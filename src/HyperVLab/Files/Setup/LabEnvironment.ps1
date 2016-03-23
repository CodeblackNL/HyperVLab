
Configuration DomainController {
    Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'bPSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'xComputerManagement'
    Import-DscResource -ModuleName 'xActiveDirectory'
    Import-DscResource -ModuleName 'xDhcpServer'
    Import-DscResource -ModuleName 'bDnsServer'
    Import-DscResource -ModuleName 'bDhcpServer'

    $securePassword = ConvertTo-SecureString $Node.Domain.AdministratorPassword -AsPlainText -Force
    $domainCredential = New-Object -TypeName PSCredential -ArgumentList "Administrator@$($Node.Domain.Name)",$securePassword

    $securePassword = ConvertTo-SecureString $Node.AdministratorPassword -AsPlainText -Force
    $localCredential = New-Object -TypeName PSCredential -ArgumentList "Administrator",$securePassword

    $mgmtTools = !!(get-itemproperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Server\ServerLevels').'Server-Gui-Mgmt'

    bRemoteLog "LogRemoteMessage_$([Guid]::NewGuid())" {
        Message = "Starting configuration of $($Node.MachineName) as DomainController"
    }

    xComputer ComputerName {
        Name                = $Node.MachineName
    }
    bRemoteLog "LogRemoteMessage_$([Guid]::NewGuid())" {
        Message = "Computer-name changed"
    }

    WindowsFeature ADDSInstall {
        Name                = "AD-Domain-Services"
        DependsOn           = "[xComputer]ComputerName"
    }
    if ($mgmtTools) {
        WindowsFeature ADDSInstallMgmtTools {
            Name            = "RSAT-ADDS-Tools"
            DependsOn       = "[WindowsFeature]ADDSInstall"
        }
    }
    bRemoteLog "LogRemoteMessage_$([Guid]::NewGuid())" {
        Message         = "Active Directory installed"
        DependsOn       = "[WindowsFeature]ADDSInstall"
    }

    xADDomain ADDSForest { 
        DomainName                    = $Node.Domain.Name
        DomainAdministratorCredential = $domainCredential
        SafemodeAdministratorPassword = $domainCredential
        DependsOn                     = "[WindowsFeature]ADDSInstall"
    }
    foreach($user in $Node.Users) {
        $securePassword = ConvertTo-SecureString $User.Password -AsPlainText -Force
        $userCredential = New-Object -TypeName PSCredential -ArgumentList $user.UserName,$securePassword

        xADUser "User_$($user.UserName)" {
            Ensure                        = "Present"
            UserName                      = $user.UserName
            Password                      = $userCredential
            DomainName                    = $Node.Domain.Name
            DomainAdministratorCredential = $domainCredential
            DependsOn                     = "[xADDomain]ADDSForest"
        }
    }
    foreach ($alias in $Node.Aliases) {
        bDnsServerResourceRecordCName "DnsCName_$($alias.Name)" {
            Name           = $alias.Name
            HostNameAlias  = "$($alias.HostName).$($Node.Domain.Name)"
            ZoneName       = $Node.Domain.Name
            DependsOn      = "[xADDomain]ADDSForest"
        }
    }
    bRemoteLog "LogRemoteMessage_$([Guid]::NewGuid())" {
        Message            = "AD Domain configured"
        DependsOn          = "[xADDomain]ADDSForest"
    }

    WindowsFeature DHCPInstall {
        Name               = "DHCP"
        DependsOn          = "[xADDomain]ADDSForest"
    }
    if ($mgmtTools) {
        WindowsFeature DHCPInstallMgmtTools {
            Name           = "RSAT-DHCP"
            DependsOn      = "[WindowsFeature]DHCPInstall"
        }
    }
    bRemoteLog "LogRemoteMessage_$([Guid]::NewGuid())" {
        Message        = "DHCP installed"
        DependsOn      = "[WindowsFeature]DHCPInstall"
    }

    xDhcpServerScope DHCPScope {
        Ensure             = "Present"
        Name               = $Node.Domain.DhcpServerScopeName
        IPStartRange       = $Node.Domain.DhcpServerStartRange
        IPEndRange         = $Node.Domain.DhcpServerEndRange
        SubnetMask         = $Node.Domain.DhcpServerSubnetMask
        LeaseDuration      = $Node.Domain.DhcpServerLeaseDurationDays
        State              = "Active"
        DependsOn          = "[WindowsFeature]DHCPInstall"
    }
    bDhcpServerOption DHCPOptions {
        Ensure             = "Present"
        ScopeID            = $Node.Domain.DhcpServerScopeId
        DnsServerIPAddress = $Node.Domain.DnsServerIPAddress
        DefaultGateway     = $Node.Domain.DhcpServerDefaultGateway
        DependsOn          = "[xDhcpServerScope]DHCPScope"
    }
    bRemoteLog "LogRemoteMessage_$([Guid]::NewGuid())" {
        Message            = "DHCP configured"
        DependsOn          = "[xDhcpServerScope]DHCPScope"
    }

    bDhcpServerConfigurationCompletion DHCPInstallCompletion {
        Ensure             = "Present"
        MachineName        = $Node.MachineName
        DependsOn          = "[bDhcpServerOption]DHCPOptions"
    }
    Script AuthorizeDHCP {
        TestScript = {
            return !!(Get-DhcpServerInDC |? { $_.DnsName -eq "$($using:Node.MachineName).$($using:Node.Domain.Name)" });
        }
        GetScript = { return @{ } }
        SetScript = {
            Add-DhcpServerInDC -DnsName "$($using:Node.MachineName).$($using:Node.Domain.Name)"
        }
        DependsOn = "[bDhcpServerOption]DHCPOptions"
    }
    bRemoteLog "LogRemoteMessage_$([Guid]::NewGuid())" {
        Message = "DHCP configuration completed"
        DependsOn = "[Script]AuthorizeDHCP"
    }
}

Configuration MemberServer {
    Import-DscResource -ModuleName 'bPSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'xComputerManagement'

    $securePassword = ConvertTo-SecureString $Node.Domain.AdministratorPassword -AsPlainText -Force
    $domainCredential = New-Object -TypeName PSCredential -ArgumentList "Administrator@$($Node.Domain.Name)",$securePassword

    bRemoteLog "LogRemoteMessage_$([Guid]::NewGuid())" {
        Message = "Starting configuration of $($Node.MachineName) as MemberServer"
    }

    # wait a little, so the network-adapter can retrieve dns-information; otherwise add-to-domain will fail
    Script WaitForNetwork {
        TestScript = { return $false; }
        GetScript = { return @{ } }
        SetScript = {
            Start-Sleep -Seconds 10
        }
    }

    xComputer ComputerNameAndDomain {
        Name                    = $Node.MachineName
        DomainName              = $Node.Domain.Name
        Credential              = $domainCredential
        DependsOn               = "[Script]WaitForNetwork"
    }

    bRemoteLog "LogRemoteMessage_$([Guid]::NewGuid())" {
        Message                 = "Computer-name changed and joined domain"
        DependsOn               = "[xComputer]ComputerNameAndDomain"
    }
}

Configuration LabConfiguration {
    Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'bPSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'xNetworking'
    Import-DscResource -ModuleName 'xRemoteDesktopAdmin'

    Node $AllNodes.NodeName {

        <# The following initialization is done in the setup-complete script
            + Initialize PowerShell environment (ExecutionPolicy:Unrestricted)
            + Enable PS-Remoting
            + Enable CredSSP
            + Format Extra-Disk (only if present and not yet formatted)
            + Change LCM:RebootNodeIfNeeded
            + Apply this configuration
        #>
        $securePassword = ConvertTo-SecureString $Node.AdministratorPassword -AsPlainText -Force
        $passwordCredential = New-Object -TypeName PSCredential -ArgumentList "user-name",$securePassword

        bRemoteLog "LogRemoteMessage_$([Guid]::NewGuid())" {
            Message = "Configuration of $($Node.MachineName) started"
        }

        # Administrator password never expires
        User Administrator {
            Ensure                  = "Present"
            UserName                = "Administrator"
            Password                = $passwordCredential
            PasswordChangeRequired  = $false
            PasswordNeverExpires    = $true
        }

        bRemoteLog "LogRemoteMessage_$([Guid]::NewGuid())" {
            Message = "User 'administrator' configured"
            DependsOn = "[User]Administrator"
        }

        foreach ($networkAdapter in $Node.NetworkAdapters) {

            $nameProperty = Get-NetAdapterAdvancedProperty -Name * |? { $_.ValueName -eq 'HyperVNetworkAdapterName' -and $_.DisplayValue -eq $networkAdapter.Name } | select -First 1
            if (-not $nameProperty) {
                Log "Log_NetworkAdapter_$($networkAdapter.Name)_Property_Failure" {
                    Message = "WARNING: Unable to find network-adapter property for name '$($networkAdapter.Name)'"
                }
                
                continue
            }

            $netAdapter = Get-NetAdapter |? { $_.Name -eq $nameProperty.InterfaceAlias }
            if (-not $netAdapter) {
                Log "Log_NetworkAdapter_$($networkAdapter.Name)_Property_Failure" {
                    Message = "WARNING: Unable to find network-adapter for alias '$($nameProperty.InterfaceAlias)'"
                }
                
                continue
            }

            if ($networkAdapter.StaticIPAddress) {
                <# NOTE: xDhcpClient not yet available; but setting static IP address will disable DHCP
                xDhcpClient EnableDhcpClient
                {
                    InterfaceAlias      = $netAdapter.Name
                    AddressFamily       = $networkAdapter.AddressFamily
                    State               = 'Enabled'
                }#>

                xIPAddress "Network_$($netAdapter.Name)" {
                    InterfaceAlias      = $netAdapter.Name
                    AddressFamily       = $networkAdapter.AddressFamily
                    IPAddress           = $networkAdapter.StaticIPAddress
                    SubnetMask          = $networkAdapter.PrefixLength
                }

                if ($networkAdapter.DnsServerIPAddress) {
                    xDnsServerAddress "DnsServerAddress_$($netAdapter.Name)" {
                        InterfaceAlias = $netAdapter.Name
                        AddressFamily  = $networkAdapter.AddressFamily
                        Address        = $networkAdapter.DnsServerIPAddress
                        DependsOn      = "[xIPAddress]Network_$($netAdapter.Name)"
                    }

                    bRemoteLog "LogRemoteMessage_$([Guid]::NewGuid())" {
                        Message        = "Network-adapter '$($netAdapter.Name)' configured with DNS"
                        DependsOn      = "[xDnsServerAddress]DnsServerAddress_$($netAdapter.Name)"
                    }
                }
                else {
                    bRemoteLog "LogRemoteMessage_$([Guid]::NewGuid())" {
                        Message        = "Network-adapter '$($netAdapter.Name)' configured without DNS"
                        DependsOn      = "[xIPAddress]Network_$($netAdapter.Name)"
                    }
                }
            }
            else {
                <# NOTE: xDhcpClient not yet available; but network-adapters have DHCP enable by default
                xDhcpClient DisableDhcpClient
                {
                    InterfaceAlias     = $netAdapter.Name
                    AddressFamily      = $networkAdapter.AddressFamily
                    State              = 'Disabled'
                }#>

                bRemoteLog "LogRemoteMessage_$([Guid]::NewGuid())" {
                    Message        = "Network-adapter '$($netAdapter.Name)' configured for DHCP"
                }
            }
        }

        xRemoteDesktopAdmin RemoteDesktopSettings {
            Ensure					= "Present" 
            UserAuthentication		= "Secure"
        }
        xFirewall AllowRDP {
            Ensure					= "Present"
            Name					= "RemoteDesktop-UserMode-In-TCP"
            Enabled					= "True"
        }

        bRemoteLog "LogRemoteMessage_$([Guid]::NewGuid())" {
            Message = "Remote Desktop configured"
            DependsOn = "[xRemoteDesktopAdmin]RemoteDesktopSettings","[xFirewall]AllowRDP"
        }

        if ($Node.Role -contains ('DomainController')) {
            DomainController DomainController { }

            bRemoteLog "LogRemoteMessage_$([Guid]::NewGuid())" {
                Message = "Configuration of $($Node.MachineName) finished"
                DependsOn = "[DomainController]DomainController"
            }
        }
        else {
            MemberServer MemberServer { }

            bRemoteLog "LogRemoteMessage_$([Guid]::NewGuid())" {
                Message = "Configuration of $($Node.MachineName) finished"
                DependsOn = "[MemberServer]MemberServer"
            }
        }

        <#foreach ($role in $Node.Role) {
            switch ($role) {
                "DomainController" {
                    DomainController DomainController { }
                }
            }
        }

        bRemoteLog "LogRemoteMessage_$([Guid]::NewGuid())" {
            Message = "Configuration of $($Node.MachineName) finished"
            DependsOn = "[DomainController]DomainController"
        }#>
    }
}
