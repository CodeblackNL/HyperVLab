#Requires -Version 5.0

function Update-LabHostShare
{
    [CmdletBinding(DefaultParameterSetName = 'EnvironmentName')]
    param (
        [Parameter(Mandatory = $false, ParameterSetName = 'Environment', ValueFromPipeline = $true)]
        [LabEnvironment[]]$Environment,
        [Parameter(Mandatory = $false, ParameterSetName = 'EnvironmentName')]
        [string[]]$EnvironmentName
    )

    Begin {
        if (-not (Test-Administrator)) {
            throw 'Please run this command as Administrator.'
        }

        function EnsureUser {
            param (
                [string]$UserName,
                [string]$Password
            )

            $rootPath = "WinNT://$($env:COMPUTERNAME)"
            $userPath = "$rootPath/$UserName,User"
            $user = [adsi]$userPath
            if (-not $user.Path) {
                Write-Verbose -Message "Creating user '$UserName'."
                $user = ([adsi]$rootPath).Create('User', $UserName)
                $user.SetPassword($Password)
                $user.SetInfo()
            }
            else {
                Write-Verbose -Message "Updating password for user '$UserName'."
                $user.SetPassword($Password)
                $user.SetInfo()
            }
        }

        function EnsureShare {
            param (
                [string]$Name,
                [string]$Path,
                [string]$UserName
            )

            if (-not (Test-Path $Path -PathType Container)) {
                Write-Verbose -Message "Creating share-folder '$Path'."
                New-Item -Path $Path -ItemType Directory -Force
            }

            if (-not (Get-WmiObject -Class Win32_Share -Filter "name='$Name'")) {
                Write-Verbose -Message "Sharing folder '$Path' as '$Name'."
                (Get-WmiObject -Class Win32_Share -List).Create($Path, $Name, 0) | Out-Null
            }

            Write-Verbose -Message "Ensuring folder '$Path' as '$Name'."
            $acl = Get-Acl -Path $Path
            if (-not ($acl.Access |? { $_.IdentityReference -match "$($UserName)$" })) {
                Write-Verbose -Message "Allow access to share '$Name' by '$UserName'."
                $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $UserName,'FullControl','Allow'
                $acl.SetAccessRule($accessRule)
                Set-Acl -Path $Path -AclObject $acl
            }
        }
    }

    Process {
        if ($($PSCmdlet.ParameterSetName) -ne 'Environment') {
            if ($EnvironmentName) {
                $Environment = Get-LabEnvironment -Name $EnvironmentName
            }
        }

        if (-not $Environment) {
            return
        }

        foreach ($e in $Environment) {
            if (-not $e.Host) {
                Write-Warning -Message "Environment '$($e.Name)' does not contain a host-configuration."
                return
            }

            if (-not $Environment.Host.Share) {
                Write-Warning -Message "Environment '$($e.Name)' does not contain a share-configuration."
                return
            }

            $labPath = Split-Path -Path $e.Path -Parent
            $share = $e.Host.Share

            if ($share.Path.StartsWith('.')) {
                $sharePath = [System.IO.Path]::GetFullPath((Join-Path -Path $labPath -ChildPath $Share.Path))
            }
            else {
                $sharePath = $share.Path
            }

            $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($share.Password)
            $password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)

            EnsureUser -UserName $share.UserName -Password $password
            EnsureShare -Name $share.Name -Path $sharePath -UserName $share.UserName
        }
    }
}