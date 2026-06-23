# Arranca NEXUS en Chrome evitando bloqueos de OneDrive en build/
Set-Location $PSScriptRoot

Write-Host "Limpiando cache de build..." -ForegroundColor Yellow
Remove-Item -Recurse -Force build -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "windows\flutter\ephemeral\.plugin_symlinks" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "linux\flutter\ephemeral\.plugin_symlinks" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "macos\flutter\ephemeral\.plugin_symlinks" -ErrorAction SilentlyContinue

flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Iniciando NEXUS en Chrome..." -ForegroundColor Green
flutter run -d chrome
