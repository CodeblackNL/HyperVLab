#Requires -Version 5.0

function Enter-LabVMSession {
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Configuration')]
        [PSCustomObject]$Configuration,
        [Parameter(Mandatory = $true, ParameterSetName = 'MachineName')]
        [string]$MachineName,
        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $true, ParameterSetName = 'MachineName')]
        [PSCredential]$Credential,
        [Parameter(Mandatory = $false)]
        [string]$NetworkAdapterName
    )

    if (-not (Test-Administrator)) {
        throw 'Please run this command as Administrator.'
    }

    if (-not $MachineName) {
        $MachineName = $Configuration.MachineName
    }

    if (-not $Credential -and $Configuration.Domain.AdministratorPassword) {
        $securePassword = ConvertTo-SecureString -String $Configuration.Domain.AdministratorPassword -AsPlainText -Force
        $Credential = New-Object -TypeName PSCredential -ArgumentList "$($Configuration.Domain.NetbiosName)\Administrator",$securePassword
    }
    if (-not $Credential) {
        $securePassword = ConvertTo-SecureString -String $Configuration.AdministratorPassword -AsPlainText -Force
        $Credential = New-Object -TypeName PSCredential -ArgumentList 'Administrator',$securePassword
    }

    $vm = Get-VM | Where-Object { $_.Name -eq $MachineName }
    if (-not $vm) {
        throw "Lab-VM with name '$MachineName' not found"
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
        throw "Unable to determine ip-address for Lab-VM with name '$MachineName'"
    }

    return Enter-PSSession -ComputerName $ipAddress -Credential $Credential
}
