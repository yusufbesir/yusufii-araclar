# Depoyu iki GitHub hesabina gonderir: origin (yusufbesir, asil) ve yedek (yonkoakira).
# Kullanim: .\yedekle.ps1
$ErrorActionPreference = 'Stop'
$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
$gh = 'C:\Program Files\GitHub CLI\gh.exe'
Set-Location $PSScriptRoot
try {
    & $gh auth switch --hostname github.com --user yusufbesir
    git push origin main
    & $gh auth switch --hostname github.com --user yonkoakira
    git push yedek main
}
finally {
    & $gh auth switch --hostname github.com --user yusufbesir
}
& $gh auth status
