#Requires -Version 5.0

function Update-HostShares {
    param (
        [PSCustomObject]$Configuration
    )

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

    if ($Configuration -and $Configuration.Host -and $Configuration.Host.Shares) {
        foreach ($share in $Configuration.Host.Shares) {
            EnsureUser -UserName $share.UserName -Password $share.Password
            if ($share.Path.StartsWith('.')) {
                $sharePath = [System.IO.Path]::GetFullPath((Join-Path -Path (Split-Path $Configuration.ConfigurationPath) -ChildPath $share.Path))
            }
            else {
                $sharePath = $share.Path
            }
            EnsureShare -Name $share.Name -Path $sharePath -UserName $share.UserName
        }
    }
}
