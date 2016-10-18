<#
Import-Module 'D:\Projects.GitHub\HyperVLab\src\HyperVLab\HyperVLab.psd1' -Force
Get-LabMachine TFSLAB-TD-P | New-LabVM -Verbose -Force -Start
netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=yes
Get-NetFirewallRule -DisplayGroup 'File and Printer Sharing' | select Name,DisplayName,Enabled

> make multiple scenario's work
  + W2012R2 & push/injected (tested role: target-server)
  + W2016 & push/injected   (tested role: target-server)
  - W2012R2 & pull
  - W2016 & pull

- rename HYPERVLAB-CFG to HYPERVLAB-DSC
- add HYPERVLAB-FEED
  - base-configuration using DSC
  - feed-configuration using DSC
  - push/injected or pull?
- add users to LabDomain
- add aliases to LabDnsServer
- add reservations to LabDhcpServer (DhcpIPAddress vs StaticIPAddress)
- configure DSC
  - DSC Pull using HTTPS
  - DSC & encryption (secure passwords)
- SetupComplete.ps1
  - delete unattend.xml
  - set desktop-image (http://powershell.com/cs/blogs/tips/archive/2014/01/10/change-desktop-wallpaper.aspx)
- add specific module-versions to configurations; update Publish-LabConfiguration to publish correct module-version

- ManagedCredential needed in CommonServer?
- ManagementServer
  - SSMS 2016              (incl. .NET 3.5)
  - VS 2015                (incl. extensions (Chocolatey?))
- SqlServer
  - SQL Server 2016
- TfsServer
  - SQL Server 2016
  - TFS Server "15" RC2
- TfsAgent
  - VS 2015                (optional)
  - TFS Agent              (install options? now through HyperVClient module)
- SonarServer
  - Java                   (offline.jre8.8.0.91)
  - SQL Server 2016
  - SonarQube Server       (sonarqube-5.5)
  - SonarQube C# Plugin    (sonar-csharp-plugin-5.2.jar)
- TargetServer
  - Firewall rules


- add optional FilesPath to OperatingSystem; folder-structure for C:\-root
- add properties to Environment, Machine (& MachineTemplate)
  - SqlProductKey      'P7FRV-Y6X6Y-Y8C6Q-TB4QR-DMTTK'
  - TfsServerUrl       'http://tfslab-tfs:8080/tfs'
  - AgentUserName      'TFSLAB\sa-tfs-build'
  - AgentPassword      'P@ssw0rd!'
  - AgentPoolName      'Default'/'ReleaseManagement'

- custom DSC Pull Server
  - discovery service
  - (initialization-)script service
  - pull service
  - reporting service
  - package source for Chocolatey & PowerShell
  - .NET Core, nuget v3 API, container
  - check implementation of xDscWebService
  - check DSC OData API implementation guidance

- TFS Build/Release
  - check existing DSC resources; latest versions
  - install DSC-resources from package-server or TFS
  - install chocolatey-packages using OneGet; from package-server or TFS
  - use offline.* packages i.s.o. quintor.*
  - build-name-format without date
  - deploy web-packages & msi's as chocolatey-packages?
#>
<#
Define new lab-environment
- use commands to build definition, or import
- a lab-environment consists of
  - domain(s), network(s), hardware, operating system(s)
  - machines with hardware, operating system, network(s), domain
  - templates for machines

Create DSC Pull Server
- environment-specific as part of environment
- or HyperVLab-generic machine in seperate environment

Define configuration
- create DSC configurations
- create DSC resources
- publish DSC configurations & resources to DSC Pull Server
  - using host-share? or publish into VM
- use Wait* resources to synchronize & orchestrate configurations across an environment

Create lab-environment
- create the VM's for a lab-environment
- can be entire environment, or part
- add additional machines & create the VM's
- create ad-hoc VM's; by defining a machine, adding it to 'default' environment and creating the VM
#>
<#
- basic machine-configuration (SetupComplete.ps1)
  - execution policy
  - PS-Remoting
  - CredSSP
  - initialize extra disks
  - rename network-adapters
- basic machine-configuration (SetupScript.ps1)
  - update LCM: RebootNodeIfNeeded
  - execute DSC: basic machine-configuration
- basic machine-configuration (DSC)
  - Administrator user password never expires
  - network-adapters
    - IP-address
    - DNS-address(es)
  - remote desktop
  - do not open ServerManager at logon
   -host-share credential

#>
