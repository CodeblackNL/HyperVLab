#Requires -Version 5.0

function New-LabVM {
    [CmdletBinding(DefaultParameterSetName = 'MachineName')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Machine', ValueFromPipeline = $true)]
        [LabMachine[]]$Machine,
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'MachineName')]
        [string[]]$MachineName,
        [Parameter(Mandatory = $true, ParameterSetName = 'Environment', ValueFromPipeline = $true)]
        [LabEnvironment[]]$Environment,
        [Parameter(Mandatory = $false)]
        [Switch]$Force = $false,
        [Parameter(Mandatory = $false)]
        [Switch]$Start = $false
    )

    Begin {
        if (-not (Test-Administrator)) {
            throw 'Please run this command as Administrator.'
        }
    }

    Process {
        if ($($PSCmdlet.ParameterSetName) -eq 'MachineName') {
            if ($MachineName) {
                $Machine = Get-LabMachine -Name $MachineName
            }
            else {
                $Machine = Get-LabMachine
            }
        }
        elseif ($($PSCmdlet.ParameterSetName) -eq 'Environment') {
            $Machine = Get-LabMachine -Environment $Environment
        }

        if (-not $Machine) {
            return
        }

        #region Validation

        foreach ($m in $Machine) {
            if (-not $m.Name) {
                throw 'Please provide Name for each machine.'
            }

            # if dynamic memory is to be used, both minimum & maximum must be provided
            if ((!$m.Hardware.MinimumMemory -and $m.Hardware.MaximumMemory) -or ($m.Hardware.MinimumMemory -and !$m.Hardware.MaximumMemory)) {
                throw "Invalid Dynamic Memory for machine '$($m.Name)'"
            }

            # TODO: improve validate of the machine-configuration

            <#if ($InternalSwitchName -and !(Get-VMSwitch | Where { $_.Name -eq $InternalSwitchName })) {
                    throw "A switch with name '$InternalSwitchName' was not found."
                    }
                    if ($ExternalSwitchName -and !(Get-VMSwitch | Where { $_.Name -eq $ExternalSwitchName })) {
                    throw "A switch with name '$ExternalSwitchName' was not found."
            }#>
        }

        #endregion

        #region delete existing VM

        Remove-LabVM -Machine $Machine -Force:$Force #-RemoveFromDomain

        #endregion

        foreach ($m in $Machine) {
            Write-Verbose -Message 'Starting creation of new lab-VM'
            $labName = $m.Environment.Name
            $labPath = Split-Path -Path $m.Environment.Path -Parent

            # create new VM according to configuration
            Write-Verbose -Message "Creating lab-VM '$($m.Name)'"

            # determine path
            if ($m.Environment.MachinesPath) {
                $machinesPath = $m.Environment.MachinesPath
                if ($machinesPath.StartsWith('.')) {
                    $machinesPath = [System.IO.Path]::GetFullPath((Join-Path -Path $labPath -ChildPath $machinesPath))
                }
            }
            else {
                $machinesPath = [System.IO.Path]::Combine($labPath, 'Machines')
            }

            Write-Verbose -Message '- creating new VM'
            try {
                $vm = New-VM -Name $m.Name -Path $machinesPath -MemoryStartupBytes $m.Hardware.StartupMemory -Generation 2 -ErrorAction Stop
            }
            catch {
                Write-Warning "if New-VM fails due to 'Logon failure: the user has not been granted the requested logon type at this computer'"
                Write-Warning "execute 'Restart-Service Winmgmt -Force', and retry"
            }

            Write-Verbose -Message '- configuring processors'
            Set-VMProcessor -VM $vm -Count $m.Hardware.ProcessorCount
            Write-Verbose -Message '- configuring memory'
            [bool]$dynamicMemoryEnabled = $m.Hardware.MinimumMemory
            Set-VMMemory -VM $vm -DynamicMemoryEnabled $dynamicMemoryEnabled -MinimumBytes $m.Hardware.MinimumMemory -MaximumBytes $m.Hardware.MaximumMemory -StartupBytes $m.Hardware.StartupMemory

            Write-Verbose -Message '- configuring snapshots and paging'
            $pathSnapshots = [System.IO.Path]::Combine($machinesPath, $vm.Name, 'Snapshots')
            $pathPaging = [System.IO.Path]::Combine($machinesPath, $vm.Name, 'Paging')
            Set-VM -VM  $vm -SnapshotFileLocation $pathSnapshots -SmartPagingFilePath $pathPaging

            if ($m.Disks -and @($m.Disks).Length) {
                Write-Verbose -Message '- adding disk(s)'
                $pathHDDs = [System.IO.Path]::Combine($machinesPath, $vm.Name, 'Virtual Hard Disks')
                if(!(Test-Path -Path $pathHDDs)) {
                    [System.IO.Directory]::CreateDirectory($pathHDDs) | Out-Null
                }
                $index = 0
                foreach ($disk in $m.Disks) {
                    $diskPath = $null
                    if ($disk.OperatingSystem) {
                        if ($disk.OperatingSystem.FilePath.StartsWith('.')) {
                            $osPath = [System.IO.Path]::GetFullPath((Join-Path -Path $labPath -ChildPath $disk.OperatingSystem.FilePath))
                        }
                        else {
                            $osPath = $disk.OperatingSystem.FilePath
                        }
                        $diskPath = [System.IO.Path]::Combine($pathHDDs, "$($vm.Name).vhdx")
                        Write-Verbose -Message "  - creating OS disk at '$diskPath' from '$($osPath)'"
                        if ($disk.DifferencingDisk) {
                            if ($disk.UseEnvironmentCopy) {
                                $diskParentPath = [System.IO.Path]::Combine($machinesPath, '_BaseDisks', [System.IO.Path]::GetFileName($osPath))
                                Write-Verbose -Message "    - ensuring base-disk for differencing disk ($diskParentPath)"
                                if (-not (Test-Path -Path $diskParentPath)) {
                                    New-Item -Path ([System.IO.Path]::GetDirectoryName($diskParentPath)) -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
                                    Copy-Item -Path $osPath -Destination $diskParentPath
                                }
                            }
                            else {
                                $diskParentPath = $osPath
                            }

                            Write-Verbose -Message '    - creating differencing disk'
                            New-VHD -Path $diskPath -ParentPath $diskParentPath -Differencing | Out-Null
                        }
                        else {
                            Write-Verbose -Message '    - copying disk'
                            Copy-Item -Path $osPath -Destination $diskPath
                        }
                    }
                    elseif ($disk.Size) {
                        $diskPath = [System.IO.Path]::Combine($pathHDDs, "$($vm.Name)_$index.vhdx")
                        Write-Verbose -Message "  - creating new disk with size '$($disk.Size / 1GB)GB' at '$diskPath'"
                        New-VHD -Path $diskPath –SizeBytes $disk.Size | Out-Null
                    }

                    if ($diskPath) {
                        Write-Verbose -Message "    - adding disk ($index)"
                        Add-VMHardDiskDrive -VM $vm -ControllerType SCSI -ControllerNumber 0 -ControllerLocation $index -Path $diskPath
                    }
                    $index++
                }
            }

            if ($m.NetworkAdapters -and @($m.NetworkAdapters).Length) {
                Write-Verbose -Message '- configuring network'
                Get-VMNetworkAdapter -VM $vm | Remove-VMNetworkAdapter
                foreach($networkAdapter in $m.NetworkAdapters) {
                    if ($networkAdapter.Enabled -eq $null -or $networkAdapter.Enabled) {
                        $network = $networkAdapter.Network
                        # ensure VM-Switch exists, with correct settings
                        $switch = Get-VMSwitch -Name $network.SwitchName -ErrorAction SilentlyContinue
                        if ($switch) {
                            if ($network.SwitchType -eq 'External') {
                                $netAdapter = Get-NetAdapter -InterfaceDescription $switch.NetAdapterInterfaceDescription
                                if ($switch.SwitchType -ne $network.SwitchType -or $netAdapter.Name -ne $network.SwitchNetAdapterName) {
                                    Set-VMSwitch -Name $network.SwitchName -NetAdapterName $network.SwitchNetAdapterName
                                }
                            }
                            elseif ($switch.SwitchType -ne $network.SwitchType) {
                                Set-VMSwitch -Name $network.SwitchName -SwitchType $network.SwitchType
                            }
                        }
                        else {
                            if ($network.SwitchType -eq 'External') {
                                $switch = New-VMSwitch -Name $network.SwitchName -NetAdapterName $network.SwitchNetAdapterName
                            }
                            else {
                                $switch = New-VMSwitch -Name $network.SwitchName -SwitchType $network.SwitchType
                            }
                        }
                        if ($network.HostIPAddress) {
                            $interfaceAlias = "vEthernet ($($network.SwitchName))"
                            $netIPAddress = Get-NetAdapter $interfaceAlias | Get-NetIPAddress -AddressFamily IPv4 -IPAddress $network.HostIPAddress -ErrorAction SilentlyContinue
                            if (-not $netIPAddress) {
                                New-NetIPAddress –InterfaceAlias $interfaceAlias –IPAddress $network.HostIPAddress –PrefixLength $network.PrefixLength
                            }
                            elseif ($netIPAddress.PrefixLength -ne $network.PrefixLength) {
                                Set-NetIPAddress –InterfaceAlias $interfaceAlias -PrefixLength $network.PrefixLength
                            }
                        }

                        Write-Verbose -Message "  - adding network '$($network.Name)'"
                        Add-VMNetworkAdapter -VM $vm -Name $network.Name -SwitchName $network.SwitchName
                        Set-VMNetworkAdapter -VM $vm -Name $network.Name -DeviceNaming On
                        if ($networkAdapter.StaticMacAddress) {
                            Set-VMNetworkAdapter -VM $vm -Name $network.Name -StaticMacAddress ($networkAdapter.StaticMacAddress).Replace('-', '')
                        }
                    }
                    else {
                        Write-Verbose -Message "  - skipping network '$($networkAdapter.Network.Name)'"
                    }
                }
            }

            $pathOSDisk = (Get-VMHardDiskDrive -VM $vm |? { [System.IO.Path]::GetFileNameWithoutExtension($_.Path) -eq $m.Name } | Sort ControllerNumber,ControllerLocation | Select -First 1).Path
            if ($pathOSDisk) {
                Write-Verbose -Message '- fixing boot-order to OS-disk'
                Update-BootOrder -VM $vm -BootDrivePath $pathOSDisk
            }

            $operatingSystem = ($m.Disks |? { $_.OperatingSystem } | Sort DriveLetter).OperatingSystem
            $unattendTemplateFilePath = $operatingSystem.UnattendFilePath
            if ($unattendTemplateFilePath) {
                Write-Verbose -Message '- generating unattend file'
                if ($unattendTemplateFilePath.StartsWith('.')) {
                    $unattendTemplateFilePath = [System.IO.Path]::GetFullPath((Join-Path -Path $labPath -ChildPath $unattendTemplateFilePath))
                }
                $administratorPassword = $null
                if ($m.AdministratorPassword) {
                    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($m.AdministratorPassword)
                    $plain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
                    $administratorPassword = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes("$($plain)AdministratorPassword"))
                }
                $unattendContent = New-UnattendXml -TemplateFilePath $unattendTemplateFilePath -Property @{
                    ComputerName = $m.Name
                    ProductKey = $operatingSystem.ProductKey
                    TimeZone = $m.TimeZone
                    AdministratorPassword = $administratorPassword
                }
            }

            Write-Verbose -Message '- inserting files into virtual harddisk'
            $configurationContent = (ConvertTo-Json -InputObject $m.ToMachineConfiguration() -Depth 9)

            $filesToCopy = @(
                @{
                    Content = $unattendContent
                    Destination = 'unattend.xml'
                }
                @{
                    Content = $configurationContent
                    Destination = 'Setup\configuration.json'
                }
                @{
                    Source = "$PSScriptRoot\..\..\Files\*"
                    Destination = ''
                }
            )
            if ($m.Environment.FilesPath) {
                if ($m.Environment.FilesPath.StartsWith('.')) {
                    $filesPath = [System.IO.Path]::GetFullPath((Join-Path -Path $labPath -ChildPath $m.Environment.FilesPath))
                }
                else {
                    $filesPath = $m.Environment.FilesPath
                }
                
                $filesToCopy += @{
                    Source = "$filesPath\*"
                    Destination = ''
                }
            }
            if ($m.FilesPath) {
                if ($m.FilesPath.StartsWith('.')) {
                    $filesPath = [System.IO.Path]::GetFullPath((Join-Path -Path $labPath -ChildPath $m.FilesPath))
                }
                else {
                    $filesPath = $m.FilesPath
                }
                
                $filesToCopy += @{
                    Source = "$filesPath\*"
                    Destination = ''
                }
            }

            Add-FilesIntoVirtualHardDisk -Path $pathOSDisk -FilesToCopy $filesToCopy -ErrorAction Stop

            if ($Start) {
                Write-Verbose -Message "Starting lab-VM '$($m.Name)'"
                Start-VM -Name $m.Name
            }
        }

        $environments = $Machine.Environment | Select -Unique
        if ($environments) {
            foreach ($e in $environments) {
                if ($e.Host -and $e.Host.Share) {
                    Update-LabHostShare -Environment $e
                }
            }
        }

	    Write-Verbose -Message "Finished creating lab-VM '$($m.Name)'."
    }
}

