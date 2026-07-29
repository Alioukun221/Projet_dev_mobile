DART_DEFINES :=
ifneq ($(strip $(SUPABASE_URL)),)
DART_DEFINES += --dart-define=SUPABASE_URL=$(SUPABASE_URL)
endif
ifneq ($(strip $(SUPABASE_ANON_KEY)),)
DART_DEFINES += --dart-define=SUPABASE_ANON_KEY=$(SUPABASE_ANON_KEY)
endif
ifneq ($(strip $(SUPABASE_PUBLISHABLE_KEY)),)
DART_DEFINES += --dart-define=SUPABASE_PUBLISHABLE_KEY=$(SUPABASE_PUBLISHABLE_KEY)
endif
ifneq ($(strip $(GROQ_API_KEY)),)
DART_DEFINES += --dart-define=GROQ_API_KEY=$(GROQ_API_KEY)
endif
ifneq ($(strip $(GROQ_MODEL)),)
DART_DEFINES += --dart-define=GROQ_MODEL=$(GROQ_MODEL)
endif

.PHONY: get
get:
	@flutter pub get

.PHONY: build
build:
	@dart pub run build_runner build --delete-conflicting-outputs

.PHONY: watch
watch:
	@dart pub run build_runner watch --delete-conflicting-outputs

.PHONY: build-apk-prod-local
build-apk-prod-local:
	@powershell -NoProfile -ExecutionPolicy Bypass -Command ". .\.env.ps1; if (-not $$env:SUPABASE_URL) { throw 'SUPABASE_URL manquante' }; if (-not $$env:SUPABASE_ANON_KEY -and -not $$env:SUPABASE_PUBLISHABLE_KEY) { throw 'Clé Supabase manquante' }; flutter build apk --release --flavor production --target lib/main.dart --split-per-abi --obfuscate --split-debug-info=build/symbols \"--dart-define=SUPABASE_URL=$$env:SUPABASE_URL\" \"--dart-define=SUPABASE_ANON_KEY=$$env:SUPABASE_ANON_KEY\" \"--dart-define=SUPABASE_PUBLISHABLE_KEY=$$env:SUPABASE_PUBLISHABLE_KEY\" \"--dart-define=GROQ_API_KEY=$$env:GROQ_API_KEY\" \"--dart-define=GROQ_MODEL=$$env:GROQ_MODEL\""
	
.PHONY: apk-dev
apk-dev:
	@flutter build apk --debug --flavor development --target lib/main.dart $(DART_DEFINES)

.PHONY: run-dev
run-dev:
	@flutter run --debug --flavor development --target lib/main.dart $(DART_DEFINES)

.PHONY: run-dev-local
run-dev-local:
	@powershell -NoProfile -ExecutionPolicy Bypass -Command ". .\.env.ps1; Write-Host ('Using SUPABASE_URL=' + $$env:SUPABASE_URL); $$defs = @('--dart-define=SUPABASE_URL=' + $$env:SUPABASE_URL); if ($$env:SUPABASE_ANON_KEY) { $$defs += '--dart-define=SUPABASE_ANON_KEY=' + $$env:SUPABASE_ANON_KEY }; if ($$env:SUPABASE_PUBLISHABLE_KEY) { $$defs += '--dart-define=SUPABASE_PUBLISHABLE_KEY=' + $$env:SUPABASE_PUBLISHABLE_KEY }; if ($$env:GROQ_API_KEY) { $$defs += '--dart-define=GROQ_API_KEY=' + $$env:GROQ_API_KEY }; if ($$env:GROQ_MODEL) { $$defs += '--dart-define=GROQ_MODEL=' + $$env:GROQ_MODEL }; flutter run --debug --flavor development --target lib/main.dart @defs"

.PHONY: apk-stg
apk-stg:
	@flutter build apk --profile --flavor staging --target lib/main.dart $(DART_DEFINES)

.PHONY: apk-prod
apk-prod:
	@flutter build apk --release --flavor production --target lib/main.dart $(DART_DEFINES)

.PHONY: upgrade
upgrade: 
	@flutter packages upgrade

.PHONY: ipa-dev
ipa-dev:
	@flutter build ipa --debug --flavor development --target lib/main.dart $(DART_DEFINES)

.PHONY: ipa-stg
ipa-stg:
	@flutter build ipa --profile --flavor staging --target lib/main.dart $(DART_DEFINES)

.PHONY: ipa-prod
ipa-prod:
	@flutter build ipa --release --flavor production --target lib/main.dart $(DART_DEFINES)

.PHONY: test
test:
	@flutter test --coverage --test-randomize-ordering-seed random

.PHONY: fix
fix:
	@dart fix --apply

.PHONY: check-fix
check-fix:
	@dart fix --dry-run

.PHONY: analyze
analyze:
	@dart analyze lib test

.PHONY: format
format:
	@dart format --set-exit-if-changed lib test

.PHONY: prepare
prepare: fix format analyze

