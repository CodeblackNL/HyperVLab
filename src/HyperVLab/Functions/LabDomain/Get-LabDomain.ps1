#Requires -Version 5.0

function Get-LabDomain
{
    [CmdletBinding(DefaultParameterSetName = 'EnvironmentName')]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [string[]]$Name,
        [Parameter(Mandatory = $false, ParameterSetName = 'Environment', ValueFromPipeline = $true)]
        [LabEnvironment[]]$Environment,
        [Parameter(Mandatory = $false, ParameterSetName = 'EnvironmentName')]
        [string[]]$EnvironmentName
    )

    Process {
        if ($($PSCmdlet.ParameterSetName) -ne 'Environment') {
            if ($EnvironmentName) {
                $Environment = Get-LabEnvironment -Name $EnvironmentName
            }
            else {
                $Environment = Get-LabEnvironment
            }
        }

        if (-not $Environment) {
            return
        }

        foreach ($e in $Environment)
        {
            if ($e.Domains) {
                foreach ($domain in $e.Domains) {
                    if (-not $Name -or @($Name |? { $domain.Name -like $_ }).Length -gt 0)
                    {
                        Write-Output $domain
                    }
                }
            }
        }
    }
}