$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}
Invoke-Expression (& { (zoxide init --cmd cd powershell | Out-String) })
function activate {
    & "C:\Users\ohp460\Scripts\activate-venv.ps1"
}
function arbiter { ssh guggoo@arbiter }
function ex {
    explorer.exe $PWD.Path
}
