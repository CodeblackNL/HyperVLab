#Requires -Version 5.0

function Import-LabEnvironment
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # validate file-path

    # read environment from file-path
    # validate environment

    #$filePath = Join-Path -Path $script:configurationPath -ChildPath "environments\$Name.json"

    if ($Force -or $PSCmdlet.ShouldProcess($Name))
    {
        #Remove-Item -Path $filePath -Force -Confirm:$false
    }
}