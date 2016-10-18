#Requires -Version 5.0

function Set-LabEnvironment
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', 'Impact is low, no point in supporting ShouldProcess')]
    [CmdletBinding(DefaultParameterSetName = 'EnvironmentName')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'EnvironmentName')]
        [string]$Name,
        [Parameter(Mandatory = $true, ParameterSetName = 'Environment', ValueFromPipeline = $true)]
        [LabEnvironment]$Environment,
        [Parameter(Mandatory = $false)]
        [string]$Path,
        [Parameter(Mandatory = $false)]
        [string]$FilesPath
    )

    Process {
        if ($($PSCmdlet.ParameterSetName) -ne 'Environment') {
            if ($Name) {
                $Environment = Get-LabEnvironment -Name $Name
            }
            else {
                $Environment = Get-LabEnvironment
            }
        }

        if (-not $Environment) {
            return
        }

        foreach ($e in $Environment) {
            $filePath = Join-Path -Path $script:configurationPath -ChildPath "environments\$($e.Name).json"

            if (-not (Test-Path -Path $filePath))
            {
                throw "A lab-environment with name '$($e.Name)' does not exist."
            }

            if ($Path) {
                $e.Path = $Path
            }
            if ($FilesPath) {
                $e.FilesPath = $FilesPath
            }

            $folderPath = Split-Path -Path $filePath -Parent
            if (-not (Test-Path -Path $folderPath))
            {
                New-Item -Path $folderPath -ItemType Directory | Out-Null
            }

            $environment | ConvertTo-Json -Depth 9 | Out-File -FilePath $filePath
        }
    }
}