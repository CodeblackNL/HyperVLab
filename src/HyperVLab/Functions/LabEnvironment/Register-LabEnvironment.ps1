#Requires -Version 5.0

function Register-LabEnvironment
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
            if (Test-Path -Path $Path -PathType Container) {
                Write-Verbose "path '$Path' is folder, assuming filename is missing"
                $Path = Join-Path -Path $Path -ChildPath 'environment.json'
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
        }
        if (-not $environments) {
            $environments = @{}
        }

        $update = $false
        foreach ($e in $Environment) {
            if (-not $environments.ContainsKey($e.Name) -or $Force.IsPresent -or $PSCmdlet.ShouldProcess($e.Name)) {
                $environments.($e.Name) = $e.Path
                $update = $true
            }
        }

        if ($update) {
            if (-not (Test-Path -Path (Split-Path -Path $filePath -Parent) -PathType Container)) {
                New-Item -Path (Split-Path -Path $filePath -Parent) -ItemType Directory -Force | Out-Null
            }

            $environments | ConvertTo-Json -Depth 9 | Out-File -FilePath $filePath
        }
 
        if ($PassThru.IsPresent) {
            return $Environment
        }
   }
}