#Requires -Version 5.0

function Enter-LabVMSession {
    [CmdletBinding(DefaultParameterSetName = 'MachineName')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Machine', ValueFromPipeline = $true)]
        [LabMachine]$Machine,
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'MachineName')]
        [string]$MachineName,

        [PSCredential]$Credential,
        [Parameter(Mandatory = $false)]
        [string]$NetworkAdapterName,
        [Parameter(Mandatory = $false)]
        [switch]$CredSSP
    )

    if (-not (Test-Administrator)) {
        throw 'Please run this command as Administrator.'
    }

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

    if (-not $Credential) {
        $domainNetwork = $Machine.NetworkAdapters.Network |? { $_.Domain } | Select -First 1
        if ($domainNetwork) {
            $domain = $domainNetwork.Domain
            if ($domain.AdministratorPassword) {
                $Credential = New-Object -TypeName PSCredential -ArgumentList "$($domain.NetbiosName)\Administrator",$domain.AdministratorPassword
            }
        }
        if (-not $Credential) {
            $Credential = New-Object -TypeName PSCredential -ArgumentList "$($Machine.Name)\Administrator",$Machine.AdministratorPassword
        }
    }

    $vm = Get-VM | Where-Object { $_.Name -eq $Machine.Name }
    if (-not $vm) {
        throw "Lab-VM with name '$($Machine.Name)' not found"
    }

    if ($NetworkAdapterName) {
        $ipAddress = $vm `
            | Get-VMNetworkAdapter `
            | Select-Object -Property * -ExpandProperty IPAddresses `
            | Where-Object { $_.Name -eq $NetworkAdapterName -and $_.Contains('.') } `
            | Select-Object -First 1
    }
    else {
        $ipAddress = $vm `
            | Get-VMNetworkAdapter `
            | Select-Object -Property * -ExpandProperty IPAddresses `
            | Where-Object { $_.Contains('.') } `
            | Select-Object -First 1
    }

    if (-not $ipAddress) {
        throw "Unable to determine ip-address for Lab-VM with name '$($Machine.Name)'"
    }

    if ($CredSSP.IsPresent) {
        return Enter-PSSession -ComputerName $ipAddress -Credential $Credential -Authentication Credssp
    }
    else {
        return Enter-PSSession -ComputerName $ipAddress -Credential $Credential
    }
}
