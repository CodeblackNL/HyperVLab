function Initialize-LabVM {
    if ($script:configuration) {
        #######################################
        # Share
        #######################################
	    if ($script:configuration.Environment.Host -and $script:configuration.Environment.Host.Share) {
            $share = $script:configuration.Environment.Host.Share
            $sharePath = "\\$($script:configuration.Environment.Host.Name)\$($share.Name)"
            if (-not (Get-PSDrive -PSProvider FileSystem |? { $_.Name -eq $share.DriveLetter })) {
                Write-Log "INFO" "Adding share '$($share.Name)' at '$sharePath'"
                $userName = "$($script:configuration.Environment.Host.Name)\$($share.UserName)"
                #$securePassword = ConvertTo-SecureString -String $($share.Password) -AsPlainText -Force                $securePassword = ConvertTo-SecureString -String 'P@ssw0rd!' -AsPlainText -Force                $credential = New-Object -TypeName PSCredential -ArgumentList $userName,$securePassword                New-PSDrive -PSProvider FileSystem -Name $share.DriveLetter -Root $sharePath -Persist -Credential $credential -Scope Global | Out-Null
                Write-Log "INFO" "Share '$($share.Name)' at '$sharePath' added"
            }
            else {
                Write-Log "INFO" "Share '$($share.Name)' at '$sharePath' already added"
            }
	    }
	    else {
		    Write-Log "INFO" "No share in configuration"
	    }

        #######################################
        # Configure PowerShellGet & Chocolatey
        #######################################
        $packageSourceName = $configuration.Environment.Host.Share.Name
        $packageSourcePath = "\\$($configuration.Environment.Host.Name)\$($configuration.Environment.Host.Share.Name)\packages"
        if (-not (Test-Path -Path $packageSourcePath)) {
            Write-Log "INFO" "Package-source path not present"
        }
        elseif (Get-PackageSource -Name $packageSourceName -ErrorAction SilentlyContinue) {
            Write-Log "INFO" "Package-source already registered"
        }
        else {
            Write-Log "INFO" "Registering the package-source"
            Register-PackageSource -Name $packageSourceName -Provider Chocolatey -Location $packageSourcePath -Trusted
            # Register-PackageSource -Name chocolatey -Provider PowerShellGet -Location http://chocolatey.org/api/v2 -Trusted

            #choco source add -n="$packageSourceName" -s"$packageSourcePath"

            Write-Log "INFO" "Finished registering the package-source"
        }
    }
	else {
		Write-Log "WARNING" "No configuration"
	}
}




