#Requires -Version 5.0

function Get-LabEnvironment
{
    [CmdletBinding(DefaultParameterSetName = 'EnvironmentName')]
    param (
        [Parameter(Mandatory = $false, Position = 0, ParameterSetName = 'EnvironmentName')]
        [string[]]$Name,
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'EnvironmentPath')]
        [string]$Path
    )

    if ($($PSCmdlet.ParameterSetName) -eq 'EnvironmentName') {
        $filePath = Join-Path -Path $script:configurationPath -ChildPath 'environments.json'
        if (Test-Path -Path $filePath -PathType Leaf) {
            $environments = Get-Content -Path $filePath -Raw | ConvertFrom-Json | Convert-PSObjectToHashtable
            foreach ($environmentName in $environments.Keys) {
                if (-not $Name -or $Name -contains $environmentName) {
                    $environmentFilePath = $environments.$environmentName
                    if (Test-Path -Path $environmentFilePath -PathType Container) {
                        $environmentFilePath = Join-Path -Path $environmentFilePath -ChildPath 'environment.json'
                    }
                    if (Test-Path -Path $environmentFilePath -PathType Leaf) {
                        Write-Output (Convert-FromJsonObject -InputObject (Get-Content -Path $environmentFilePath -Raw | ConvertFrom-Json) -TypeName 'LabEnvironment')
                    }
                }
            }
        }
    }
    else {
        if (Test-Path -Path $Path -PathType Container) {
            $Path = Join-Path -Path $Path -ChildPath 'environment.json'
        }
        if (Test-Path -Path $Path -PathType Leaf) {
            $environment = Convert-FromJsonObject -InputObject (Get-Content -Path $Path -Raw | ConvertFrom-Json) -TypeName 'LabEnvironment'
            if ($environment.Path.StartsWith('.')) {
                $environment.Path = [System.IO.Path]::GetFullPath((Join-Path -Path (Split-Path -Path $Path -Parent) -ChildPath $environment.Path))
            }

            Write-Output $environment
        }
    }
}