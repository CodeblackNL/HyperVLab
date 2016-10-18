class LabOperationSystem {
    [string]$Name
    [string]$FilePath
    [string]$UnattendFilePath
    [string]$ProductKey
    [LabEnvironment]$Environment

    [string] ToString()
    {
        return $this.Name
    }

    [LabOperationSystem] ToMachineConfiguration() {
        return New-Object LabOperationSystem -Property @{
            Name = $this.Name
            FilePath = $this.FilePath
            UnattendFilePath = $this.UnattendFilePath
            #ProductKey = $this.ProductKey
        }
    }
}

class LabHardware {
    [string]$Name
    [int]$ProcessorCount
    [long]$StartupMemory
    [long]$MinimumMemory
    [long]$MaximumMemory
    [LabEnvironment]$Environment

    [string] ToString() {
        return $this.Name
    }

    [LabHardware] ToMachineConfiguration() {
        return New-Object LabHardware -Property @{
            Name = $this.Name
            ProcessorCount = $this.ProcessorCount
            StartupMemory = $this.StartupMemory
            MinimumMemory = $this.MinimumMemory
            MaximumMemory = $this.MaximumMemory
        }
    }
}

class LabDomain {
    [string]$Name
    [string]$NetbiosName
    [SecureString]$AdministratorPassword
    [LabEnvironment]$Environment

    [string] ToString() {
        return $this.Name
    }

    [LabDomain] ToMachineConfiguration() {
        return New-Object LabDomain -Property @{
            Name = $this.Name
            NetbiosName = $this.NetbiosName
            #AdministratorPassword = $this.AdministratorPassword
        }
    }
}

class LabDnsServer {
    [string]$IPAddress

    [string] ToString() {
        return $this.IPAddress
    }
}

class LabDhcpServer {
    [string]$IPAddress
    [string]$ScopeName
    [string]$ScopeId
    [string]$StartRange
    [string]$EndRange
    [string]$SubnetMask
    [int]$LeaseDurationDays
    [string]$DefaultGateway

    [string] ToString() {
        return $this.IPAddress
    }
}

class LabNetwork {
    [string]$Name
    [string]$SwitchName
    [string]$SwitchType                # Internal, External
    [string]$SwitchNetAdapterName
    [string]$AddressFamily             # IPV4
    [int]$PrefixLength
    [string]$HostIPAddress
    [LabDomain]$Domain
    [LabDnsServer]$DnsServer
    [LabDhcpServer]$DhcpServer
    [LabEnvironment]$Environment

    [string] ToString() {
        return $this.Name
    }

    [LabNetwork] ToMachineConfiguration() {
        $network = New-Object LabNetwork -Property @{
            Name = $this.Name
            SwitchName = $this.SwitchName
            SwitchType = $this.SwitchType
            SwitchNetAdapterName = $this.SwitchNetAdapterName
            AddressFamily = $this.AddressFamily
            PrefixLength = $this.PrefixLength
            HostIPAddress = $this.HostIPAddress
        }
        if ($this.Domain) {
            $network.Domain = $this.Domain.ToMachineConfiguration()
        }
        $network.DnsServer = $this.DnsServer
        $network.DhcpServer = $this.DhcpServer

        return $network
    }
}

class LabNetworkAdapter {
    [LabNetwork]$Network
    [string]$StaticMacAddress
    [string]$StaticIPAddress

    [LabNetworkAdapter] ToMachineConfiguration() {
        return New-Object LabNetworkAdapter -Property @{
            Network = $this.Network.ToMachineConfiguration()
            StaticMacAddress = $this.StaticMacAddress
            StaticIPAddress = $this.StaticIPAddress
        }
    }
}

class LabDisk {
    [string]$DriveLetter                       # optional; always replaced with 'C' if OperatingSystem is provided
    [LabOperationSystem]$OperatingSystem       # optional
    [bool]$DifferencingDisk                    # optional; only valid if OperatingSystem is provided, otherwise ignored
    [long]$Size                                # mandatory if OperatingSystem not provided, otherwise ignored

    [LabDisk] ToMachineConfiguration() {
        $disk = New-Object LabDisk -Property @{
            DriveLetter = $this.DriveLetter
            DifferencingDisk = $this.DifferencingDisk
            Size = $this.Size
        }
        if ($this.OperatingSystem) {
            $disk.OperatingSystem = $this.OperatingSystem.ToMachineConfiguration()
        }

        return $disk
    }
}

class LabMachine {
    [string]$Name
    [SecureString]$AdministratorPassword
    [string]$TimeZone
    [string[]]$Role
    [string]$FilesPath
    [Hashtable]$Properties
    [Hashtable]$AllProperties
    [LabHardware]$Hardware
    [LabDisk[]]$Disks
    [LabNetworkAdapter[]]$NetworkAdapters
    [LabEnvironment]$Environment

    [string] ToString() {
        return $this.Name
    }

    [LabMachine] ToMachineConfiguration() {
        $machine = New-Object LabMachine -Property @{
            Name = $this.Name
            #AdministratorPassword = $this.AdministratorPassword
            TimeZone = $this.TimeZone
            Role = $this.Role
            Hardware = $this.Hardware.ToMachineConfiguration()
        }
        if ($this.Environment) {
            $machine.Environment = $this.Environment.ToMachineConfiguration()
        }
        if ($this.Role) {
            $machine.Role = @($this.Role)
        }
        if ($this.Disks) {
            $machine.Disks = @($this.Disks |% { $_.ToMachineConfiguration() })
        }
        if ($this.NetworkAdapters) {
            $machine.NetworkAdapters = @($this.NetworkAdapters |% { $_.ToMachineConfiguration() })
        }

        return $machine
    }
}

#class LabMachineTemplate : LabMachine {
#}

class LabHostShare {
    [string]$Name
    [string]$Path
    [string]$DriveLetter
    [string]$UserName
    [SecureString]$Password

    [string] ToString() {
        return $this.Name
    }
}

class LabHost {
    [string]$Name
    [LabHostShare]$Share

    [string] ToString() {
        return $this.Name
    }
}

class LabEnvironment {
    [string]$Name
    [string]$Path
    [string]$FilesPath
    [string]$ConfigurationFilePath
    [string]$ConfigurationName
    [string]$CertificateFilePath
    [string]$CertificateThumbprint
    [Hashtable]$Properties
    [LabHost]$Host
    [LabHardware[]]$Hardware
    [LabOperationSystem[]]$OperatingSystems
    [LabDomain[]]$Domains
    [LabNetwork[]]$Networks
    [LabMachine[]]$Machines

    [string] ToString() {
        return $this.Name
    }

    [LabEnvironment] ToMachineConfiguration() {
        $environment = New-Object LabEnvironment -Property @{
            Name = $this.Name
        }
        if ($this.Host) {
            $environment.Host = $this.Host
        }

        return $environment
    }
}
