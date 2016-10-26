#Requires -Version 5.0

function Convert-FromJsonObject {
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
            $environment.Hardware = $InputObject.Hardware |% { Convert-FromJsonObject -InputObject $_ -TypeName 'LabHardware' -ParentObject $environment }
            $environment.OperatingSystems = $InputObject.OperatingSystems |% { Convert-FromJsonObject -InputObject $_ -TypeName 'LabOperationSystem' -ParentObject $environment }
            $environment.Domains = $InputObject.Domains |% { Convert-FromJsonObject -InputObject $_ -TypeName 'LabDomain' -ParentObject $environment }
            $environment.Networks = $InputObject.Networks |% { Convert-FromJsonObject -InputObject $_ -TypeName 'LabNetwork' -RootObject $environment -ParentObject $environment }
            $environment.Machines = $InputObject.Machines |% { Convert-FromJsonObject -InputObject $_ -TypeName 'LabMachine' -RootObject $environment -ParentObject $environment }
            
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
                DriveLetter = $InputObject.DriveLetter
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
                catch { }
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
                NetbiosName = $InputObject.Name
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
                catch { }
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
            $network.Domain = ($RootObject.Domains |? { $_.Name -eq $InputObject.Domain } | Select -First 1)
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
                catch { }
            }

            $machine.AllProperties = New-Object Hashtable
            if ($RootObject) {
                foreach ($propertyKey in $RootObject.Properties.Keys) {
                    $machine.AllProperties[$propertyKey] = $RootObject.Properties.$propertyKey
                }
            }
            foreach ($propertyKey in $machine.Properties.Keys) {
                $machine.AllProperties[$propertyKey] = $machine.Properties.$propertyKey
            }
            #if ($RootObject -and $RootObject.Properties) {
            #    $RootObject.Properties.Keys |% { "$_: $($RootObject.Properties.$_)" }
            #    $machine.AllProperties = Convert-PSObjectToHashtable -InputObject $InputObject.Properties
            #}
            $machine.Hardware = ($RootObject.Hardware |? { $_.Name -eq $InputObject.Hardware } | Select -First 1)
            $machine.Disks = ($InputObject.Disks |% { Convert-FromJsonObject -InputObject $_ -TypeName 'LabDisk' -RootObject $RootObject })
            $machine.NetworkAdapters = ($InputObject.NetworkAdapters |% { Convert-FromJsonObject -InputObject $_ -TypeName 'LabNetworkAdapter' -RootObject $RootObject })
            return $machine
        }
        'LabDisk' {
            $disk = New-Object LabDisk -Property @{
                DriveLetter = $(if ($InputObject.OperatingSystem) { 'C' } else { $InputObject.DriveLetter })
                Size = $(if ($InputObject.Size) { Invoke-expression -Command $InputObject.Size })
                DifferencingDisk = $InputObject.DifferencingDisk
                UseEnvironmentCopy = $InputObject.UseEnvironmentCopy
            }
            $disk.OperatingSystem = ($RootObject.OperatingSystems |? { $_.Name -eq $InputObject.OperatingSystem } | Select -First 1)
            return $disk
        }
        'LabNetworkAdapter' {
            $networkAdapter = New-Object LabNetworkAdapter -Property @{
                StaticMacAddress = $InputObject.StaticMacAddress
                StaticIPAddress = $InputObject.StaticIPAddress
            }
            $networkAdapter.Network = ($RootObject.Networks |? { $_.Name -eq $InputObject.Network } | Select -First 1)
            return $networkAdapter
        }
    }
}
