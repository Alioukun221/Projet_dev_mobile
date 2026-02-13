# SpendWise - Plan de Migration vers Supabase

## Contexte Actuel

| Aspect | Actuel | Cible |
|--------|--------|-------|
| Base de donnees | Hive (NoSQL local) | Supabase (PostgreSQL cloud) |
| Authentification | Aucune | Supabase Auth (email/Google) |
| Sync | Aucune (offline only) | Cloud-first + cache local |
| Multi-device | Non | Oui |
| State management | Provider + Hive Listenable | Provider + Supabase Realtime |

---

## Phase 0 : Preparation du projet Supabase

### 0.1 - Creer le projet Supabase
- Creer un compte sur [supabase.com](https://supabase.com)
- Creer un nouveau projet (region EU-West recommandee)
- Recuperer les credentials :
  - `SUPABASE_URL`
  - `SUPABASE_ANON_KEY`

### 0.2 - Installer les dependances Flutter
```yaml
# pubspec.yaml - Ajouter
dependencies:
  supabase_flutter: ^2.8.4    # SDK Supabase pour Flutter
  connectivity_plus: ^6.1.4   # Detection de connexion reseau

# pubspec.yaml - Supprimer (a la fin de la migration)
# hive: ^2.2.3
# hive_flutter: ^1.1.0

# dev_dependencies - Supprimer (a la fin)
# hive_generator: ^2.0.1
```

### 0.3 - Configuration de l'environnement
Creer `lib/config/supabase_config.dart` :
```dart
class SupabaseConfig {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
}
```

> Les cles seront passees au build via `--dart-define` pour eviter de les hardcoder.

---

## Phase 1 : Schema de la base de donnees Supabase

### 1.1 - Table `profiles` (utilisateurs)
```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT,
  display_name TEXT,
  preferred_locale TEXT DEFAULT 'fr',
  preferred_theme TEXT DEFAULT 'light',
  currency TEXT DEFAULT 'CFA',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 1.2 - Table `categories`
```sql
CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  icon TEXT NOT NULL,               -- Code icon (ex: '0xe148')
  is_default BOOLEAN DEFAULT FALSE,
  is_deleted BOOLEAN DEFAULT FALSE, -- Soft delete
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, name)
);
```

### 1.3 - Table `transactions`
```sql
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  type TEXT NOT NULL CHECK (type IN ('deposit', 'withdrawal')),
  amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
  description TEXT,
  date TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 1.4 - Table `budgets`
```sql
CREATE TABLE budgets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
  spent NUMERIC(12,2) DEFAULT 0,
  start_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CHECK (end_date > start_date)
);
```

### 1.5 - Row Level Security (RLS)
```sql
-- Activer RLS sur toutes les tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;

-- Politique : chaque user voit uniquement ses donnees
CREATE POLICY "Users see own data" ON profiles
  FOR ALL USING (auth.uid() = id);

CREATE POLICY "Users see own categories" ON categories
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users see own transactions" ON transactions
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users see own budgets" ON budgets
  FOR ALL USING (auth.uid() = user_id);
```

### 1.6 - Fonction auto-create profile + categories par defaut
```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  new_profile_id UUID;
BEGIN
  -- Creer le profil
  INSERT INTO public.profiles (id, email, display_name)
  VALUES (NEW.id, NEW.email, COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1)));

  -- Inserer les categories par defaut
  INSERT INTO public.categories (user_id, name, icon, is_default) VALUES
    (NEW.id, 'Alimentation', '0xe148', TRUE),
    (NEW.id, 'Transport',    '0xe1d5', TRUE),
    (NEW.id, 'Logement',     '0xe318', TRUE),
    (NEW.id, 'Loisirs',      '0xe87c', TRUE),
    (NEW.id, 'Sante',        '0xe548', TRUE),
    (NEW.id, 'Education',    '0xe80c', TRUE),
    (NEW.id, 'Autres',       '0xe8b8', TRUE);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

---

## Phase 2 : Authentification

### 2.1 - Creer `lib/services/auth_service.dart`
Responsabilites :
- `signUpWithEmail(email, password)` - Inscription
- `signInWithEmail(email, password)` - Connexion
- `signInWithGoogle()` - Connexion Google (optionnel)
- `signOut()` - Deconnexion
- `resetPassword(email)` - Mot de passe oublie
- `getCurrentUser()` - Utilisateur courant
- `onAuthStateChange` - Stream d'etat d'authentification

### 2.2 - Creer les pages d'authentification
| Fichier | Fonction |
|---------|----------|
| `lib/pages/auth/login_page.dart` | Formulaire de connexion |
| `lib/pages/auth/register_page.dart` | Formulaire d'inscription |
| `lib/pages/auth/forgot_password_page.dart` | Reinitialisation MDP |

### 2.3 - Modifier le flux de navigation
```
SplashScreen
  ├── User connecte  → HomePage
  └── User non connecte → LoginPage
