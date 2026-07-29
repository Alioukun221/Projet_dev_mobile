$ErrorActionPreference = "Stop"

# ---------------------------------------------------------
# Project root
# ---------------------------------------------------------

$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

$envFile = Join-Path $projectRoot ".env.ps1"

if (-not (Test-Path $envFile)) {
    throw "Fichier .env.ps1 introuvable : $envFile"
}

# ---------------------------------------------------------
# Load environment variables
# ---------------------------------------------------------

. $envFile

# ---------------------------------------------------------
# Validate required variables
# ---------------------------------------------------------

if ([string]::IsNullOrWhiteSpace($env:SUPABASE_URL)) {
    throw "SUPABASE_URL est absente."
}

$supabaseKey = $null
$keyName = $null

if (-not [string]::IsNullOrWhiteSpace($env:SUPABASE_PUBLISHABLE_KEY)) {
    $supabaseKey = $env:SUPABASE_PUBLISHABLE_KEY
    $keyName = "SUPABASE_PUBLISHABLE_KEY"
}
elseif (-not [string]::IsNullOrWhiteSpace($env:SUPABASE_ANON_KEY)) {
    $supabaseKey = $env:SUPABASE_ANON_KEY
    $keyName = "SUPABASE_ANON_KEY"
}
else {
    throw "SUPABASE_PUBLISHABLE_KEY ou SUPABASE_ANON_KEY est obligatoire."
}

# ---------------------------------------------------------
# Display configuration (without exposing secrets)
# ---------------------------------------------------------

Write-Host ""
Write-Host "========== Build Configuration =========="
Write-Host "SUPABASE_URL               : OK"
Write-Host "$keyName : OK"
Write-Host "GROQ_MODEL                 : $($env:GROQ_MODEL)"

if ($env:GROQ_API_KEY) {
    Write-Host "GROQ_API_KEY               : OK"
}
else {
    Write-Host "GROQ_API_KEY               : NON DEFINIE"
}

Write-Host "========================================="
Write-Host ""

# ---------------------------------------------------------
# Flutter arguments
# ---------------------------------------------------------

$flutterArguments = @(
    "build",
    "apk",
    "--release",
    "--flavor", "production",
    "--target", "lib/main.dart",
    "--split-per-abi",
    "--obfuscate",
    "--split-debug-info=build/symbols",
    "--dart-define=SUPABASE_URL=$($env:SUPABASE_URL)",
    "--dart-define=$keyName=$supabaseKey"
)

if (-not [string]::IsNullOrWhiteSpace($env:GROQ_MODEL)) {
    $flutterArguments += "--dart-define=GROQ_MODEL=$($env:GROQ_MODEL)"
}

if (-not [string]::IsNullOrWhiteSpace($env:GROQ_API_KEY)) {
    $flutterArguments += "--dart-define=GROQ_API_KEY=$($env:GROQ_API_KEY)"
}

# ---------------------------------------------------------
# Build
# ---------------------------------------------------------

Write-Host "Building APK..."
Write-Host ""

& flutter @flutterArguments

if ($LASTEXITCODE -ne 0) {
    throw "Le build Flutter a échoué (code $LASTEXITCODE)."
}

Write-Host ""
Write-Host "Build terminé avec succès."