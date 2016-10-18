
function Get-LabMachineConfiguration {
    param (
        [Parameter(Mandatory = $true)]
        [LabMachine]$Machine
    )

    return New-Object LabMachine -Property @{
        Name = $Machine.Name
        AdministratorPassword = $(if ($Machine.AdministratorPassword) { $Machine.AdministratorPassword | ConvertTo-SecureString })
        TimeZone = $Machine.TimeZone
    }
}
