#Requires -Version 5.0

function New-LabEnvironment
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', 'Impact is low, no point in supporting ShouldProcess')]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $false)]
        [string]$Path,
        [Parameter(Mandatory = $false)]
        [string]$FilesPath
    )

    $filePath = Join-Path -Path $script:configurationPath -ChildPath "environments\$Name.json"

    if (Test-Path -Path $filePath)
    {
        throw "A lab-environment with name '$Name' already exists."
    }

    # TODO: validate characters in Name; should be valid for filename

    $environment = New-Object LabEnvironment
    $environment.Name = $Name
    $environment.Path = $Path
    $environment.FilesPath = $FilesPath

    $folderPath = Split-Path -Path $filePath -Parent
    if (-not (Test-Path -Path $folderPath))
    {
        New-Item -Path $folderPath -ItemType Directory | Out-Null
    }

    $environment | ConvertTo-Json -Depth 9 | Out-File -FilePath $filePath

    return $environment
}