#Requires -Version 5.0

$script:configurationPath = (Join-Path -Path $env:ALLUSERSPROFILE -ChildPath 'HyperVLab')

. "$PSScriptRoot\Classes.ps1"

Get-ChildItem -Path "$PSScriptRoot\Internal" -Filter '*.ps1' -Recurse | ForEach-Object {
    . $_.FullName
}

Get-ChildItem -Path "$PSScriptRoot\Functions" -Filter '*.ps1' -Recurse | ForEach-Object {
    . $_.FullName
    Export-ModuleMember -Function ([System.IO.Path]::GetFileNameWithoutExtension($_.Name))
}
