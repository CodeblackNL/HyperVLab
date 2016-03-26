#Requires -Version 5.0

function New-LabVM {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [PSCustomObject]$Configuration,
        [Parameter(Mandatory = $false)]
        [PSCredential]$Credential,
        [Parameter(Mandatory = $false)]
        [Switch]$Force = $false,
        [Parameter(Mandatory = $false)]
        [Switch]$Start = $false,
        [Parameter(Mandatory = $false)]
        [Switch]$Connect = $false
    )

    #region Validation

    # TODO: validate the configuration

    if (-not (Test-Administrator)) {
        throw 'Please run this command as Administrator.'
    }

    if (-not $Configuration.MachineName) {
        throw 'Please provide MachineName in Configuration.'
    }

    # if dynamic memory is to be used, both minimum & maximum must be provided
    if ((!$Configuration.Hardware.MinimumMemory -and $Configuration.Hardware.MaximumMemory) -or ($Configuration.Hardware.MinimumMemory -and !$Configuration.Hardware.MaximumMemory)) {
        throw 'Invalid Dynamic Memory'
    }

    <#if ($InternalSwitchName -and !(Get-VMSwitch | Where { $_.Name -eq $InternalSwitchName })) {
            throw "A switch with name '$InternalSwitchName' was not found."
            }
            if ($ExternalSwitchName -and !(Get-VMSwitch | Where { $_.Name -eq $ExternalSwitchName })) {
            throw "A switch with name '$ExternalSwitchName' was not found."
    }#>

    #endregion

    $machineName = $Configuration.MachineName
    $labName = $Configuration.LabName

    Write-Verbose -Message 'Starting creation of new lab-VM'

    #region delete existing VM

    # determine if deletion is needed and allowed
    Write-Verbose -Message "Checking existing lab-VM '$machineName'"

    $existingVM = !!(Get-VM | Where-Object { $_.Name -eq $machineName })
    if ($existingVM) {
        Write-Verbose -Message "Lab-VM '$machineName' already exists"
    }	
    else {
        Write-Verbose -Message "Lab-VM '$machineName' does not exist"
    }

    # if the machine already exists, ask for removal; or just remove when 'Force' is $true
    if ($existingVM) {
        if ($Force) {
            Write-Verbose -Message "Forcing delete of lab-VM '$machineName'"
        }
        elseif (!$Force -and $existingVM) {
            Write-Verbose -Message "Asking confirmation for delete of lab-VM '$machineName'"
            $forceAnswer = Read-Host -Prompt "A VM with name '$machineName' already exists; do you wish to remove it? [Y]es/[N]o/[A]ll "
            if ($forceAnswer -eq 'a' -or $forceAnswer -eq 'all') {
                break;
            }
            elseif ($forceAnswer -ne 'y' -and $forceAnswer -ne 'yes') {
                Write-Host -Object "Unable to create new machine '$machineName'" -BackgroundColor Red -ForegroundColor White
                return
            }
        }
    }

    # delete existing VM
    $existingVM = !!(Get-VM | Where-Object { $_.Name -eq $machineName })
    if ($existingVM) {
        Write-Verbose -Message "Removing old lab-VM '$machineName'"
        Remove-LabVM -Configuration $Configuration -RemoveFromDomain
    }

    #endregion

    #region create new VM

    # create new VM according to configuration
    Write-Verbose -Message "Creating lab-VM '$machineName'"

    # determine path
    $machinesPath = [System.IO.Path]::Combine($Configuration.LabPath, 'Machines')

    # find OS base-image
    $osDiskImagePath = [System.IO.Path]::Combine($Configuration.LabPath, 'Images', "$($Configuration.OperatingSystem.Name).vhdx")
    if (-not (Test-Path -Path $osDiskImagePath)) {
        $osDiskImagePath = [System.IO.Path]::Combine($Configuration.LabPath, '..', 'Images', "$($Configuration.OperatingSystem.Name).vhdx")
    }
    if (-not (Test-Path -Path $osDiskImagePath)) {
        $osDiskImagePath = [System.IO.Path]::Combine($Configuration.LabPath, '..', '..', 'Images', "$($Configuration.OperatingSystem.Name).vhdx")
    }
    if (-not (Test-Path -Path $osDiskImagePath)) {
        throw "Unable to locate operating-system image for '$($Configuration.OperatingSystem.Name)'"
    }

    Write-Verbose -Message 'Creating new lab-VM'

    Write-Verbose -Message '- creating new VM'
    # NOTE: Restart-Service Winmgmt, if New-VM fails due to 'Logon failure: the user has not been granted the requested logon type at this computer'
    $vm = New-VM -Name $machineName -Path $machinesPath -MemoryStartupBytes $Configuration.Hardware.StartupMemory -Generation 2 -ErrorAction Stop

    Write-Verbose -Message '- configuring processors'
    Set-VMProcessor -VM $vm -Count $Configuration.Hardware.ProcessorCount
    Write-Verbose -Message '- configuring memory'
    [bool]$dynamicMemoryEnabled = $Configuration.Hardware.MinimumMemory
    Set-VMMemory -VM $vm -DynamicMemoryEnabled $dynamicMemoryEnabled -MinimumBytes $Configuration.Hardware.MinimumMemory -MaximumBytes $Configuration.Hardware.MaximumMemory -StartupBytes $Configuration.Hardware.StartupMemory

    Write-Verbose -Message '- configuring snapshots and paging'
    $pathSnapshots = [System.IO.Path]::Combine($machinesPath, $vm.Name, 'Snapshots')
    $pathPaging = [System.IO.Path]::Combine($machinesPath, $vm.Name, 'Paging')
    Set-VM -VM  $vm -SnapshotFileLocation $pathSnapshots -SmartPagingFilePath $pathPaging

    Write-Verbose -Message '- adding OS disk'
    $pathHDDs = [System.IO.Path]::Combine($machinesPath, $vm.Name, 'Virtual Hard Disks')
    if(!(Test-Path -Path $pathHDDs)) {
        [System.IO.Directory]::CreateDirectory($pathHDDs) | Out-Null
    }
    $pathHDD_OS = [System.IO.Path]::Combine($pathHDDs, "$($vm.Name).vhdx")
    if($osDiskImagePath -and [System.IO.File]::Exists($osDiskImagePath)) {
        if ($Configuration.Hardware.DifferencingDisk) {
            Write-Verbose -Message '  - ensuring base-disk for differencing disk'
            $diskParentPath = [System.IO.Path]::Combine($machinesPath, '_BaseDisks', [System.IO.Path]::GetFileName($osDiskImagePath))
            if (-not(Test-Path -Path $diskParentPath)) {
                New-Item -Path ([System.IO.Path]::GetDirectoryName($diskParentPath)) -ErrorAction SilentlyContinue
                Copy-Item -Path $osDiskImagePath -Destination $diskParentPath
            }

            Write-Verbose -Message '  - creating differencing disk'
            New-VHD -Path $pathHDD_OS -ParentPath $diskParentPath -Differencing | Out-Null
        }
        else {
            Write-Verbose -Message '  - copying image'
            Copy-Item -Path $osDiskImagePath -Destination $pathHDD_OS
        }

        Write-Verbose -Message '  - adding disk'
        Add-VMHardDiskDrive -VM $vm -ControllerType SCSI -ControllerNumber 0 -ControllerLocation 0 -Path $pathHDD_OS
    }

    if ($Configuration.Disks -and $Configuration.Disks.Length) {
        Write-Verbose -Message '- adding extra disk(s)'
        $index = 0
        foreach ($disk in $Configuration.Disks) {
            ++$index
            $pathData = [System.IO.Path]::Combine($pathHDDs, "$($vm.Name)_$index.vhdx")
            if ($disk.ExtraDiskImage) {
                # find disk-image
                $extraDiskImagePath = [System.IO.Path]::Combine($Configuration.LabPath, 'Images', "$($disk.ExtraDiskImage).vhdx")
                if (-not (Test-Path -Path $extraDiskImagePath)) {
                    $extraDiskImagePath = [System.IO.Path]::Combine($Configuration.LabPath, '..', 'Images', "$($disk.ExtraDiskImage).vhdx")
                }
                if (-not (Test-Path -Path $extraDiskImagePath)) {
                    $extraDiskImagePath = [System.IO.Path]::Combine($Configuration.LabPath, '..', '..', 'Images', "$($disk.ExtraDiskImage).vhdx")
                }
                if (-not (Test-Path -Path $extraDiskImagePath)) {
                    throw "Unable to locate disk image for '$($disk.ExtraDiskImage)'"
                }

                Write-Verbose -Message '  - copying image'
                Copy-Item -Path $extraDiskImagePath -Destination $pathData
            }
            elseif ($disk.ExtraDiskSize) {
                Write-Verbose -Message '- creating new disk'
                New-VHD -Path $pathData –SizeBytes $disk.ExtraDiskSize | Out-Null
            }

            if ($pathData) {
                Write-Verbose -Message '  - adding disk...'
                Add-VMHardDiskDrive -VM $vm -ControllerType SCSI -ControllerNumber 0 -ControllerLocation $index -Path $pathData
            }
        }
    }

    Write-Verbose -Message '- configuring network'
    Get-VMNetworkAdapter -VM $vm | Remove-VMNetworkAdapter
    foreach($networkAdapter in $Configuration.NetworkAdapters) {
        if ($networkAdapter.Enabled) {
            Add-VMNetworkAdapter -VM $vm -Name $networkAdapter.Name -SwitchName $networkAdapter.SwitchName
            Set-VMNetworkAdapter -VM $vm -Name $networkAdapter.Name -DeviceNaming On
            if ($Configuration.StaticMacAddress) {
                Set-VMNetworkAdapter -VM $vm -Name $networkAdapter.Name -StaticMacAddress $Configuration.StaticMacAddress
            }
        }
    }

    Write-Verbose -Message '- fixing boot-order to OS-disk'
    Update-BootOrder -VM $vm -BootDrivePath $pathHDD_OS

    $unattendContent = Get-Content -Path "$PSScriptRoot\..\Files\unattend.xml"
    $unattendContent = $unattendContent -replace '{ComputerName}',$machineName
    $timeZone = $Configuration.OperatingSystem.TimeZone
    if (-not $timeZone) {
        $timeZone = 'W. Europe Standard Time'
    }
    $unattendContent = $unattendContent -replace '{TimeZone}',$timeZone

    if ($Configuration.AdministratorPassword) {
        $administratorPassword = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes("$($Configuration.AdministratorPassword)AdministratorPassword"))
    }
    $unattendContent = $unattendContent -replace '{AdministratorPassword}',$administratorPassword

    Write-Verbose -Message 'Inserting files into virtual harddisk'
    $configurationContent = (ConvertTo-Json -InputObject $Configuration -Depth 9)

    $filesToCopy = @(
        @{
            Content = $unattendContent
            Destination = 'unattend.xml'
        }
        @{
            Content = 'powershell -File C:\Setup\SetupComplete.ps1 -ExecutionPolicy Unrestricted > C:\Setup\SetupComplete.txt'
            Destination = 'Windows\Setup\Scripts\SetupComplete.cmd'
        }
        @{
            Content = $configurationContent
            Destination = 'Setup\configuration.json'
        }
        @{
            Source = "$PSScriptRoot\..\Files\ProviderAssemblies\*"
            Destination = 'Program Files\PackageManagement\ProviderAssemblies'
        }
        @{
            Source = "$PSScriptRoot\..\Files\Setup\*"
            Destination = 'Setup'
        }
        # files for all labs
        @{
            Source = "$($machineConfig.LabPath)\..\..\Files\Setup\*"
            Destination = 'Setup'
        }
        @{
            Source = "$($machineConfig.LabPath)\..\..\Files\Modules\*"
            Destination = 'Program Files\WindowsPowerShell\Modules'
        }
        # files for the current lab
        @{
            Source = "$($machineConfig.LabPath)\Files\Setup\*"
            Destination = 'Setup'
        }
        @{
            Source = "$($machineConfig.LabPath)\Files\Modules\*"
            Destination = 'Program Files\WindowsPowerShell\Modules'
        }
    )

    Add-FilesIntoVirtualHardDisk -Name $machineName -FilesToCopy $filesToCopy -ErrorAction Stop

    Update-HostShares -Configuration $Configuration

    #endregion

    if ($Start) {
        Write-Verbose -Message "Starting lab-VM '$machineName'"
        Start-VM -Name $machineName

        if ($Connect) {
            Write-Verbose -Message "Connecting to lab-VM '$machineName'"
            Connect-LabVM -Name $machineName
        }
    }

	Write-Verbose -Message "Finished creating lab-VM '$machineName'."
}

