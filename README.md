# SpendWise

SpendWise est une application Flutter de gestion de finances personnelles. Elle permet de suivre les revenus et depenses, organiser les transactions par categories, suivre des budgets, planifier des operations futures et capturer automatiquement certaines transactions Wave / Orange Money depuis les notifications et SMS Android.

## Fonctionnalites

- Authentification Supabase avec profil utilisateur.
- Tableau de bord avec solde, revenus, depenses et dernieres transactions.
- Transactions manuelles avec categorie, montant, date et heure.
- Categories personnalisables.
- Budgets par categorie avec recalcul du `spent` cote local et Supabase.
- Statistiques avec graphiques `fl_chart`.
- Todo / planification de transactions avec rappels locaux.
- Mode offline-first : cache local, queue de synchronisation, reconciliation au retour online.
- Capture Wave / Orange Money par notifications et SMS avec consentement explicite.
- Transactions capturees en mode automatique ou en validation manuelle.
- Idempotence locale pour eviter les doublons SMS/notifications, y compris le cas transfert entre deux numeros du meme utilisateur.
- Assistant IA pour resumer la semaine/le mois et repondre aux questions sur les donnees financieres locales.
- Localisation et devise basees sur le profil utilisateur.

## Stack

- Flutter / Dart
- Supabase Auth, Database, Realtime
- Provider
- SharedPreferences + Flutter Secure Storage
- Connectivity Plus
- Notification Listener Service
- Telephony
- Flutter Local Notifications
- fl_chart
- Groq Responses API compatible OpenAI

## Prerequis

- Flutter SDK compatible Dart `^3.6.0`
- Android Studio ou Android SDK installe
- Un projet Supabase
- `make` si vous utilisez les raccourcis du `Makefile`

Verifier l'environnement :

```powershell
flutter doctor
flutter pub get
```

## Configuration Supabase

1. Creer un projet Supabase.
2. Executer les scripts SQL dans l'ordre :

```sql
supabase/migration.sql
supabase/todo.sql
```

3. Fournir les acces Supabase au lancement, sans les commiter :

```powershell
$env:SUPABASE_URL="https://votre-projet.supabase.co"
$env:SUPABASE_ANON_KEY="votre_anon_key"
make run-dev
```

Les projets Supabase recents peuvent aussi utiliser `SUPABASE_PUBLISHABLE_KEY` a la place de `SUPABASE_ANON_KEY`.

Commande Flutter equivalente :

```powershell
flutter run --debug --flavor development --target lib/main.dart --dart-define=SUPABASE_URL=https://votre-projet.supabase.co --dart-define=SUPABASE_ANON_KEY=votre_anon_key
```

Pour un projet public ou open source, eviter de commiter des secrets et valeurs d'environnement. L'`anon key` / `publishable key` Supabase est concue pour etre publique cote client, mais les politiques RLS doivent rester strictes.

## Lancer l'application

En debug Android avec le flavor `development`, apres avoir defini `SUPABASE_URL` et `SUPABASE_ANON_KEY` ou `SUPABASE_PUBLISHABLE_KEY` :

```powershell
make run-dev
```

Sur Windows, la cible la plus fiable est celle qui charge `.env.ps1` elle-meme avant `flutter run` :

```powershell
make run-dev-local
```

Commande Flutter equivalente :

```powershell
flutter run --debug --flavor development --target lib/main.dart --dart-define=SUPABASE_URL=https://votre-projet.supabase.co --dart-define=SUPABASE_ANON_KEY=votre_anon_key
```

Avec l'assistant IA active, passer aussi la cle Groq au runtime sans la commiter :

```powershell
$env:SUPABASE_URL="https://votre-projet.supabase.co"
$env:SUPABASE_ANON_KEY="votre_anon_key"
$env:GROQ_API_KEY="votre_cle_groq"
make run-dev
```

Commande Flutter equivalente :

```powershell
flutter run --debug --flavor development --target lib/main.dart --dart-define=SUPABASE_URL=https://votre-projet.supabase.co --dart-define=SUPABASE_ANON_KEY=votre_anon_key --dart-define=GROQ_API_KEY=votre_cle_groq
```

Le modele par defaut est `openai/gpt-oss-20b`. Il peut etre surcharge avec :

```powershell
$env:GROQ_MODEL="openai/gpt-oss-20b"
```

## Builds Android

Les flavors Android disponibles sont :

- `development` : applicationId principal `sn.alioukun.spendwise`
- `staging` : applicationId suffix `.stg`
- `production` : applicationId principal `sn.alioukun.spendwise`

Build APK debug :

```powershell
make apk-dev
```

Build APK profile staging :

```powershell
make apk-stg
```

Build APK production simple :

