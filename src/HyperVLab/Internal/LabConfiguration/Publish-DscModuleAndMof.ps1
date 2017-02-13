<#
.Synopsis
   Package DSC modules and mof configuration document and publish them on an enterprise DSC pull server in the required format.
.DESCRIPTION
   Uses Publish-DSCModulesAndMof function to package DSC modules into zip files with the version info. 
   Publishes the zip modules on "$env:ProgramFiles\WindowsPowerShell\DscService\Modules".
   Publishes all mof configuration documents that are present in the $Source folder on "$env:ProgramFiles\WindowsPowerShell\DscService\Configuration"-
   Use $Force to overwrite the version of the module that exists in the PowerShell module path with the version from the $source folder.
   Use $ModuleNameList to specify the names of the modules to be published if the modules do not exist in $Source folder.
.EXAMPLE
    $ModuleList = @("xWebAdministration", "xPhp")
    Publish-DSCModuleAndMof -Source C:\LocalDepot -ModuleNameList $ModuleList
.EXAMPLE
    Publish-DSCModuleAndMof -Source C:\LocalDepot -Force
#>

# Tools to use to package DSC modules and mof configuration document and publish them on enterprise DSC pull server in the required format
function Publish-DscModuleAndMof {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'Don''t use ShouldProcess in internal functions.')]
    [CmdletBinding()]
    param (
        # The folder that contains the configuration mof documents. Everything in this folder will be packaged and published.
        [Parameter(Mandatory = $true)]
        [string]$Path, 
        # Package and publish the modules listed in $ModuleNames based on PowerShell module path content.
        [string[]]$ModuleNames,
        [string]$ComputerName,
        [PSCredential]
        [System.Management.Automation.Credential()]
        $Credential
    )

    function PackageModules {
        param (
            [string[]]$ModuleNames,
            [string]$Destination
        )

        # Move all required  modules from powershell module path to a temp folder and package them
        if ($ModuleNames) {
            foreach ($moduleName in $ModuleNames) {
                $moduleVersions = Get-Module -Name $moduleName -ListAvailable -Verbose        
                foreach ($moduleVersion in $moduleVersions) {
                    $name = $moduleVersion.Name
                    $version = $moduleVersion.Version.ToString()
                    $modulePath = $moduleVersion.ModuleBase
                    $destinationFilePath = Join-Path -Path $Destination -ChildPath "$($name)_$($version).zip"

                    Write-Log -Scope $MyInvocation -Message "Zipping $name ($version)"
                    Compress-Archive -Path "$modulePath\*" -DestinationPath $destinationFilePath -Verbose -Force 
                } 
            }   
        }
        else {
            Write-Log -Scope $MyInvocation -Message "No additional modules are specified to be packaged." 
        }
    }

    function PublishModules {
        param (
            [string]$Path,
            [System.Management.Automation.Runspaces.PSSession]$Session
        )

        # TODO: find module-repository folder from web.config
        #       (Get-Website 'PSDSCPullServer').PhysicalPath
        #       appSetting:ModulePath
        $moduleRepository = "$env:ProgramFiles\WindowsPowerShell\DscService\Modules"
        [ScriptBlock]$scriptBlock = {
            param ($ModuleRepository)
            return (Get-Module ServerManager -ListAvailable) -and (Test-Path $ModuleRepository)
        }

        if ($Session) {
            $isDscPullServer = Invoke-Command -Session $Session -ScriptBlock $scriptBlock -ArgumentList $moduleRepository
        }
        else {
            $isDscPullServer = $scriptBlock.Invoke($moduleRepository)
        }

        if (-not $isDscPullServer) {
            Write-Warning "Copying module(s) to Pull server module repository skipped because the machine is not a server sku or Pull server endpoint is not deployed."
            return
        }

        Write-Log -Scope $MyInvocation -Message "Copying modules and checksums to [$moduleRepository]."
        if ($Session) {
            Copy-Item -Path "$Path\*.zip*" -Destination $moduleRepository -ToSession $Session -Force
        }
        else {
            Copy-Item -Path "$Path\*.zip*" -Destination $moduleRepository -Force
        }
    }

    function PublishMofDocuments {
       param (
            [string]$Path,
            [System.Management.Automation.Runspaces.PSSession]$Session
        )

        # TODO: find configuration-repository folder from web.config
        #       (Get-Website 'PSDSCPullServer').PhysicalPath
        #       appSetting:ConfigurationPath
        $mofRepository = "$env:ProgramFiles\WindowsPowerShell\DscService\Configuration"
        [ScriptBlock]$scriptBlock = {
            param ($MofRepository)
            return (Get-Module ServerManager -ListAvailable) -and (Test-Path $MofRepository)
        }

        if ($Session) {
            $isDscPullServer = Invoke-Command -Session $Session -ScriptBlock $scriptBlock -ArgumentList $mofRepository
        }
        else {
            $isDscPullServer = $scriptBlock.Invoke($mofRepository)
        }

        if (-not $isDscPullServer) {
            Write-Warning "Copying configuration(s) to Pull server configuration repository skipped because the machine is not a server sku or Pull server endpoint is not deployed."
            return
        }

        Write-Log -Scope $MyInvocation -Message "Copying mofs and checksums to [$moduleRepository]."
        if ($Session) {
            Copy-Item -Path "$Path\*.mof*" -Destination $mofRepository -ToSession $Session -Force
        }
        else {
            Copy-Item -Path "$Path\*.mof*" -Destination $mofRepository -Force
        }
    }

    Write-Log -Scope $MyInvocation -Message 'Start Deployment'

    $tempFolder = Join-Path -Path $Path -ChildPath 'temp'
    New-Item -Path $tempFolder -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null

    Copy-Item -Path "$Path\*.mof" -Destination $tempFolder -Force -Verbose

    PackageModules -ModuleNames $ModuleNames -Destination $tempFolder

    New-DSCCheckSum -Path $tempFolder -Force

    if ($ComputerName) {
        if ($Credential) {
            $session = New-PSSession -ComputerName $ComputerName -Credential $Credential
        }
        else {
            $session = New-PSSession -ComputerName $ComputerName
        }

        if ($ModuleNames) {
            PublishModules -Path $tempFolder -Session $session
        }
        PublishMofDocuments -Path $tempFolder -Session $session

        Remove-PSSession -Session $session
    }
    else {
        if ($ModuleNames) {
            PublishModules -Path $tempFolder
        }
        PublishMofDocuments -Path $tempFolder
    }

    Remove-Item -Path $tempFolder -Recurse -Force -ErrorAction SilentlyContinue
    Write-Log -Scope $MyInvocation -Message 'End Deployment'
}
