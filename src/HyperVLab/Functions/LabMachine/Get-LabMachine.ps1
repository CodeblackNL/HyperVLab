#Requires -Version 5.0

function Get-LabMachine
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

        foreach ($e in $Environment) {
            if ($e.Machines) {
                foreach ($machine in $e.Machines) {
                    if (-not $Name -or @($Name |? { $machine.Name -like $_ }).Length -gt 0) {
                        Write-Output $machine
                    }
                }
            }
        }
    }
}