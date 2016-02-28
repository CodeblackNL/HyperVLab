param (
    [Version]$Version,
    [switch]$Force
)

$packageName = 'HyperVLab'
# change the name of the repository as desired, but also change it in Publish-ToLocalRepository.ps1
$repositoryName = 'LocalDev'

$major = $Version.Major
$minor = $Version.Minor
$build = $Version.Build
$revision = $Version.Revision

# determine the new version
$latestModule = Find-Module -Name $packageName -Repository $repositoryName -ErrorAction SilentlyContinue
if ($latestModule) {
    if ($major -lt 0) {
        $major = $latestModule.Version.Major
    }
    if ($minor -lt 0) {
        $minor = $latestModule.Version.Minor
    }
    if ($build -lt 0) {
        if ($minor -gt $latestModule.Version.Minor) {
            $build =0
        }
        else {
            $build = $latestModule.Version.Build + 1
        }
    }
    if ($revision -lt 0) {
        $revision = 0
    }
}
else {
    if ($major -lt 0) {
        throw 'Invalid major version'
    }
    if ($minor -lt 0) {
        throw 'Invalid minor version'
    }
    if ($build -lt 0) {
        $build = 0
    }
    if ($revision -lt 0) {
        $revision = 0
    }
}

[Version]$newVersion = "$major.$minor.$build.$revision"

if ($latestModule -and $newVersion -lt $latestModule.Version) {
    throw "Version not higher"
}

Write-Host "Selected new version: '$newVersion' (current version: '$($latestModule.Version)')"
if (-not $Force.IsPresent) {
    $publish = Read-Host 'Do you wish to publish? [y]es or [n]o'
}
else {
    $publish = 'Y'
}
if ($publish.ToUpperInvariant() -in 'Y','YES') {
    
    # modify the manifest
    $manifestFilePath = "$PSScriptRoot\..\src\$packageName\$packageName.psd1"
    if (-not (Test-Path $manifestFilePath)) {
        throw "Manifest file '$manifestFilePath' not found"
    }
    $content = Get-Content -Path $manifestFilePath
    $content = $content |% {
        if ($_ -match '^ModuleVersion') {
            "ModuleVersion = '$newVersion'"
        }
        else {
            $_
        }
    }
    Set-Content -Path $manifestFilePath -Value $content

    # publish the module
    Publish-Module -Path "$PSScriptRoot\..\src\$packageName" -Repository $repositoryName
}