```powershell
make apk-prod
```

Build APK production split par ABI avec obfuscation :

```powershell
make build-apk-prod
```

Sorties attendues :

```text
build/app/outputs/flutter-apk/app-armeabi-v7a-production-release.apk
build/app/outputs/flutter-apk/app-arm64-v8a-production-release.apk
build/app/outputs/flutter-apk/app-x86_64-production-release.apk
```

Note release : le projet utilise encore la signature debug dans `android/app/build.gradle`. Configurer une vraie keystore avant distribution Play Store ou production externe.

## Tests et qualite

Lancer les tests :

```powershell
flutter test
```

Via Makefile, avec coverage et ordre aleatoire :

```powershell
make test
```

Analyse statique :

```powershell
flutter analyze
```

Formatage :

```powershell
dart format lib test
```

## Capture automatique Wave / Orange Money

La capture automatique se configure depuis l'ecran `Notifications auto`.

Le fonctionnement est volontairement strict :

- consentement explicite obligatoire ;
- master toggle obligatoire ;
- toggles separes Wave et Orange Money ;
- choix entre creation automatique et validation manuelle ;
- categories par defaut configurables pour depot / retrait ;
- lecture SMS Orange Money uniquement si le message contient le marqueur OFMS ;
- idempotence locale pour bloquer les doublons.

Cas traite par l'idempotence :

- meme notification ou meme SMS recu plusieurs fois ;
- transaction avec reference explicite deja vue ;
- transfert entre deux numeros du meme utilisateur, ou un cote apparait comme retrait et l'autre comme depot du meme montant dans une fenetre courte.

Les donnees capturees sont stockees localement et transformees en transactions uniquement selon le mode choisi par l'utilisateur.

## Assistant IA

L'ecran `Assistant finances` est accessible depuis le menu lateral.

Il construit un contexte financier local a partir des transactions, budgets et transactions planifiees, puis appelle l'endpoint Groq Responses API :

```text
https://api.groq.com/openai/v1/responses
```

La cle API n'est pas stockee dans le repo. Elle est lue via :

```text
--dart-define=GROQ_API_KEY=...
```

Les acces Supabase suivent le meme principe :

```text
--dart-define=SUPABASE_URL=...
--dart-define=SUPABASE_ANON_KEY=...
```

Le system prompt est defini dans :

```text
lib/services/finance_ai_service.dart
```

Il impose a l'IA de repondre dans la langue de la question, d'utiliser uniquement le contexte financier fourni, de ne pas inventer de donnees et de rester sur du suivi budgetaire personnel.

Les reponses IA sont rendues avec `gpt_markdown` pour afficher proprement le Markdown mobile, et le service ignore les blocs de raisonnement Groq pour ne garder que la reponse finale utilisateur.

Pour une app mobile en production, une cle appelee directement depuis le client peut etre extraite de l'APK/IPA. La solution la plus robuste est de passer par un backend ou une Supabase Edge Function qui garde la cle cote serveur.

## Offline / Online Sync

SpendWise conserve les donnees critiques en local par utilisateur :

- transactions ;
- categories ;
- budgets ;
- todos ;
- transactions capturees en attente ;
- queue de synchronisation.

Quand l'app est offline, les operations sont ajoutees a une queue locale. Au retour online, `SupabaseDataService` rejoue les operations vers Supabase puis rafraichit les streams UI. Les caches sont scopes par utilisateur et nettoyes au logout.

## Structure utile

```text
lib/
  config/                 Configuration Supabase
  l10n/                   Localisations
  models/                 Modeles metier
  pages/                  Ecrans Flutter
  providers/              Etat profil, theme, locale
  services/               Supabase, cache local, sync, SMS, notifications
  utils/                  Formatage, erreurs, idempotence
  widgets/                Widgets partages
supabase/
  migration.sql           Tables principales, RLS, triggers budgets
  todo.sql                Table todo_tasks et politiques RLS
android/
  app/build.gradle        Flavors et config Android app
  build.gradle            Fallback namespace pour vieux plugins Android
```

## Notes Android

Le plugin `telephony` est ancien et ne declare pas de `namespace` Android. Le projet applique un fallback dans `android/build.gradle` pour rester compatible avec les versions recentes d'AGP.

`kotlin.incremental=false` est defini dans `android/gradle.properties` pour eviter des erreurs de cache Kotlin sous Windows quand le projet est sur `D:\...` et le cache Pub sur `C:\...`.

Flutter peut afficher des avertissements indiquant que Gradle `8.11.1` et AGP `8.9.1` seront bientot moins supportes. Ces warnings ne bloquent pas le build actuel, mais il faudra planifier une mise a jour Gradle / AGP.
