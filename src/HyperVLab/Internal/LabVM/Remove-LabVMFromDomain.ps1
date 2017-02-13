#Requires -Version 5.0

function Remove-LabVMFromDomain {
    [CmdletBinding(DefaultParameterSetName = 'MachineName', SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Machine', ValueFromPipeline = $true)]
        [LabMachine[]]$Machine,
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'MachineName')]
        [string[]]$MachineName,
        [Parameter(Mandatory = $false)]
        [string]$DomainName
        #[Parameter(Mandatory = $false, ParameterSetName = 'MachineName')]
        #[string]$IPAddress,
        #[Parameter(Mandatory = $true, ParameterSetName = 'MachineName')]
        #[string]$DomainController,
        #[Parameter(Mandatory = $true, ParameterSetName = 'MachineName')]
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

        # TODO: validate if each machine can be remove from it's domain
        #       - single domain in machine
        #       - provided DomainName exists for machine

        foreach ($m in $Machine) {
            $domain = $m.NetworkAdapters.Network.Domain | Where-Object { $_ }
            if ($DomainName) {
                $domain = $domain | Where-Object { $_.Name -eq $DomainName }
                if (-not $domain) {
                    Write-Error "No domain found for machine '$($m.Name)' with name '$DomainName'"
                }
            }
            if (-not $domain) {
                Write-Error "No domain found for machine '$($m.Name)'"
            }
            if (@($domain).Length -gt 1) {
                Write-Error "Mulptiple domains found for machine '$($m.Name)': '$($domain.Name)'"
            }

            $networkAdapter = $m.NetworkAdapters | Where-Object { $_.Network.Domain.Name -eq $domain.Name }

            # NOTE: this assumes there is a single domain-controller that is also the DNS-server
            $domainController = $domain.DnsServerIPAddress
            $domainCredential = New-Object -TypeName PSCredential -ArgumentList "$($domain.Name)\Administrator",$domain.AdministratorPassword

            try {
                Write-Verbose -Message "Removing '$($m.Name)' from domain '$($domain.Name)'"
                # use a remote session to execute the script
                $session = New-PSSession -ComputerName $domainController -Credential $domainCredential -ErrorAction SilentlyContinue
                Invoke-Command -Session $session -ScriptBlock {
                    param (
				        [string]$MachineName,
                        [string]$IPAddress
                    )

			        $computer = Get-ADComputer -Filter { Name -eq $MachineName } -ErrorAction SilentlyContinue
                    if (-not $computer -and $IPAddress) {
				        $computer = Get-ADComputer -Filter { IPv4Address -eq $IPAddress } -ErrorAction SilentlyContinue
                    }

                    if ($computer) {
                        Remove-ADObject -Identity $computer -Recursive -Confirm:$false
                    }
                } -ArgumentList $m.Name,$networkAdapter.StaticIPAddress
                Remove-PSSession -Session $session
        
                Write-Verbose -Message 'Remote-session finished'
            }
            catch {
                Write-Warning -Message "Unable to connect to domain-controller '$domainController'."
            }

        }

<#
        if (-not $DomainController) {
            $DomainController = $Configuration.Domain.DnsServerIPAddress
        }

        if (-not $DomainCredential) {
            $securePassword = ConvertTo-SecureString -String $Configuration.Domain.AdministratorPassword -AsPlainText -Force
            $domainCredential = New-Object -TypeName PSCredential -ArgumentList "Administrator@$($Configuration.Domain.Name)",$securePassword
        }

        try {
            Write-Verbose -Message "Removing '$MachineName' from domain-controller '$DomainController'"
            # use a remote session to execute the script
            $session = New-PSSession -ComputerName $DomainController -Credential $DomainCredential -ErrorAction SilentlyContinue
            Invoke-Command -Session $session -ScriptBlock {
                param (
				    [string]$MachineName,
                    [string]$IPAddress
                )

			    $computer = Get-ADComputer -Filter { Name -eq $MachineName } -ErrorAction SilentlyContinue
                if (-not $computer -and $IPAddress) {
				    $computer = Get-ADComputer -Filter { IPv4Address -eq $IPAddress } -ErrorAction SilentlyContinue
                }

                if ($computer) {
                    Remove-ADObject -Identity $computer -Recursive -Confirm:$false
                }
            } -ArgumentList $MachineName,$IPAddress
            Remove-PSSession -Session $session
        
            Write-Verbose -Message 'Remote-session finished'
        }
        catch {
            Write-Warning -Message "Unable to connect to domain-controller '$DomainController'."$_"Unable to connect to domain-controller '$DomainController'."
        }
#>
    }
}
