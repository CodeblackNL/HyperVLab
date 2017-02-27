#Requires -Version 5.0

function Publish-LabAccess {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'TODO: implement ShouldProcess')]
    [CmdletBinding(DefaultParameterSetName = 'EnvironmentName')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Environment', ValueFromPipeline = $true)]
        [LabEnvironment[]]$Environment,
        [Parameter(Mandatory = $true, ParameterSetName = 'EnvironmentName')]
        [string[]]$EnvironmentName,
        [Parameter(Mandatory = $false)]
        [string]$OutputPath
    )

    Process {
        try{
            Import-Module "${env:ProgramFiles(x86)}\code4ward.net\Royal TS V4\RoyalDocument.PowerShell.dll" -Verbose:$false -ErrorAction Stop
        }catch
        {
            throw "Unable to find Royal TS V4"
        }

        if ($($PSCmdlet.ParameterSetName) -in 'EnvironmentName') {
            if ($EnvironmentName) {
                $Environment = Get-LabEnvironment -Name $EnvironmentName
            }
            else {
                $Environment = Get-LabEnvironment
            }
        }

        if (-not $OutputPath) {
            $OutputPath = Join-Path -Path (Get-Location) -ChildPath 'PublishLabAccess'
        }
        if (-not (Test-Path -Path $OutputPath -PathType Container)) {
            New-Item -Path $OutputPath -ItemType Directory -Force
        }

        function EnsureRoyalDocument{
            param (
                [String]$OutputPath,
                [String]$EnvironmentName
            )
            Process {
                Write-Verbose "Ensure existence of RoyalDocument $EnvironmentName in $OutputPath"
                $royalDocumentFileName="$(Join-Path -Path $OutputPath -ChildPath $EnvironmentName).rtsz"
                $store=New-RoyalStore -UserName ($env:USERDOMAIN + '\' + $env:USERNAME)
                $rv=Open-RoyalDocument -FileName $RoyalDocumentFileName -Store $store -ErrorAction SilentlyContinue
                if(!$rv){
                    $rv=New-RoyalDocument -Name $EnvironmentName -FileName $royalDocumentFileName -Store $store
                }
                return $rv
            }
        }

        function EnsureRoyalObject{
            param (
                [String]$Type,
                [RoyalDocumentLibrary.RoyalFolder]$Path,
                [String]$ChildPath
            )
            Process {
                Write-Verbose "Ensure existence of $Type $ChildPath in $($Path.ListInfoPath)"
                $rv=Get-RoyalObject -Type $Type -Name $ChildPath -Folder $Path
                if(!$rv){
                    $rv=New-RoyalObject -Type $Type -Name $ChildPath -Folder $Path
                }
                return $rv
            }
        }
        
        foreach($e in $Environment){
            $royalDocument=EnsureRoyalDocument -OutputPath $OutputPath -EnvironmentName $e.Name
            $royalCredentials=EnsureRoyalObject -Type RoyalFolder -Path $royalDocument -ChildPath 'Credentials'
            $royalConnections=EnsureRoyalObject -Type RoyalFolder -Path $royalDocument -ChildPath 'Connections'
            $royalLocalAdministratorFolder=EnsureRoyalObject -Type RoyalFolder -Path $royalConnections -ChildPath '.\Administrator'
            
            foreach($m in $e.Machines){
                #Ensure existence of RDP session with local administrator
                $royalLocalAdministratorRDP=EnsureRoyalObject -Type RoyalRDSConnection -Path $royalLocalAdministratorFolder -ChildPath "$($m.Name)@.\Administrator"
                $royalLocalAdministratorRDP.URI=$m.NetworkAdapters | ?{$_.Network.Name -eq "Internal"} | %{$_.StaticIPAddress}
                $royalLocalAdministratorRDP.CredentialMode=2
                $royalLocalAdministratorRDP.CredentialUserName=".\Administrator"
                $royalLocalAdministratorRDP.CredentialPassword=[System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($m.AdministratorPassword))

                foreach($d in $m.Environment.Domains){
                    #Ensure existence of domain credential
                    $royalDomainAdministratorCredential=EnsureRoyalObject -Type RoyalCredential -Path $royalCredentials -ChildPath "$($d.NetbiosName)\Administrator"
                    $royalDomainAdministratorCredential.UserName="$($d.NetbiosName)\Administrator"
                    $royalDomainAdministratorCredential.Password=[System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($d.AdministratorPassword))

                    #Ensure existence of domain folder
                    $royalDomainFolder=EnsureRoyalObject -Type RoyalFolder -Path $royalConnections -ChildPath "$($d.NetbiosName)\Administrator"
                    $royalDomainFolder.CredentialMode=3
                    $royalDomainFolder.CredentialId=$royalDomainAdministratorCredential.ID

                    #Ensure existence of RDP session with domain administrator
                    $royalDomainAdministratorRDP=EnsureRoyalObject -Type RoyalRDSConnection -Path $royalDomainFolder -ChildPath "$($m.Name)@$($d.NetbiosName)\Administrator"
                    $royalDomainAdministratorRDP.URI=$m.NetworkAdapters | ?{$_.Network.Name -eq "Internal"} | %{$_.StaticIPAddress}
                    $royalDomainAdministratorRDP.CredentialMode = 3
                    $royalDomainAdministratorRDP.CredentialFromParent = $true
                }
            }
            
            #Save and close Royal TS document
            Out-RoyalDocument -Document $royalDocument
            Close-RoyalDocument -Document $royalDocument    
        }
    }
}
