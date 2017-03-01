#Requires -Version 5.0

function Convert-FromJsonObject {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'Don''t use ShouldProcess in internal functions.')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingInvokeExpression', '', Justification = 'Invoke-Expression is used to convert GB-notation to an integer-value.')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'The passwords are coming from a file; conversion is necessary.')]
    param (
        [PSCustomObject]$InputObject,
        [string]$TypeName,
        $RootObject,
        $ParentObject
    )

    if (-not $InputObject) {
        return
    }

    switch ($TypeName) {
        'LabEnvironment' {
            $environment = New-Object LabEnvironment -Property @{
                Name = $InputObject.Name
                Path = $InputObject.Path
                MachinesPath = $InputObject.MachinesPath
                FilesPath = $InputObject.FilesPath
                ConfigurationFilePath = $InputObject.ConfigurationFilePath
                ConfigurationName = $InputObject.ConfigurationName
                CertificateFilePath = $InputObject.CertificateFilePath
                CertificateThumbprint = $InputObject.CertificateThumbprint
                Properties = Convert-PSObjectToHashtable -InputObject $InputObject.Properties
            }
            if ($InputObject.Host) {
                $environment.Host = Convert-FromJsonObject -InputObject $InputObject.Host -TypeName 'LabHost'
            }
            $environment.Hardware = $InputObject.Hardware | ForEach-Object { Convert-FromJsonObject -InputObject $_ -TypeName 'LabHardware' -ParentObject $environment }
            $environment.OperatingSystems = $InputObject.OperatingSystems | ForEach-Object { Convert-FromJsonObject -InputObject $_ -TypeName 'LabOperationSystem' -ParentObject $environment }
            $environment.Domains = $InputObject.Domains | ForEach-Object { Convert-FromJsonObject -InputObject $_ -TypeName 'LabDomain' -ParentObject $environment }
            $environment.Networks = $InputObject.Networks | ForEach-Object { Convert-FromJsonObject -InputObject $_ -TypeName 'LabNetwork' -RootObject $environment -ParentObject $environment }
            $environment.Machines = $InputObject.Machines | ForEach-Object { Convert-FromJsonObject -InputObject $_ -TypeName 'LabMachine' -RootObject $environment -ParentObject $environment }
            
            return $environment
        }
        'LabHost' {
            $host = New-Object LabHost -Property @{
                Name = $InputObject.Name
            }
            if ($InputObject.Share) {
                $host.Share = Convert-FromJsonObject -InputObject $InputObject.Share -TypeName 'LabHostShare'
            }
            return $host
        }
        'LabHostShare' {
            $hostShare = New-Object LabHostShare -Property @{
                Name = $InputObject.Name
                Path = $InputObject.Path
                UserName = $InputObject.UserName
            }
            if ($InputObject.Password) {
                try {
                    if ($InputObject.PasswordType -eq 'PlainText') {
                        $hostShare.Password = ConvertTo-SecureString -String $InputObject.Password -AsPlainText -Force
                    }
                    else {
                        $hostShare.Password = $InputObject.Password | ConvertTo-SecureString -ErrorAction SilentlyContinue
                    }
                }
                catch {
                    Write-Warning -Message "Error reading the host-share password."
                }
            }
            return $hostShare
        }
        'LabOperationSystem' {
            return New-Object LabOperationSystem -Property @{
                Name = $InputObject.Name
                FilePath = $InputObject.FilePath
                UnattendFilePath = $InputObject.UnattendFilePath
                ProductKey = $InputObject.ProductKey
                Environment = $ParentObject
            }
        }
        'LabDomain' {
            $domain = New-Object LabDomain -Property @{
                Name = $InputObject.Name
                NetbiosName = $InputObject.NetbiosName
                Environment = $ParentObject
            }
            if ($InputObject.AdministratorPassword) {
                try {
                    if ($InputObject.AdministratorPasswordType -eq 'PlainText') {
                        $domain.AdministratorPassword = ConvertTo-SecureString -String $InputObject.AdministratorPassword -AsPlainText -Force
                    }
                    else {
                        $domain.AdministratorPassword = $InputObject.AdministratorPassword | ConvertTo-SecureString -ErrorAction SilentlyContinue
                    }
                }
                catch {
                    Write-Warning -Message "Error reading the domain administrator password."
                }
            }
            return $domain
        }
        'LabDnsServer' {
            $dnsServer = New-Object LabDnsServer -Property @{
                IPAddress = $InputObject.IPAddress
            }
            return $dnsServer
        }
        'LabDhcpServer' {
            $dhcpServer = New-Object LabDhcpServer -Property @{
                IPAddress = $InputObject.IPAddress
                ScopeName = $InputObject.ScopeName
                ScopeId = $InputObject.ScopeId
                StartRange = $InputObject.StartRange
                EndRange = $InputObject.EndRange
                SubnetMask = $InputObject.SubnetMask
                LeaseDurationDays = $InputObject.LeaseDurationDays
                DefaultGateway = $InputObject.DefaultGateway
            }
            return $dhcpServer
        }
        'LabHardware' {
            $hardware = New-Object LabHardware -Property @{
                Name = $InputObject.Name
                ProcessorCount = $InputObject.ProcessorCount
                Environment = $ParentObject
            }
            if ($InputObject.StartupMemory) {
                $hardware.StartupMemory = Invoke-expression -Command $InputObject.StartupMemory
            }
            if ($InputObject.StartupMemory) {
                $hardware.MinimumMemory = Invoke-expression -Command $InputObject.MinimumMemory
            }
            if ($InputObject.StartupMemory) {
                $hardware.MaximumMemory = Invoke-expression -Command $InputObject.MaximumMemory
            }
            return $hardware
        }
        'LabNetwork' {
            $network = New-Object LabNetwork -Property @{
                Name = $InputObject.Name
                SwitchName = $InputObject.SwitchName
                SwitchType = $InputObject.SwitchType
                SwitchNetAdapterName = $InputObject.SwitchNetAdapterName
                AddressFamily = $InputObject.AddressFamily
                PrefixLength = $InputObject.PrefixLength
                HostIPAddress = $InputObject.HostIPAddress
                Environment = $ParentObject
            }
            $network.Domain = ($RootObject.Domains | Where-Object { $_.Name -eq $InputObject.Domain } | Select-Object -First 1)
            if ($InputObject.DnsServer) {
                $network.DnsServer = Convert-FromJsonObject -InputObject $InputObject.DnsServer -TypeName 'LabDnsServer'
            }
            if ($InputObject.DhcpServer) {
                $network.DhcpServer = Convert-FromJsonObject -InputObject $InputObject.DhcpServer -TypeName 'LabDhcpServer'
            }
            return $network
        }
        'LabMachine' {
            $machine = New-Object LabMachine -Property @{
                Name = $InputObject.Name
                TimeZone = $InputObject.TimeZone
                Role = $InputObject.Role
                FilesPath = $InputObject.FilesPath
                Properties = Convert-PSObjectToHashtable -InputObject $InputObject.Properties
                Environment = $ParentObject
            }
            if ($InputObject.AdministratorPassword) {
                try {
                    if ($InputObject.AdministratorPasswordType -eq 'PlainText') {
                        $machine.AdministratorPassword = ConvertTo-SecureString -String $InputObject.AdministratorPassword -AsPlainText -Force
                    }
                    else {
                        $machine.AdministratorPassword = $InputObject.AdministratorPassword | ConvertTo-SecureString -ErrorAction SilentlyContinue
                    }
                }
                catch {
                    Write-Warning -Message "Error reading the machine administrator password."
                }
            }

            $machine.AllProperties = @{}
            if ($RootObject) {
                foreach ($propertyKey in $RootObject.Properties.Keys) {
                    $machine.AllProperties[$propertyKey] = $RootObject.Properties.$propertyKey
                }
            }
            foreach ($propertyKey in $machine.Properties.Keys) {
                $machine.AllProperties[$propertyKey] = $machine.Properties.$propertyKey
            }
            $machine.Hardware = ($RootObject.Hardware | Where-Object { $_.Name -eq $InputObject.Hardware } | Select-Object -First 1)
            $machine.Disks = ($InputObject.Disks | ForEach-Object { Convert-FromJsonObject -InputObject $_ -TypeName 'LabDisk' -RootObject $RootObject })
            $machine.NetworkAdapters = ($InputObject.NetworkAdapters | ForEach-Object { Convert-FromJsonObject -InputObject $_ -TypeName 'LabNetworkAdapter' -RootObject $RootObject })
            return $machine
        }
        'LabDisk' {
            $disk = New-Object LabDisk -Property @{
                DifferencingDisk = $InputObject.DifferencingDisk
                UseEnvironmentCopy = $InputObject.UseEnvironmentCopy
                Size = $(if ($InputObject.Size) { Invoke-expression -Command $InputObject.Size })
                Shared = $InputObject.Shared
                ImageFilePath = $InputObject.ImageFilePath
            }

            $disk.OperatingSystem = ($RootObject.OperatingSystems | Where-Object { $_.Name -eq $InputObject.OperatingSystem } | Select-Object -First 1)

            [LabDiskType]$type = [LabDiskType]::HardDisk
            if (-not [LabDiskType]::TryParse($InputObject.Type, [ref]$type)) {
                if ($disk.OperatingSystem) {
                    $type = [LabDiskType]::OperatingSystem
                }
                elseif ($disk.ImageFilePath) {
                    $type = [LabDiskType]::DVDDrive
                }
                else {
                    $type = [LabDiskType]::HardDisk
                }
            }
            $disk.Type = $type

            return $disk
        }
        'LabNetworkAdapter' {
            $networkAdapter = New-Object LabNetworkAdapter -Property @{
                StaticMacAddress = $InputObject.StaticMacAddress
                StaticIPAddress = $InputObject.StaticIPAddress
                DefaultGateway = $InputObject.DefaultGateway
            }
            $networkAdapter.Network = ($RootObject.Networks | Where-Object { $_.Name -eq $InputObject.Network } | Select-Object -First 1)
            return $networkAdapter
        }
    }
}
