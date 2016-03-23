#Requires -Version 5.0

function Remove-LabVMFromDomain {
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Configuration')]
        [PSCustomObject]$Configuration,
        [Parameter(Mandatory = $true, ParameterSetName = 'MachineName')]
        [string]$MachineName,
        [Parameter(Mandatory = $false, ParameterSetName = 'MachineName')]
        [string]$IPAddress,
        [Parameter(Mandatory = $true, ParameterSetName = 'MachineName')]
        [string]$DomainController,
        [Parameter(Mandatory = $true, ParameterSetName = 'MachineName')]
        [PSCredential]$DomainCredential
    )

    if (-not $MachineName) {
        $MachineName = $Configuration.MachineName
    }

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
}
