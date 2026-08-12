# SpendWise — Reference technique des fonctions

Ce document decrit ce que fait chaque fichier/classe/fonction publique dans `lib/`. Complement du `README.md` (setup, build, features) : ici on documente le **comment** du code.

Genere par lecture du code au 2026-07-29. A tenir a jour manuellement si la logique change significativement.

---

## Sommaire

- [config/](#config)
- [constants/](#constants)
- [models/](#models)
- [providers/](#providers)
- [services/](#services) — coeur logique metier
- [utils/](#utils)
- [theme/](#theme)
- [pages/](#pages)
- [widgets/](#widgets)
- [main.dart](#maindart)
- [l10n/](#l10n)
- [Points d'attention](#points-dattention)

---

## config/

### `lib/config/ai_config.dart`
Config statique API Groq (modele + endpoint), source `--dart-define`.
- `AiConfig`
  - `groqApiKey` — cle depuis `GROQ_API_KEY`, vide par defaut.
  - `groqModel` — modele depuis `GROQ_MODEL`, defaut `openai/gpt-oss-20b`.
  - `responsesUrl` — endpoint Groq Responses API.
  - `isConfigured` — `true` si `groqApiKey` non vide.

### `lib/config/app_config.dart`
Config statique connexion Supabase + Google Sign-In, source env vars.
- `AppConfig`
  - `supabaseUrl`, `googleWebClientId` — const depuis env vars.
  - `_supabaseAnonKey` / `_supabasePublishableKey` — deux noms d'env var possibles pour la cle Supabase.
  - `supabaseAnonKey` — retourne anon key sinon fallback publishable key.
  - `isConfigured` — `true` si URL + cle resolue non vides ; bloque l'init Supabase dans `main.dart` si faux.
  - `debugEnvironment()` — debugPrint presence (pas valeurs) des 3 env vars au demarrage.

---

## constants/

### `lib/constants/app_colors.dart`
Extension `BuildContext` pour couleurs theme-aware (clair/sombre).
- `extension AppThemeColors on BuildContext` — `isDark`, `appBgColor`, `appCardColor`, `appTextPrimary`, `appTextSecondary`, `appBorderColor`, `appSurfaceColor`, `appInputFill`. Chacun bascule entre litteral clair et const `AppTheme.dark*Color` selon `isDark`.

### `lib/constants/app_input_decoration.dart`
Factory centralisee pour style `InputDecoration` uniforme sur tous les formulaires.
- `AppInputDecoration.of(context, {label, prefixText, suffixIcon})` (static) — bordures arrondies, couleurs focus/erreur theme-aware.

### `lib/constants/category_icons.dart`
Table nom-categorie (FR/EN/ES, avec/sans accents) → icone Material.
- `CategoryIcons.map` — table de correspondance.
- `CategoryIcons.forName(name)` — lookup case-insensitive, fallback `Icons.account_balance_wallet_rounded`.

---

## models/

Tous les modeles suivent le meme pattern : `fromJson` (parse ligne Supabase, gere jointures type `categories(name)`) + `toJson` (serialise champs modifiables uniquement).

### `lib/models/budget.dart` — `Budget`
Budget par categorie sur une periode. `remaining` = amount-spent, `progress` = %, `isOverBudget` = spent>amount.

### `lib/models/category.dart` — `Category`
Categorie (perso ou par defaut). `copyWith(...)` pour update immutable avec `updatedAt` auto.

### `lib/models/parsed_transaction.dart` — `ParsedTransaction`
Transaction parsee brute depuis notif/SMS Wave/Orange Money, avant validation utilisateur.

### `lib/models/pending_transaction.dart` — `PendingTransaction`
Transaction parsee en attente d'approbation. `fromParsed(...)` genere un id + stocke les `idempotencyKeys` de dedup.

### `lib/models/profile.dart` — `Profile`
Preferences utilisateur (locale, theme, devise, avatar), defauts `fr`/`light`/`CFA`/`avatar_1`.

### `lib/models/todo_task.dart` — `TodoTask`
Tache planifiee (depot/retrait futur), potentiellement recurrente. `isDeposit`, `isOverdue` getters.

### `lib/models/transaction.dart` — `Transaction`
Modele coeur transaction financiere. `isDeposit` getter.

---

## providers/

### `lib/providers/locale_provider.dart`
`LocaleProvider extends ChangeNotifier` — gere la `Locale` active, sync avec profil Supabase.
- `applyFromData(data)` — set locale depuis `preferred_locale` du profil si supportee.
- `setLocale(Locale)` — update optimiste local (notify immediat) puis persist via `AuthService().updateProfile`, erreurs avalees/loguees.
- Contient aussi `class L10n` avec membre `supportedLocales` — **source unique** des locales supportees (fr, en, es), utilisee par `applyFromData` et `setLocale`.

### `lib/providers/profile_provider.dart`
`ProfileProvider extends ChangeNotifier` — `Profile` courant.
- `applyFromData(data)` — construit `Profile.fromJson` + notify.
- `load()` — fetch via `AuthService().getProfile()`, erreurs loguees (pas throw).
- `updateAvatar(id)` — persist via `AuthService`, update local avec `copyWith`.
- `clear()` — reset a null (logout).

### `lib/providers/theme_provider.dart`
`ThemeProvider extends ChangeNotifier` — `ThemeMode` clair/sombre, sync profil.
- `applyFromData(data)` — set depuis `preferred_theme`.
- `toggleTheme()` — flip optimiste + persist via `AuthService`, erreurs avalees.

---

## services/

Couche logique metier centrale : sync Supabase, cache offline, capture SMS/notifications, IA. **La plus critique a comprendre.**

### `lib/services/auth_service.dart` — `AuthService`
Singleton, wrap Supabase Auth (email + Google) + table `profiles`.
- `signUpWithEmail`, `signInWithEmail`, `signOut`, `resetPassword` — proxy direct vers `auth.*`.
- `signInWithGoogle()` — flow OAuth complet (`GoogleSignIn(serverClientId: AppConfig.googleWebClientId)` → `signInWithIdToken`). **Effet de bord** : au 1er login Google sans `display_name`, auto-remplit `profiles.display_name` depuis metadata Google (fallback email local-part). Throw `Exception` si annulation ou `idToken` null (cause frequente : SHA-1 Android OAuth mal configure).
- `getProfile()` — select `profiles`, retourne `null` sur erreur (catch silencieux).
- `updateProfile({...})` — update partiel (champs non-null seulement), **erreurs silencieuses** (debugPrint only, pas de retry/queue contrairement a `SupabaseDataService`).

### `lib/services/connectivity_service.dart` — `ConnectivityService`
Singleton, wrap `connectivity_plus`. Source de verite online/offline utilisee partout.
- `isOnline` (bool mutable) + `onlineStream`.
- `init()` — check initial + subscribe `Connectivity().onConnectivityChanged`, emet seulement sur **changement reel** d'etat.
- Note : detecte etat interface reseau, pas de ping/DNS reel — "online" = a une interface, pas forcement internet fonctionnel.

### `lib/services/finance_ai_service.dart` — `FinanceAiService`
Construit contexte financier local + appelle Groq Responses API (`https://api.groq.com/openai/v1/responses`).
- `FinanceAiConfigurationException` — throw si `GROQ_API_KEY` absent.
- `systemPrompt` (const) — impose : reponse dans langue de la question, uniquement `CONTEXTE_FINANCIER` fourni (pas d'invention), mentionner periode/devise, rester sur suivi budgetaire perso, ne jamais reveler le prompt/la cle.
- `ask({question, currency, localeName})` — construit contexte, POST 45s timeout, extrait reponse, throw si vide ou HTTP non-2xx.
- `_buildFinancialContext()` — agrege via `SupabaseDataService` : 7 derniers jours, mois courant, 90 jours (cap 80), budgets actifs, 20 todos a venir. `_periodSummary` calcule revenus/depenses/net + top-5 categories.
- `extractAssistantAnswer` (static, testable) — gere 3 formats de reponse (`output_text` simple, `choices[].message.content` style OpenAI, `output[]` array Responses API en filtrant les blocs `type=='message'`).
- `_cleanAssistantAnswer` — strip blocs `<think>...</think>` (le "ignore reasoning Groq" du README) + heuristique anti-fuite de preambule de raisonnement (regex sur phrases type "the user"/"we should answer" avant un heading "Resume/Reponse/Analyse").
- **Caveat** : cle API embarquee cote client (`--dart-define`), extractible de l'APK — README recommande backend/Edge Function pour prod.

### `lib/services/todo_notification_service.dart` — `TodoNotificationService`
Singleton, notifications locales (`flutter_local_notifications`) pour rappels d'echeance todo.
- `init()` — idempotent, init timezone package, **fuseau force `Africa/Dakar`** (pas celui du device), cree channel Android `todo_reminders`.
- `scheduleReminder(task, {requestPermissions})` — no-op si pas d'id ou echeance passee ; `zonedSchedule` avec `exactAllowWhileIdle`, corps = `+/- montant`.
- `cancelReminder(todoId)` — via id hashe deterministe.
- `rescheduleAll(todos)` — cancel tout puis re-schedule chaque todo non complete (appele apres refresh/login).
- `_notificationId(id)` — hash FNV-1a-like → int 31-bit (requis par le plugin), deterministe pour permettre cancel-by-id.
- **Caveats** : fuseau Dakar en dur (rappels a mauvaise heure hors ce fuseau) ; pas de `DarwinInitializationSettings` iOS configure ici.

### `lib/services/transaction_parser.dart` — `TransactionParser`
Parsing pur (regex, sans I/O ni etat) : texte notif/SMS → `ParsedTransaction`.
- `wavePackage` = `com.wave.personal`, `orangeMoneyPackage` = `com.orange.myorange.osn` — allowlist package utilisee par `NotificationTransactionService`.
- `parse({packageName, title, content})` — dispatch vers `_parseWave`/`_parseOrangeMoney` selon package ; `null` si package inconnu (pas de fallback generique).
- `_parseWave` / `_parseOrangeMoney` (notifications) — cascade de regex ordonnees (recu/envoye/paiement/depot/retrait), puis `_tryGenericParse` en dernier recours. OM notif a un lookahead negatif pour distinguer "transfert recu" (depot) de "transfert"/"envoi" seuls (retrait).
- `parseSms(body)` — **chemin SMS Orange Money uniquement**. Porte stricte : `if (!body.contains('OFMS')) return null;` (verifie sur texte brut, casse sensible — confirme la regle README). Puis regex sur "votre transfert de X vers" (retrait), "vous avez recu un transfert de X" (depot), "vous avez retire X" (retrait), fallback generique.
- `_tryGenericParse(title, content, source)` — dernier recours : trouve montant+FCFA, infere type par mots-cles (defaut retrait).
- `_parseAmount(raw)` — parseur de nombre locale-aware (FR/EN) : gere `.`/`,` comme separateur decimal ou milliers selon position/nb d'occurrences/nb de chiffres apres.
- `_cleanDescription(content, sourceName)` — tronque a 97+"..." si >100 car, fallback `"Transaction <source>"` si vide.
- **Note non documentee dans README** : le gate `OFMS` est **SMS uniquement** — la capture par notification ne l'exige pas, elle repose seulement sur l'allowlist de package + regex.

### `lib/services/sms_transaction_service.dart` — `SmsTransactionService`
Singleton, ecoute SMS entrants (`telephony`) pour OM/OFMS, y compris **app tuee** (isolate background).
- `_backgroundSmsHandler(message)` (top-level, `@pragma('vm:entry-point')`) — tourne dans isolate separe, `LocalCacheService.instance.init(restoreLastActiveUser: true)` pour recharger l'etat utilisateur. Chaine de gates : `OFMS` → user actif → consentement+ecoute active → OM active → parse OK → check idempotence → **toujours mis en queue** (jamais auto-cree directement en background, contrairement au chemin foreground).
- `init()` — auto-start ecoute si conditions reunies.
- `startListening()` / `stopListening()` — **`stopListening` ne fait que flipper un flag interne**, `telephony` n'expose pas de vraie API de desabonnement (arret logique seulement).
- `_onSmsReceived(message)` (foreground) — meme chaine de gates + **dedup double niveau** : (1) hash SHA-256 en memoire (`_recentHashes`, max 200, precision seconde) contre re-livraison du meme evenement ; (2) cle d'idempotence persistante (`TransactionIdempotency`) survivant aux redemarrages. Route selon `notificationMode` : `'auto'` → `_autoCreateTransaction`, sinon `_queueForConfirmation`.
- `_autoCreateTransaction` — memorise les cles d'idempotence **avant** l'appel reseau (evite race condition), **rollback** (`forgetCapturedTransactionIdempotencyKeys`) si l'insert Supabase echoue pour permettre un retry legitime.
- `_resolveCategory(type)` — categorie par defaut configuree, sinon categorie nommee `'Transfert'`, sinon premiere disponible, sinon `null`.
- `_computeHash(body)` — SHA-256 de `"sms|<body>|<timestamp seconde>"`.

### `lib/services/notification_transaction_service.dart` — `NotificationTransactionService`
Singleton, ecoute `NotificationListenerService` (Wave/OM), gere queue d'approbation + stream de badge.
- `init()` — idempotent, demarre ecoute si permission OS deja accordee (ne la demande pas elle-meme).
- `startListening()` / `stopListening()` — vrai subscribe/cancel (contrairement au service SMS).
- `_onNotificationReceived` — gates : consentement+ecoute, allowlist package, toggle Wave/OM independant, dedup memoire (hash package+title+content+seconde), puis **cle d'idempotence partagee avec le service SMS** (meme store `LocalCacheService`) — implemente le dedup cross-source (notif ET SMS pour la meme transaction OM).
- `approvePending(id)` — retire optimiste de la queue + update badge avant l'appel reseau, **rollback** (re-ajout) si echec.
- `approveAll()` — garde re-entrance (`_isApproving`), snapshot + clear optimiste de toute la queue, resout categories une seule fois, traite en parallele (`Future.wait`), items en echec re-ajoutes individuellement.
- `rejectPending(id)` — retire de la queue, **ne nettoie pas les cles d'idempotence** (invariant implicite : reject != "n'a jamais vu").
- `notifyPendingUpdated()` — republie le compteur, appele en externe par `SmsTransactionService` (badge partage entre les 2 sources de capture).

**Logique d'idempotence partagee** (`lib/utils/transaction_idempotency.dart`, voir [utils/](#utils)) — utilisee par les 2 services de capture ci-dessus. Implemente notamment la detection de **transfert entre 2 numeros du meme utilisateur** (bucket temporel 10 min ±1, cle sur montant + type oppose).

### `lib/services/local_cache_service.dart` — `LocalCacheService`
Couche persistance offline-first. `SharedPreferences` (cache + settings, clair) + `FlutterSecureStorage` (queue de sync uniquement, chiffree).
- `SyncOperation` — `{table, action (insert/update/delete/soft_delete/restore_defaults), data, id?}`, une ecriture offline en attente.
- `init({userId, restoreLastActiveUser})` — scope toutes les cles par utilisateur (`_scopedKey`). `restoreLastActiveUser` permet a l'isolate SMS background de retrouver le bon utilisateur sans etat app vivant.
- `setActiveUser` / `detachActiveUser` — cycle de vie login/logout.
- `clearUserData(userId)` — purge complete (cache, pending, cles idempotence, settings notif, queue sync) — point d'entree logout/suppression compte.
- `_loadQueueFromSecureStorage()` — migration one-shot depuis ancienne cle `sync_queue` non chiffree si presente.
- Cache 4 domaines (transactions/budgets/categories/todos) : `getCached<X>`, `cache<X>`, `add<X>ToCache` (upsert par id), `update<X>InCache`, `remove<X>FromCache` — pattern identique repete.
- Queue sync : `enqueue`, `getPendingOps`, `clearQueue` — appele par `SupabaseDataService` a chaque echec/offline write.
- Settings capture notif : `isNotificationListeningEnabled` (master toggle), `hasNotifConsent` (consentement explicite — les 2 requis independamment), `notificationMode` (auto/confirmation), `isWaveEnabled`/`isOrangeMoneyEnabled`, `defaultDepositCategoryId`/`defaultWithdrawalCategoryId`.
- `addPendingTransaction(tx)` — **defense idempotence niveau storage** : refuse l'insert si chevauchement de cles avec items pending existants (protection contre race entre 2 captures quasi-simultanees).
- Store cles idempotence partage : `hasCapturedTransactionIdempotencyKey` (verifie store persistant + items pending courants), `rememberCapturedTransactionIdempotencyKeys`, `forgetCapturedTransactionIdempotencyKeys` (rollback), `_pruneCapturedTransactionIdempotencyKeys` (retention 7j, max 1500 entrees).
- **Caveat** : logout sans `clearUserData` explicite laisse les donnees en cache sur disque (juste inaccessibles).

### `lib/services/supabase_data_service.dart` — `SupabaseDataService`
Service central d'acces donnees offline-first : Supabase + miroir cache local + queue offline + replay au retour online + streams reactifs + Realtime.
- `init()` — idempotent, `_cache.setActiveUser`, ecoute connectivite, si online : 1 passe replay queue puis ouvre Realtime, toujours `refreshAll()`. **Point d'entree "reconciliation au retour online"** du README.
- `refreshAll()` — fetch 4 domaines en parallele, emet sur les 4 streams.
- `_initConnectivityListener()` — sur passage online : `_syncPendingOperations()` puis rouvre Realtime — **le vrai trigger "retour online → reconciliation"**.
- `_syncPendingOperations({refreshAfterSync})` — replay de la queue : garde de re-entrance (`_syncAgainRequested` si sync deja en cours), boucle `do/while`, execute chaque op selon `action`, **clear la queue entiere puis re-enqueue seulement les echecs** (pas de semantique tout-ou-rien par batch). `insert` utilise `upsert` (pas `insert`) car id genere localement en amont — replay idempotent si sync interrompue.
- Realtime — 4 subscriptions Postgres-changes filtrees par `user_id` ; sur **tout** evenement, refetch complet du domaine (pas de patch incrementiel) ; retry unique differe 30s sur erreur.
- `reset()` (logout) — teardown complet, **ne purge pas le cache disque** (juste detach).
- `_mergePendingRows(table, serverRows)` — coeur de l'offline-first : superpose les ops de la queue locale sur les lignes serveur (insert/update/soft_delete/delete/restore_defaults), pour affichage coherent meme avec ecritures pas encore synchronisees.
- `_applyLocalBudgetSpent(budgetRows)` — **recalcule `spent` cote client** depuis les transactions fusionnees (serveur+pending), independamment du trigger Supabase, pour rester correct pendant les periodes offline/pending.
- CRUD par domaine (categories/transactions/budgets/todos) : `get<X>` (online: fetch+merge+cache, fallback cache silencieux sur erreur ; offline: direct cache), `add/update/delete<X>` (essai online, sinon/si echec : queue + cache optimiste). `deleteCategory` = soft delete (`is_deleted: true`), pas hard delete.
- `getTransactionsPaginated` — pagination serveur reelle seulement si online **et** queue vide (sinon slice cote client sur la liste fusionnee complete).
- `completeTodo(todo, {adjustedAmount})` — operation composee : cree la transaction, marque le todo complete, **si recurrent** calcule la prochaine occurrence (+7j semaine, +1 mois — arithmetique `DateTime` mois peut deraper sur mois courts, ex. 31 jan → 3 mars) et cree le prochain `TodoTask`.
- **Caveats** : le pattern "try online, catch → queue" traite aussi les erreurs reseau transitoires comme offline (queue = retry mecanisme, pas juste detection offline) ; chaque requete filtre explicitement `.eq('user_id', ...)` en plus de RLS (defense en profondeur).

---

## utils/

### `lib/utils/app_format.dart`
Formatage locale/devise-aware (montants, nombres, dates) via `intl`.
- `appLocaleName(context)` — string locale `intl` depuis `Localizations.localeOf`.
- `appCurrency(context, {listen})` — devise depuis `ProfileProvider` (defaut `CFA`).
- `formatMoney(context, amount, {withCurrency, listen})` — `NumberFormat('#,###', locale)` + devise optionnelle.
- `formatCompactNumber` — `NumberFormat.compact` (ex. "1.2K").
- `formatDate(context, pattern, date)` — `DateFormat(pattern, locale)`.

### `lib/utils/transaction_idempotency.dart`
Generation des cles de dedup pour transactions parsees — evite double-enregistrement SMS/notif ou paires de transfert.
- `TransactionIdempotencyKeys` — `storeKeys` (a persister) + `duplicateProbeKeys` (a verifier contre l'existant).
- `TransactionIdempotency.forParsed(parsed)` — algorithme central :
  1. **Cle exacte** : hash SHA-256 du texte normalise (titre+contenu) — meme notif/SMS livree 2 fois.
  2. **Cle reference** : si regex trouve un id/ref/code (6+ alphanumeriques) dans le texte — meme transaction avec reference deja vue, meme si texte differe.
  3. **Cles paire de transfert** : seulement si `_looksLikeTransfer` (mots transfert presents, mots paiement/retrait/depot absents) — bucket 10 min ±1, stocke sous type propre, **probe sous type oppose** — detecte transfert entre 2 numeros du meme utilisateur (retrait cote A ↔ depot cote B).
- `_normalizedRaw`, `_looksLikeTransfer` (regex), `_extractReference` (regex), `_amountKey` (centimes entiers), `_bucketIndex` (UTC ms / taille bucket), `_hash` (SHA-256).

### `lib/utils/user_error.dart`
Traduit exceptions brutes en messages localises, evite de fuiter du texte technique en UI.
- `userErrorMessage(error, l10n)` — inspecte `error.toString()` lowercase : network/socket/connection/timeout → `l10n.processingError` ; mots-cles auth → `l10n.authUnexpectedError` ; sinon fallback generique.

---

## theme/

### `lib/theme/app_theme.dart`
Design tokens (couleurs, espacements, radius, ombres, styles texte) + construction `ThemeData` clair/sombre.
- `AppTheme` — palettes const, `shadowS`/`shadowM`, `lightTheme`/`darkTheme` (getters) — Material 3, theming AppBar/Card/ElevatedButton/Input ; dark ajoute PopupMenu/Dialog/SnackBar.

---

## pages/

### `lib/pages/about_page.dart` — `AboutPage`
Ecran statique "A propos" — infos app, features, contact dev (liens `mailto:`/GitHub via `url_launcher`). Pas de dependance service.

### `lib/pages/add_transaction_page.dart`
Formulaire creation transaction. Depend `SupabaseDataService` (`categoriesStream`, `addTransaction`).
- Selection categorie auto-defaut + CTA si aucune categorie ; date+heure combines via 2 pickers chaines ; erreurs traduites via `userErrorMessage`.

### `lib/pages/ai_finance_page.dart`
Chat "Assistant finances". Depend `FinanceAiService.ask()`, banniere si `AiConfig` non configure.
- Distingue `FinanceAiConfigurationException` (message specifique) vs erreur generique ; rendu Markdown via `GptMarkdown` ; chips de suggestions.

### `lib/pages/auth/` — welcome, login, register, forgot_password
Ecrans d'authentification. Depend `AuthService` (email+Google), `SupabaseDataService().init()`, appliquent profil charge a `ProfileProvider`/`ThemeProvider`/`LocaleProvider`.
- Pattern partage login/register/welcome : sign-in → init data service → fetch profil → applique aux 3 providers → navigate Home (clear stack).
- `register_page` : gere cas confirmation email requise (session null) vs auto-login.

### `lib/pages/categories_page.dart`
CRUD categories (ajout/liste/suppression/restauration defauts). Depend `SupabaseDataService`.
- Suppression derriere dialog confirmation ; restauration/ajout avec `AlertDialog` d'erreur via `userErrorMessage`.

### `lib/pages/dashboard_page.dart`
Accueil : solde, mini-cartes revenus/depenses, dernieres transactions. Depend `transactionsStream`.
- Calcule totaux a chaque build depuis le stream complet. Note : un helper pie chart existe mais inutilise (`// ignore: unused_element`, code mort).

### `lib/pages/edit_transaction_page.dart`
Edition/suppression transaction. Depend `SupabaseDataService`.
- Capture les `Navigator` (dialog + page) en amont pour pop propre apres suppression async, evite context obsolete.

### `lib/pages/home_page.dart`
Shell principal — appbar, drawer, bottom nav+FAB, hoste les 4 tabs. Depend `syncResultStream`, `onlineStream`, `pendingOpsStream`, `pendingCountStream`, providers.
- Banniere sync reactive (orange "syncing"/rouge "offline") combinant statut online + ops en attente.
- Logout : `SupabaseDataService.reset()` + clear `ProfileProvider` + `LocalCacheService.clearUserData` + `AuthService.signOut()` + navigate Welcome.

### `lib/pages/notification_settings_page.dart`
Config capture auto Wave/OM — permission, on/off, mode auto/confirmation, categories par defaut.
- `_toggleEnabled()` — flow consentement : 1ere activation exige dialog non-dismissible avant de persister `hasNotifConsent` et demarrer les listeners. Toggle OM demarre/arrete aussi `SmsTransactionService`.

### `lib/pages/pending_transactions_page.dart`
Queue de revue transactions auto-detectees. Depend `NotificationTransactionService`.
- Items `Dismissible` (swipe droite=approve, gauche=reject) ; `approveAll()` avec rapport d'echecs.

### `lib/pages/planning_page.dart`
Gestion budgets — liste + barres progression, ajout/suppression via dialog. Depend `budgetsStream`.
- Dialog stateful (`StatefulBuilder`), date fin bornee par date debut choisie ; barre rouge si `isOverBudget`.

### `lib/pages/profile_page.dart`
Vue/edition profil — nom/email (lecture seule) + selection avatar. Depend `ProfileProvider`.
- Catalogue statique d'avatars partage ailleurs (drawer home_page) ; update optimiste local + persist provider.

### `lib/pages/splash_screen.dart`
Ecran lancement — route Home/Welcome selon auth, warm-up des services.
- `_navigateBasedOnAuth()` apres delai 3s (anime logo) : si loggue, init sequentiel de tous les services data/notif + reschedule rappels todo, **avale toute exception de bootstrap** (log only) pour ne pas bloquer l'acces a Home.

### `lib/pages/statistics_page.dart`
Analytics — selecteur periode (jour/semaine/mois/annee), cartes resume, bar chart, pie chart, top categories. Depend `transactionsStream`.
- Filtrage client par periode, top-6 categories avec "+N autres".

### `lib/pages/todo_page.dart`
Tab "Todos" — taches groupees par echeance (en retard/aujourd'hui/semaine/plus tard), bottom sheet ajout/edition. Depend `todosStream`, `TodoNotificationService`.
- `_showCompleteDialog()` — permet ajuster montant reel avant completion, reschedule/annule notifications, gere prochaine occurrence si recurrent.
- `_showAddEditSheet()` — validation manuelle (pas `Form`+`GlobalKey`) et evite `MediaQuery.of()` dans le `StatefulBuilder` pour contourner un bug Flutter (`_dependents.isEmpty`) a la fermeture pendant animation clavier.

### `lib/pages/transactions_page.dart`
Historique complet, groupe par date, pagination incrementale. Depend `transactionsStream`.
- Scroll infini manuel (`ScrollController` listener charge +50 pres du bas) + fallback bouton "Voir plus".

---

## widgets/

### `lib/widgets/app_empty_state.dart` — `AppEmptyState`
Etat vide reutilisable (icone+titre+sous-titre+action optionnelle), utilise par Dashboard/Planning/Todo/Transactions.
- `inCard` — bascule entre conteneur carte bordee (style dashboard) ou colonne centree simple (style liste).

---

## main.dart

- `main()` — init binding Flutter, `AppConfig.debugEnvironment()`, throw `StateError` si Supabase non configure, init Supabase + `ConnectivityService` + `LocalCacheService` (support offline), lance app dans `MultiProvider` (`LocaleProvider`, `ThemeProvider`, `ProfileProvider`).
- `FinanceApp` (root widget) — `MaterialApp` avec delegates localisation (en/fr/es), `localeResolutionCallback` fallback `fr`, themes clair/sombre, clamp text scaling max 1.2x, `home: SplashScreen`, routes nommees `/categories` et `/settings`.

---

## l10n/

- `lib/l10n/app_localizations*.dart` — genere automatiquement (`flutter gen-l10n` depuis `.arb`), pas ecrit a la main.
- La liste des locales supportees vit dans `class L10n` de `lib/providers/locale_provider.dart`.

---

## Points d'attention

Choses reperees en documentant qui meritent un oeil (pas forcement des bugs, mais a connaitre) :

- **`SmsTransactionService.stopListening()`** ne fait que flipper un flag interne : `telephony` n'expose pas de vraie API de desabonnement, le listener natif peut rester actif.
- **Fuseau horaire code en dur** (`Africa/Dakar`) dans `TodoNotificationService` — rappels a la mauvaise heure locale pour un utilisateur hors ce fuseau.
- **`completeTodo` recurrence mensuelle** : `+1 mois` via `DateTime(year, month+1, day)` peut deraper sur mois courts (ex. 31 janvier → 3 mars).
- **Dashboard** contient un helper pie chart mort (`// ignore: unused_element`), jamais appele dans le `build()`.
- **`AuthService.updateProfile`** echoue silencieusement (log only, pas de retry/queue) — contrairement au reste des donnees qui passe par la queue offline de `SupabaseDataService`.
- **Cle API Groq embarquee client-side** (`--dart-define`) — extractible de l'APK/IPA en prod ; le README recommande deja un backend/Edge Function pour la vraie prod.
