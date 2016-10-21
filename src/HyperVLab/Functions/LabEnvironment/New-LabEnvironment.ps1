#Requires -Version 5.0

function New-LabEnvironment
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', 'Impact is low, no point in supporting ShouldProcess')]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $false)]
        [string]$Path = '.',
        [Parameter(Mandatory = $false)]
        [string]$MachinesPath = '.\Machines',
        [Parameter(Mandatory = $false)]
        [string]$FilesPath,
        [Parameter(Mandatory = $false)]
        [string]$ConfigurationFilePath = '.\Configuration\LabConfiguration.ps1',
        [Parameter(Mandatory = $false)]
        [string]$ConfigurationName,
        [Parameter(Mandatory = $false)]
        [Hashtable]$Properties,
        [switch]$Force
    )

    # TODO: validate parameters

    if ($Path -ne [System.IO.Path]::GetFullPath($Path)) {
        $Path = [System.IO.Path]::GetFullPath((Join-Path -Path (Get-Location) -ChildPath $Path))
    }

    $labFilePath = Join-Path -Path $Path -ChildPath 'environment.json'

    if ((Test-Path -Path $labFilePath -PathType Leaf) -and -not $Force.IsPresent) {
        throw "The environment-file '$labFilePath' already exists; use -Force to create the lab-environment in this location."
    }

    if ($MachinesPath -and $MachinesPath.ToUpper().StartsWith($Path.ToUpper())) {
        $MachinesPath = Join-Path -Path '.' -ChildPath $MachinesPath.Substring($Path.Length)
    }
    if ($FilesPath -and $FilesPath.ToUpper().StartsWith($Path.ToUpper())) {
        $FilesPath = Join-Path -Path '.' -ChildPath $FilesPath.Substring($Path.Length)
    }
    if ($ConfigurationFilePath -and $ConfigurationFilePath.ToUpper().StartsWith($Path.ToUpper())) {
        $ConfigurationFilePath = Join-Path -Path '.' -ChildPath $ConfigurationFilePath.Substring($Path.Length)
    }

    $environment = New-Object LabEnvironment
    $environment.Name = $Name
    $environment.Path = $Path
    $environment.MachinesPath = $MachinesPath
    $environment.FilesPath = $FilesPath
    $environment.ConfigurationFilePath = $ConfigurationFilePath
    $environment.ConfigurationName = $ConfigurationName
    $environment.Properties = @{}
    if ($Properties) {
        foreach ($key in $Properties.Keys) {
            $environment.Properties.$key = $Properties.$key
        }
    }

    if (-not (Test-Path -Path $Path)) {
        New-Item -Path $Path -ItemType Directory | Out-Null
    }

    $environment | ConvertTo-Json -Depth 9 | Out-File -FilePath $labFilePath

    if ($environment.ConfigurationFilePath) {
        $ConfigurationFilePath = $environment.ConfigurationFilePath
        if ($ConfigurationFilePath.StartsWith('.')) {
            $ConfigurationFilePath = [System.IO.Path]::GetFullPath((Join-Path -Path $Path -ChildPath $ConfigurationFilePath))
        }

        if (-not (Test-Path -Path $ConfigurationFilePath -PathType Leaf)) {
            $ConfigurationContent = ''
            if ($ConfigurationName) {
                $ConfigurationContent = @("Configuration $ConfigurationName {",'}')
            }

            $ConfigurationFolderPath = Split-Path -Path $ConfigurationFilePath -Parent
            if (-not (Test-Path -Path $ConfigurationFolderPath -PathType Container)) {
                New-item -Path $ConfigurationFolderPath -ItemType Directory | Out-Null
            }

            if ($update) {
                $ConfigurationContent | Out-File -FilePath $ConfigurationFilePath
            }
        }
    }

    Register-LabEnvironment -Environment $environment -Force:$Force.IsPresent

    return $environment
}
