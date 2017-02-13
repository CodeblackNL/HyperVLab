
<#
.Synopsis
   Deploy DSC modules to the pullserver.
.DESCRIPTION
   Publish DSC module using Module Info object as an input. 
   The cmdlet will figure out the location of the module repository using web.config of the pullserver.
.EXAMPLE
   Get-Module <ModuleName> | Publish-ModuleToPullServer
#>
function Publish-ModuleToPullServer
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'Don''t use ShouldProcess in internal functions.')]
    [CmdletBinding()]
    [OutputType([void])]
    Param
    (
        # Name of the module.
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $Name,
                
        # This is the location of the base of the module.
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        $ModuleBase,
        
        # This is the version of the module
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)]
        $Version,

        $PullServerWebConfig = "$env:SystemDrive\inetpub\wwwroot\PSDSCPullServer\web.config",

        $OutputFolderPath = $null
    )

    Begin {
        if (-not($OutputFolderPath)) {
            if ( -not(Test-Path $PullServerWebConfig)) {
                throw "Web.Config of the pullserver does not exist on the default path $PullServerWebConfig. Please provide the location of your pullserver web configuration using the parameter -PullServerWebConfig or an alternate path where you want to publish the pullserver modules to"
            }
            else {
                # Pull Server exist figure out the module path of the pullserver and use this value as output folder path.
                $webConfigXml = [xml](Get-Content $PullServerWebConfig)
                $moduleXElement = $webConfigXml.SelectNodes("//appSettings/add[@key = 'ModulePath']")
                $OutputFolderPath =  $moduleXElement.Value
            }
        }
    }
    Process {
       Write-Verbose "Name: $Name , ModuleBase : $ModuleBase ,Version: $Version"
       $targetPath = Join-Path $OutputFolderPath "$($Name)_$($Version).zip"

      if (Test-Path $targetPath) {
            Compress-Archive -DestinationPath $targetPath -Path "$($ModuleBase)\*" -Update -Verbose
      }
      else {
            Compress-Archive -DestinationPath $targetPath -Path "$($ModuleBase)\*" -Verbose
      }
    }

    End {
       # Now that all the modules are published generate thier checksum.
       New-DscChecksum -Path $OutputFolderPath
      
    }
} 
