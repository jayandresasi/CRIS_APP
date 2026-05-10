$src = "C:\Users\User\Documents\Rabies-Hiligaynon-and-Karay-a-1.pdf"
$destDir = "c:\Users\User\CRISS APP\CRIS_APP\flutter_application_1\assets\documents"

if (-not (Test-Path $src)) {
    Write-Host "Source PDF not found: $src" -ForegroundColor Red
    exit 1
}

New-Item -ItemType Directory -Force -Path $destDir | Out-Null
Copy-Item -Path $src -Destination (Join-Path $destDir 'Rabies-Hiligaynon-and-Karay-a-1.pdf') -Force
Write-Host "Copied PDF to: $destDir" -ForegroundColor Green
