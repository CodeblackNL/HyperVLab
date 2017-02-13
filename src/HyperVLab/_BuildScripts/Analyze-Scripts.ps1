
$rootPath = Join-Path -Path $PSScriptRoot -ChildPath '..'
$violations = @()

$violations += Invoke-ScriptAnalyzer -Path (Join-Path -Path $rootPath -ChildPath 'Classes.ps1')

Get-ChildItem -Path (Join-Path -Path $rootPath -ChildPath 'Internal') -Recurse -File | ForEach-Object {
    $violations += Invoke-ScriptAnalyzer -Path $_.FullName
}

Get-ChildItem -Path (Join-Path -Path $rootPath -ChildPath 'Functions') -Recurse -File | ForEach-Object {
    $rules += Invoke-ScriptAnalyzer -Path $_.FullName
}

$violations | ft -AutoSize

if ($violations.Length -gt 0) {
    Write-Error -Message "Found $($violations.Length) violations."
}
else {
    Write-Host "Found no violations."
}