```

Modifier `splash_screen.dart` pour verifier `Supabase.instance.client.auth.currentSession`.

---

## Phase 3 : Nouveau Service de donnees (Supabase)

### 3.1 - Creer `lib/services/supabase_data_service.dart`

Ce service remplace `DataService` avec la meme interface publique :

```
SupabaseDataService (Singleton)
│
├── Transactions
│   ├── getTransactions() → Future<List<Transaction>>
│   ├── addTransaction(Transaction) → Future<void>
│   ├── updateTransaction(Transaction) → Future<void>
│   └── deleteTransaction(String id) → Future<void>
│
├── Budgets
│   ├── getBudgets() → Future<List<Budget>>
│   ├── addBudget(Budget) → Future<void>
│   ├── updateBudget(Budget) → Future<void>
│   └── deleteBudget(String id) → Future<void>
│
├── Categories
│   ├── getCategories() → Future<List<Category>>
│   ├── addCategory(Category) → Future<void>
│   ├── updateCategory(Category) → Future<void>
│   ├── deleteCategory(String id) → Future<void>  // soft delete
│   └── restoreDefaultCategories() → Future<void>
│
├── Profile
│   ├── getProfile() → Future<Profile>
│   └── updateProfile(Profile) → Future<void>
│
└── Realtime
    ├── transactionsStream() → Stream<List<Transaction>>
    ├── budgetsStream() → Stream<List<Budget>>
    └── categoriesStream() → Stream<List<Category>>
```

### 3.2 - Mettre a jour les modeles

Les modeles doivent passer de Hive a des classes simples avec serialisation JSON :

**Avant (Hive) :**
```dart
@HiveType(typeId: 0)
class Transaction extends HiveObject {
  @HiveField(0) String type;
  ...
}
```

**Apres (Supabase) :**
```dart
class Transaction {
  final String id;          // UUID
  final String userId;
  final String categoryId;
  final String type;        // 'deposit' ou 'withdrawal'
  final double amount;
  final String description;
  final DateTime date;

  Transaction({...});

  factory Transaction.fromJson(Map<String, dynamic> json) => ...;
  Map<String, dynamic> toJson() => ...;
}
```

Meme transformation pour `Category`, `Budget`, + nouveau modele `Profile`.

### 3.3 - Adapter les pages

| Page | Changements |
|------|-------------|
| `dashboard_page.dart` | Remplacer `ValueListenableBuilder` par `StreamBuilder` sur les streams Supabase Realtime |
| `transactions_page.dart` | Idem + pagination possible |
| `add_transaction_page.dart` | Appeler `SupabaseDataService` au lieu de `DataService` |
| `edit_transaction_page.dart` | Idem + passer l'`id` UUID |
| `categories_page.dart` | Idem |
| `planning_page.dart` | Idem |
| `statistics_page.dart` | Idem |
| `home_page.dart` | Ajouter bouton deconnexion + info profil |

---

## Phase 4 : Migration des donnees existantes

### 4.1 - Script de migration locale
Pour les utilisateurs existants, migrer les donnees Hive vers Supabase au premier login :

```dart
class DataMigrationService {
  /// Verifie si des donnees Hive existent
  Future<bool> hasLocalData();

  /// Migre les donnees Hive vers Supabase
  Future<void> migrateToSupabase(String userId);

  /// Supprime les donnees Hive apres migration reussie
  Future<void> clearLocalData();
}
```

Flux de migration :
1. User se connecte pour la premiere fois
2. Detection de donnees Hive locales
3. Proposition de migration a l'utilisateur (dialog)
4. Upload des transactions, budgets, categories vers Supabase
5. Confirmation + suppression des donnees Hive locales

---

## Phase 5 : Preferences utilisateur dans le cloud

### 5.1 - Sauvegarder les preferences dans `profiles`
- Langue preferee (`preferred_locale`)
- Theme prefere (`preferred_theme`)
- Devise (`currency`)

### 5.2 - Modifier `LocaleProvider`
Charger la langue depuis le profil Supabase au lieu d'une valeur hardcodee.

### 5.3 - Modifier la gestion du theme
Sauvegarder le choix light/dark dans le profil Supabase.

---

## Phase 6 : Nettoyage et finalisation

### 6.1 - Supprimer Hive
- Retirer `hive`, `hive_flutter` du `pubspec.yaml`
- Retirer `hive_generator`, `build_runner` des dev_dependencies
- Supprimer les fichiers `*.g.dart` generes
- Supprimer les annotations `@HiveType`, `@HiveField`
- Supprimer `ColorAdapter`
- Retirer toute reference a Hive dans `main.dart`

### 6.2 - Modifier `main.dart`
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(const SpendWiseApp());
}
```

