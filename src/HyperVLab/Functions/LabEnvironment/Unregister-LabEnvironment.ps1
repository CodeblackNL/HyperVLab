#Requires -Version 5.0

function Unregister-LabEnvironment
{
    [CmdletBinding(DefaultParameterSetName = 'EnvironmentPath', SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'EnvironmentPath')]
        [string]$Path,
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'EnvironmentObject', ValueFromPipeline = $true)]
        [LabEnvironment[]]$Environment,
        [Parameter(Mandatory = $false)]
        [switch]$PassThru,
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    Process {
        if ($($PSCmdlet.ParameterSetName) -eq 'EnvironmentPath') {
            if (-not $Path) {
                throw 'Provide a path to the environment.'
            }
            if (-not (Test-Path -Path $Path -PathType Leaf)) {
                throw 'The provided path does not reference an existing environment-file.'
            }

            $Environment = Get-LabEnvironment -Path $Path
        }

        if (-not $Environment) {
            return
        }

        $filePath = Join-Path -Path $script:configurationPath -ChildPath 'environments.json'
        if (Test-Path -Path $filePath -PathType Leaf) {
            $environments = Get-Content -Path $filePath -Raw | ConvertFrom-Json | Convert-PSObjectToHashtable
            if ($environments) {
                $update = $false
                foreach ($e in $Environment) {
                    if ($environments.ContainsKey($e.Name) -and ($Force.IsPresent -or $PSCmdlet.ShouldProcess($e.Name))) {
                        $environments.Remove($e.Name)
                        $update = $true
                    }
                }

                if ($update) {
                    $environments | ConvertTo-Json -Depth 9 | Out-File -FilePath $filePath
                }
            }
        }

        if ($PassThru.IsPresent) {
            return $Environment
        }
    }
}