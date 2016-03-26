#Requires -Version 5.0

function Update-BootOrder {
    param (
        $VM,
        [string]$MachineName,
        [string]$BootDrivePath,
        [switch]$BootDisk
    )

    if (!$VM -and $MachineName) {
        $VM = Get-VM | Where-Object { $_.Name -eq $MachineName }
    }

    if ($VM) {
        if (!$BootDrivePath -and $BootDisk) {
            $BootDrivePath = (Get-VMHardDiskDrive -VMName $VM.Name  -ControllerNumber 0 -ControllerLocation 0).Path
        }

        if ($BootDrivePath) {
            $bootOrder = (Get-VMFirmware -VM $VM).BootOrder
            $bootDrive = $bootOrder | Where-Object { $_.BootType -eq 'Drive' -and $_.Device.Path -eq $BootDrivePath }
            $newBootOrder = @()
            $newBootOrder += $bootDrive
            $newBootOrder += $bootOrder | Where-Object { $_ -ne $bootDrive }
            Set-VMFirmware -VM $VM -BootOrder $newBootOrder
        }
    }
}
