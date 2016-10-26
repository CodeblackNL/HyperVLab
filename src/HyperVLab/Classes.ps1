class LabObject {
}

class LabOperationSystem : LabObject {
    [string]$Name
    [string]$FilePath
    [string]$UnattendFilePath
    [string]$ProductKey
    [LabEnvironment]$Environment

    [string] ToString()
    {
        return $this.Name
    }

    [Hashtable] ToMachineConfiguration() {
        return @{
            Name = $this.Name
            FilePath = $this.FilePath
            UnattendFilePath = $this.UnattendFilePath
            #ProductKey = $this.ProductKey
        }
    }

    [Hashtable] ToHashtable() {
        return @{
            Name = $this.Name
            FilePath = $this.FilePath
            UnattendFilePath = $this.UnattendFilePath
            ProductKey = $this.ProductKey
        }
    }
}

class LabHardware : LabObject {
    [string]$Name
    [int]$ProcessorCount
    [long]$StartupMemory
    [long]$MinimumMemory
    [long]$MaximumMemory
    [LabEnvironment]$Environment

    [string] ToString() {
        return $this.Name
    }

    [Hashtable] ToMachineConfiguration() {
        return $this.ToHashtable()
    }

    [Hashtable] ToHashtable() {
        return @{
            Name = $this.Name
            ProcessorCount = $this.ProcessorCount
            StartupMemory = $this.StartupMemory
            MinimumMemory = $this.MinimumMemory
            MaximumMemory = $this.MaximumMemory
        }
    }
}

class LabDomain : LabObject {
    [string]$Name
    [string]$NetbiosName
    [SecureString]$AdministratorPassword
    [LabEnvironment]$Environment

    [string] ToString() {
        return $this.Name
    }

    [Hashtable] ToMachineConfiguration() {
        return @{
            Name = $this.Name
            NetbiosName = $this.NetbiosName
            AdministratorPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($this.AdministratorPassword))
        }
    }

    [Hashtable] ToHashtable() {
        return @{
            Name = $this.Name
            NetbiosName = $this.NetbiosName
            AdministratorPassword = $this.AdministratorPassword
        }
    }
}

class LabDnsServer : LabObject {
    [string]$IPAddress

    [string] ToString() {
        return $this.IPAddress
    }

    [Hashtable] ToMachineConfiguration() {
        return $this.ToHashtable()
    }

    [Hashtable] ToHashtable() {
        return @{
            IPAddress = $this.IPAddress
        }
    }
}

class LabDhcpServer : LabObject {
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

    [Hashtable] ToMachineConfiguration() {
        return $this.ToHashtable()
    }

    [Hashtable] ToHashtable() {
        return @{
            IPAddress = $this.IPAddress
            ScopeName = $this.ScopeName
            ScopeId = $this.ScopeId
            StartRange = $this.StartRange
            EndRange = $this.EndRange
            SubnetMask = $this.SubnetMask
            LeaseDurationDays = $this.LeaseDurationDays
            DefaultGateway = $this.DefaultGateway
        }
    }
}

class LabNetwork : LabObject {
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

    [Hashtable] ToMachineConfiguration() {
        $hashtable = @{
            Name = $this.Name
            SwitchName = $this.SwitchName
            SwitchType = $this.SwitchType
            SwitchNetAdapterName = $this.SwitchNetAdapterName
            AddressFamily = $this.AddressFamily
            PrefixLength = $this.PrefixLength
            HostIPAddress = $this.HostIPAddress
        }

        if ($this.Domain) {
            $hashtable.Domain = $this.Domain.ToMachineConfiguration()
        }
        if ($this.DnsServer) {
            $hashtable.DnsServer = $this.DnsServer.ToMachineConfiguration()
        }
        if ($this.DhcpServer) {
            $hashtable.DhcpServer = $this.DhcpServer.ToMachineConfiguration()
        }

        return $hashtable
    }

