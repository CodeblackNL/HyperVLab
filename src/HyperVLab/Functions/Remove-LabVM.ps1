#Requires -Version 5.0

function Remove-LabVM {
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Configuration')]
        [PSCustomObject]$Configuration,
        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [switch]$RemoveFromDomain,
        [Parameter(Mandatory = $true, ParameterSetName = 'MachineName')]
        [string]$MachineName,
        [Parameter(Mandatory = $false, ParameterSetName = 'MachineName')]
        [string]$DomainController,
        [Parameter(Mandatory = $false, ParameterSetName = 'MachineName')]
        [PSCredential]$DomainCredential
    )

    if (-not (Test-Administrator)) {
        throw 'Please run this command as Administrator.'
    }

    try
    {
        if ($Configuration -and $RemoveFromDomain) {
            Remove-LabVMFromDomain -Configuration $Configuration
        }
        elseif ($MachineName -and $DomainController -and $DomainCredential) {
            Remove-LabVMFromDomain -Configuration $Configuration
        }
    }
    catch {
        Write-Warning -Message 'Removing machine from domain failed.'
    }

    if (-not $MachineName) {
        $MachineName = $Configuration.MachineName
    }

    $vm = Get-VM | Where-Object { $_.Name -eq $MachineName }
    if ($vm) {
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
    }
}
