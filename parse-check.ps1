$errs = $null
[System.Management.Automation.Language.Parser]::ParseFile('C:\Users\SAMPC\remoteworkhub-us-astro\regen.ps1', [ref]$null, [ref]$errs) | Out-Null
if ($errs.Count -gt 0) {
  foreach ($e in $errs) { Write-Host "ERR line $($e.Extent.StartLineNumber): $($e.Message)" }
  exit 1
} else {
  Write-Host "SYNTAX OK"
  exit 0
}