    [Hashtable] ToHashtable() {
        $hashtable = @{
            Name = $this.Name
            SwitchName = $this.SwitchName
            SwitchType = $this.SwitchType
            SwitchNetAdapterName = $this.SwitchNetAdapterName
            AddressFamily = $this.AddressFamily
            PrefixLength = $this.PrefixLength
            HostIPAddress = $this.HostIPAddress
        }

        if ($this.Domain) {
            $hashtable.Domain = $this.Domain.ToHashtable()
        }
        if ($this.DnsServer) {
            $hashtable.DnsServer = $this.DnsServer.ToHashtable()
        }
        if ($this.DhcpServer) {
            $hashtable.DhcpServer = $this.DhcpServer.ToHashtable()
        }

        return $hashtable
    }
}

class LabNetworkAdapter : LabObject {
    [LabNetwork]$Network
    [string]$StaticMacAddress
    [string]$StaticIPAddress

    [Hashtable] ToMachineConfiguration() {
        $hashtable = @{
            StaticMacAddress = $this.StaticMacAddress
            StaticIPAddress = $this.StaticIPAddress
        }

        if ($this.Network) {
            $hashtable.Network = $this.Network.ToMachineConfiguration()
        }

        return $hashtable
    }

    [Hashtable] ToHashtable() {
        $hashtable = @{
            StaticMacAddress = $this.StaticMacAddress
            StaticIPAddress = $this.StaticIPAddress
        }

        if ($this.Network) {
            $hashtable.Network = $this.Network.ToHashtable()
        }

        return $hashtable
    }
}

class LabDisk : LabObject {
    [string]$DriveLetter                       # optional; always replaced with 'C' if OperatingSystem is provided
    [LabOperationSystem]$OperatingSystem       # optional
    [bool]$DifferencingDisk                    # optional; only valid if OperatingSystem is provided, otherwise ignored
    [bool]$UseEnvironmentCopy                  # optional; only valid if DifferencingDisk is true, otherwise ignored
    [long]$Size                                # mandatory if OperatingSystem not provided, otherwise ignored

    [Hashtable] ToMachineConfiguration() {
        $hashtable = @{
            DriveLetter = $this.DriveLetter
            DifferencingDisk = $this.DifferencingDisk
            UseEnvironmentCopy = $this.UseEnvironmentCopy
            Size = $this.Size
        }

        if ($this.OperatingSystem) {
            $hashtable.OperatingSystem = $this.OperatingSystem.ToMachineConfiguration()
        }

        return $hashtable
    }

    [Hashtable] ToHashtable() {
        $hashtable = @{
            DriveLetter = $this.DriveLetter
            DifferencingDisk = $this.DifferencingDisk
            UseEnvironmentCopy = $this.UseEnvironmentCopy
            Size = $this.Size
        }

        if ($this.OperatingSystem) {
            $hashtable.OperatingSystem = $this.OperatingSystem.ToHashtable()
        }

        return $hashtable
    }
}

class LabMachine : LabObject {
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

    [Hashtable] ToMachineConfiguration() {
        $hashtable = @{
            Name = $this.Name
            AdministratorPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($this.AdministratorPassword))
            TimeZone = $this.TimeZone
        }

        if ($this.Role) {
            $hashtable.Role = @($this.Role)
        }
        if ($this.Properties) {
            $hashtable.Properties = $this.Properties
        }
        if ($this.AllProperties) {
            $hashtable.AllProperties = $this.AllProperties
        }
        if ($this.Hardware) {
            $hashtable.Hardware = $this.Hardware.ToMachineConfiguration()
        }
        if ($this.Disks) {
            $hashtable.Disks = @($this.Disks |% { $_.ToMachineConfiguration() })
        }
        if ($this.NetworkAdapters) {
            $hashtable.NetworkAdapters = @($this.NetworkAdapters |% { $_.ToMachineConfiguration() })
        }
        if ($this.Environment) {
            $hashtable.Environment = $this.Environment.ToMachineConfiguration()
        }