### 6.3 - Tests
- [ ] Inscription / Connexion / Deconnexion
- [ ] CRUD Transactions (create, read, update, delete)
- [ ] CRUD Budgets
- [ ] CRUD Categories (+ soft delete + restore defaults)
- [ ] Migration des donnees Hive existantes
- [ ] Sync multi-device (meme compte, 2 appareils)
- [ ] Preferences sauvegardees (langue, theme)
- [ ] Statistiques et dashboard avec donnees Supabase
- [ ] Comportement sans connexion internet (erreurs gracieuses)
- [ ] RLS : un user ne voit pas les donnees d'un autre

---

## Ordre d'execution recommande

```
Phase 0  ██░░░░░░░░  Setup & dependances
Phase 1  ████░░░░░░  Schema SQL + RLS
Phase 2  ██████░░░░  Auth (service + pages + navigation)
Phase 3  ████████░░  Nouveau DataService + adaptation pages
Phase 4  █████████░  Migration Hive → Supabase
Phase 5  █████████▌  Preferences cloud
Phase 6  ██████████  Nettoyage + tests
```

---

## Structure des fichiers apres migration

```
lib/
├── config/
│   └── supabase_config.dart          # NOUVEAU
├── models/
│   ├── transaction.dart              # MODIFIE (sans Hive, avec fromJson/toJson)
│   ├── category.dart                 # MODIFIE
│   ├── budget.dart                   # MODIFIE
│   └── profile.dart                  # NOUVEAU
├── services/
│   ├── auth_service.dart             # NOUVEAU
│   ├── supabase_data_service.dart    # NOUVEAU (remplace data_service.dart)
│   ├── data_migration_service.dart   # NOUVEAU (temporaire)
│   └── permission_service.dart       # INCHANGE
├── pages/
│   ├── auth/
│   │   ├── login_page.dart           # NOUVEAU
│   │   ├── register_page.dart        # NOUVEAU
│   │   └── forgot_password_page.dart # NOUVEAU
│   ├── splash_screen.dart            # MODIFIE (check auth)
│   ├── home_page.dart                # MODIFIE (deconnexion + profil)
│   ├── dashboard_page.dart           # MODIFIE (StreamBuilder)
│   ├── transactions_page.dart        # MODIFIE
│   ├── add_transaction_page.dart     # MODIFIE
│   ├── edit_transaction_page.dart    # MODIFIE
│   ├── categories_page.dart          # MODIFIE
│   ├── planning_page.dart            # MODIFIE
│   ├── statistics_page.dart          # MODIFIE
│   └── about_page.dart               # INCHANGE
├── providers/
│   └── locale_provider.dart          # MODIFIE (charge depuis profil)
├── theme/
│   └── app_theme.dart                # INCHANGE
├── widgets/
│   └── add_planning.dart             # MODIFIE
├── l10n/                             # INCHANGE
└── main.dart                         # MODIFIE (init Supabase)

Fichiers supprimes :
  - lib/services/data_service.dart
  - lib/models/*.g.dart
```

---

## Points d'attention

1. **Type de transaction** : Actuellement `'depot'` / `'retrait'` (en francais). Migrer vers `'deposit'` / `'withdrawal'` (anglais) pour la BDD, avec mapping dans le modele pour l'affichage localise.

2. **Category par nom vs par ID** : Actuellement les transactions referencent une categorie par son *nom*. Avec Supabase, utiliser un `category_id` (UUID) avec une relation FK. Le mapping se fera lors de la migration.

3. **Realtime vs polling** : Supabase Realtime est recommande pour le dashboard et les listes. Les statistiques peuvent utiliser des requetes classiques (pas besoin de temps reel).

4. **Gestion d'erreurs** : Ajouter un wrapper pour gerer les erreurs reseau (try/catch + messages utilisateur). L'app actuelle n'a pas besoin de gerer les erreurs reseau.

5. **Budget `spent`** : Actuellement calcule manuellement. Envisager une vue SQL ou un trigger pour calculer automatiquement le `spent` a partir des transactions.
