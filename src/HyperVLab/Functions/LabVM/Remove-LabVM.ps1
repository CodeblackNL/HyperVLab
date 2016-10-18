#Requires -Version 5.0

function Remove-LabVM {
    [CmdletBinding(DefaultParameterSetName = 'MachineName', SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Machine', ValueFromPipeline = $true)]
        [LabMachine[]]$Machine,
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'MachineName')]
        [string[]]$MachineName,
        [Parameter(Mandatory = $true, ParameterSetName = 'Environment', ValueFromPipeline = $true)]
        [LabEnvironment[]]$Environment,
        [Parameter(Mandatory = $false)]
        [switch]$RemoveFromDomain,
        [Parameter(Mandatory = $false)]
        [switch]$Force

        #[Parameter(Mandatory = $false, ParameterSetName = 'MachineName')]
        #[string]$DomainController,
        #[Parameter(Mandatory = $false, ParameterSetName = 'MachineName')]
        #[PSCredential]$DomainCredential
    )

    Begin {
        if (-not (Test-Administrator)) {
            throw 'Please run this command as Administrator.'
        }
    }

    Process {
        if ($($PSCmdlet.ParameterSetName) -ne 'Machine') {
            if ($MachineName) {
                $Machine = Get-LabMachine -Name $MachineName
            }
            else {
                $Machine = Get-LabMachine
            }
        }

        if (-not $Machine) {
            return
        }

        foreach ($m in $Machine) {
            $vm = Get-VM | Where-Object { $_.Name -eq $m.Name }
            if ($vm) {
                if ($Force -or $PSCmdlet.ShouldProcess($m.Name)) {
                    Write-Verbose -Message "Removing lab-VM '$($m.Name)'..."
                    if ($vm.State -eq 'Running') {
                        Stop-VM -VM $vm -Force
                        while ($vm.State -ne 'Off') {
                            Start-Sleep -Seconds 1
                        }
                    }
    
                    $path = $vm.ConfigurationLocation

                    Remove-VM -VM $vm -Force
                    Start-Sleep -Seconds 2

                    try {
                        Get-ChildItem -Path (Join-Path -Path $path -ChildPath '*') -Directory | ForEach-Object {
                            try {
                                [System.IO.Directory]::Delete($_.FullName, $true)
                            }
                            catch {
                                Start-Sleep -Seconds 3
                            }
                        }
            
                        try {
                            [System.IO.Directory]::Delete($path, $true)
                        }
                        catch {
                            Start-Sleep -Seconds 3
                            [System.IO.Directory]::Delete($path, $true)
                        }
                    }
                    catch {
                        Write-Error -Message $_
                    }

                    Write-Verbose -Message "Finished removing lab-VM '$($m.Name)'"

                    if ($RemoveFromDomain) {
                        try
                        {
                            Write-Verbose -Message 'Removing machine '$($m.Name)' from domain...'

                            Remove-LabVMFromDomain -Machine $m
                            
                            Write-Verbose -Message "Finished removing machine '$($m.Name)' from domain."
                        }
                        catch {
                            Write-Warning -Message 'Removing machine from domain failed.'
                        }
                    }
                }
                else {
                Write-Verbose -Message "Confirmation denied for removing '$($m.Name)'; skipped removing lab-VM"
                }
            }
            else {
                Write-Verbose -Message "VM '$($m.Name)' not found; skipped removing lab-VM"
            }
        }
    }
}
