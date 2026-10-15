# Depoyu iki GitHub hesabina gonderir: origin (yusufbesir, asil) ve yedek (yonkoakira).
# Her push'tan sonra cikis kodu denetlenir; iki depo da private olmalidir.
# Kullanim: .\yedekle.ps1
$ErrorActionPreference = 'Stop'
$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
$gh = 'C:\Program Files\GitHub CLI\gh.exe'
Set-Location $PSScriptRoot

function Assert-Private([string]$Remote) {
    $url = git remote get-url $Remote
    if ($LASTEXITCODE -ne 0) { throw "$Remote uzak adresi okunamadi." }
    $repo = $url -replace '^https://github\.com/', '' -replace '\.git$', ''
    $vis = & $gh repo view $repo --json visibility --jq .visibility
    if ($LASTEXITCODE -ne 0) { throw "$repo gorunurlugu okunamadi." }
    if ($vis -ne 'PRIVATE') { throw "$repo private degil ($vis); gonderim durduruldu." }
}

function Push-Remote([string]$Remote) {
    git push $Remote main
    if ($LASTEXITCODE -ne 0) { throw "git push $Remote main basarisiz (cikis kodu $LASTEXITCODE)." }
}

try {
    & $gh auth switch --hostname github.com --user yusufbesir
    if ($LASTEXITCODE -ne 0) { throw 'gh hesabi yusufbesir secilemedi.' }
    Assert-Private origin
    Push-Remote origin
    & $gh auth switch --hostname github.com --user yonkoakira
    if ($LASTEXITCODE -ne 0) { throw 'gh hesabi yonkoakira secilemedi.' }
    Assert-Private yedek
    Push-Remote yedek
}
finally {
    & $gh auth switch --hostname github.com --user yusufbesir
}
& $gh auth status