        return $hashtable
    }

    [Hashtable] ToHashtable() {
        <#$hashtable = @{}
        # ValueType     : add key/value
        # Hashtable     : add key/value
        # custom-object : add key/value.ToHashtable()

        # exclude recursive properties
        foreach ($property in $this.PSObject.Properties) {
            $type = [Type]::GetType($property.TypeNameOfValue)
            if ($type.IsValueType -or $type.FullName -eq 'System.String') {
                $hashtable.($property.Name) = $($this.($property.Name))
            }
        }#>

        $hashtable = @{
            Name = $this.Name
            AdministratorPassword = $this.AdministratorPassword
            TimeZone = $this.TimeZone
            FilesPath = $this.FilesPath
        }

        if ($this.Role) {
            $hashtable.Role = @($this.Role)
        }
        if ($this.Properties) {
            $hashtable.Properties = $this.Properties
        }
        if ($this.AllProperties) {
            $hashtable.AllProperties = $this.AllProperties
        }
        if ($this.Hardware) {
            $hashtable.Hardware = $this.Hardware.ToHashtable()
        }
        if ($this.Disks) {
            $hashtable.Disks = @($this.Disks |% { $_.ToHashtable() })
        }
        if ($this.NetworkAdapters) {
            $hashtable.NetworkAdapters = @($this.NetworkAdapters |% { $_.ToHashtable() })
        }
        if ($this.Environment) {
            $hashtable.Environment = $this.Environment.ToHashtable()
        }

        return $hashtable
    }
}

#class LabMachineTemplate : LabMachine {
#}

class LabHostShare : LabObject {
    [string]$Name
    [string]$Path
    [string]$DriveLetter
    [string]$UserName
    [SecureString]$Password

    [string] ToString() {
        return $this.Name
    }

    [Hashtable] ToMachineConfiguration() {
        $hashtable = @{
            Name = $this.Name
            Path = $this.Path
            DriveLetter = $this.DriveLetter
            UserName = $this.UserName
        }

        if ($this.Password) {
            $hashtable.Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($this.Password))
        }

        return $hashtable
    }

    [Hashtable] ToHashtable() {
        return @{
            Name = $this.Name
            Path = $this.Path
            DriveLetter = $this.DriveLetter
            UserName = $this.UserName
            Password = $this.Password
        }
    }
}

class LabHost : LabObject {
    [string]$Name
    [LabHostShare]$Share

    [string] ToString() {
        return $this.Name
    }

    [Hashtable] ToMachineConfiguration() {
        $hashtable = @{
            Name = $this.Name
        }

        if ($this.Share) {
            $hashtable.Share = $this.Share.ToMachineConfiguration()
        }

        return $hashtable
    }

    [Hashtable] ToHashtable() {
        $hashtable = @{
            Name = $this.Name
        }

        if ($this.Share) {
            $hashtable.Share = $this.Share.ToHashtable()
        }

        return $hashtable
    }
}

class LabEnvironment : LabObject {
    [string]$Name
    [string]$Path
    [string]$MachinesPath
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

    [Hashtable] ToMachineConfiguration() {
        $hashtable = @{
            Name = $this.Name
        }

        if ($this.Properties) {
            $hashtable.Properties = $this.Properties
        }
        if ($this.Host) {
            $hashtable.Host = $this.Host.ToMachineConfiguration()
        }

        return $hashtable
    }

    [Hashtable] ToHashtable() {
        $hashtable = @{
            Name = $this.Name
            Path = $this.Path
            MachinesPath = $this.MachinesPath
            FilesPath = $this.FilesPath
            ConfigurationFilePath = $this.ConfigurationFilePath
            ConfigurationName = $this.ConfigurationName
            CertificateFilePath = $this.CertificateFilePath
            CertificateThumbprint = $this.CertificateThumbprint
            Properties = $this.Properties
        }

        if ($this.Host) {
            $hashtable.Host = $this.Host.ToHashtable()
        }

        return $hashtable
    }
}
