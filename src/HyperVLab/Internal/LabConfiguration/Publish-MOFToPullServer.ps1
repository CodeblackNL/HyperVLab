
<#
.Synopsis
   Deploy DSC Configuration document to the pullserver.
.DESCRIPTION
   Publish Mof file to the pullserver. It takes File Info object as pipeline input. It also auto detects the location of the configuration repository using the web.config of the pullserver.
.EXAMPLE
   Dir <path>\*.mof | Publish-MOFToPullServer
#>
function Publish-MOFToPullServer
{
    [CmdletBinding()]
    [Alias("pcp")]
    [OutputType([void])]
    Param
    (
        # Mof file Name
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $FullName,
       
        $PullServerWebConfig = "$env:SystemDrive\inetpub\wwwroot\PSDSCPullServer\web.config"
    )

    Begin
    {
       $webConfigXml = [xml](cat $PullServerWebConfig)
       $configXElement = $webConfigXml.SelectNodes("//appSettings/add[@key = 'ConfigurationPath']")
       $OutputFolderPath =  $configXElement.Value
    }
    Process
    {
        $fileInfo = [System.IO.FileInfo]::new($FullName)
        if ($fileInfo.Extension -eq '.mof')
        {
            if (Test-Path $FullName)
            {
                copy $FullName $OutputFolderPath -Verbose -Force
            }
            else 
            {
                Throw "File not found at $FullName"
            } 
        }
        else
        {
            throw "Invalid file $FullName. Only mof files can be copied to the pullserver configuration repository"
        }       
    }
    End
    {
        New-DscChecksum -Path $OutputFolderPath -Force
    }
}
