param (
    [Version]$Version,
    [switch]$Force
)

$packageName = 'HyperVLab'
# change the name of the repository as desired, but also change it in Publish-ToLocalRepository.ps1
$repositoryName = 'LocalDev'

if (-not $Version) {
    # determine the new version
    $latestModule = Find-Module -Name $packageName -Repository $repositoryName -ErrorAction SilentlyContinue
    if ($latestModule) {
        $Version = "$($latestModule.Version.Major).$($latestModule.Version.Minor).$($latestModule.Version.Build).$($latestModule.Version.Revision + 1)"
    }
    else {
        $Version = '0.0.0.1'
    }
}


if ($latestModule -and $newVersion -lt $latestModule.Version) {
#    throw 'Version not higher'
}

Write-Host -Object "Selected new version: '$Version' (current version: '$($latestModule.Version)')"
if (-not $Force.IsPresent) {
    $publish = Read-Host -Prompt 'Do you wish to publish? [y]es or [n]o'
}
else {
    $publish = 'Y'
}
if ($publish.ToUpperInvariant() -in 'Y','YES') {
    
    # modify the manifest
    $manifestFilePath = "$PSScriptRoot\..\src\$packageName\$packageName.psd1"
    if (-not (Test-Path -Path $manifestFilePath)) {
        throw "Manifest file '$manifestFilePath' not found"
    }
    $originalContent = Get-Content -Path $manifestFilePath
    $content = $originalContent | ForEach-Object {
        if ($_ -match '^ModuleVersion') {
            "ModuleVersion = '$Version'"
        }
        else {
            $_
        }
    }
    Set-Content -Path $manifestFilePath -Value $content

    # publish the module
    Publish-Module -Path "$PSScriptRoot\..\src\$packageName" -Repository $repositoryName -ErrorAction Stop
    Write-Host -Object "Version '$Version' published"
    
    Set-Content -Path $manifestFilePath -Value $originalContent
}
