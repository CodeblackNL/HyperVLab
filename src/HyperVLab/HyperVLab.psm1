#Requires -Version 5.0

Get-ChildItem -Path "$PSScriptRoot\Internal" -Filter '*.ps1' | ForEach-Object {
    . $_.FullName
}

Get-ChildItem -Path "$PSScriptRoot\Functions" -Filter '*.ps1' | ForEach-Object {
    . $_.FullName
}
