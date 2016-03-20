param (
#    [Version]$Version,
    [Parameter(Mandatory = $true)]
    [string]$ApiKey,
    [switch]$Force
)

$packageName = 'HyperVLab'
$repositoryName = 'PSGallery'

Write-Host -Object "Finding latest version of the module on '$repositoryName'..."
$latestModule = Find-Module -Name $packageName -Repository $repositoryName -ErrorAction Stop
if (-not $latestModule) {
    throw 'Module not found.'
}

# determine the new version
$Version = "$($latestModule.Version.Major).$($latestModule.Version.Minor).$($latestModule.Version.Build).$($latestModule.Version.Revision + 1)"

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
    Publish-Module -NuGetApiKey $ApiKey -Path 'D:\Projects.GitHub\HyperVLab\src\HyperVLab'
    Write-Host -Object "Version '$Version' published"
    
    Set-Content -Path $manifestFilePath -Value $originalContent
}
