#Requires -Version 5.0

function Remove-LabEnvironment
{
    [CmdletBinding(DefaultParameterSetName = 'EnvironmentName', SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'EnvironmentName')]
        [string]$Name,
        [Parameter(Mandatory = $true, ParameterSetName = 'Environment', ValueFromPipeline = $true)]
        [LabEnvironment]$Environment,
        [Parameter(Mandatory = $false)]
        [switch]$Force
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
            else
            {
                if ($Force -or $PSCmdlet.ShouldProcess($Name))
                {
                    Remove-Item -Path $filePath -Force -Confirm:$false
                }
            }
        }
    }
}