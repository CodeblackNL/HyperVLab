#Requires -Version 5.0

function Add-FilesIntoVirtualHardDisk {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $false)]
        [Array]$FilesToCopy
    )

    if ($FilesToCopy -and $FilesToCopy.Length -gt 0) {
        $vm = Get-VM -Name $Name
        $vhd = $vm | Get-VMHardDiskDrive -ControllerNumber 0 -ControllerLocation 0

        Write-Verbose -Message '- mounting virtual harddisk'
        Mount-VHD -Path $vhd.Path -ErrorAction SilentlyContinue -ErrorVariable $var
        $mountedVHD = Get-VHD -Path $vhd.Path

        # if mounting the VHD failed, dismount the VHD and mount it again
        if ((-not $mountedVHD) -or ($mountedVHD -and -not $mountedVHD.Attached)) {
            Write-Verbose -Message '- mounting failed; attempting to dismount and mount it again'
            try {
                Write-Verbose -Message '- dismounting virtual harddisk'
                Dismount-VHD -Path $vhd.Path
            }
            catch {
                Write-Warning -Message '- failed to dismount virtual harddisk'
            }
            Write-Verbose -Message '- mounting virtual harddisk'
            Mount-VHD -Path $vhd.Path -ErrorAction SilentlyContinue
            $mountedVHD = Get-VHD -Path $vhd.Path
        }

        try {
            # retrieving the PS-drives appears to be needed for PS to be able to access the mounted VHD
            Get-PSDrive | Out-Null

            $mountedDrive = $mountedVHD | Get-Disk | Get-Partition | Get-Volume
            $drivePath = "$($mountedDrive.DriveLetter):\"
            Write-Verbose -Message "- mounted virtual harddisk as '$drivePath'"

            foreach ($fileToCopy in $FilesToCopy) {
                $destinationPath = Join-Path -Path $drivePath -ChildPath $fileToCopy.Destination
                Write-Verbose -Message "- copying '$($fileToCopy.Source)' to '$destinationPath'"
                if ($fileToCopy.Source) {
                    if (Test-Path -Path $fileToCopy.Source) {
                        if (Test-Path -Path $fileToCopy.Source.TrimEnd('*') -PathType Container) {
                            New-Item -Path $destinationPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
                        }
                        else {
                            New-Item -Path (Split-Path -Path $destinationPath) -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
                        }
                        Copy-Item -Path $fileToCopy.Source -Destination $destinationPath -Force -Recurse -ErrorAction SilentlyContinue
                    }
                    else {
                        Write-Host -Object "- Source '$($fileToCopy.Source)' not found" -ForegroundColor DarkYellow
                    }
                }
                elseif ($fileToCopy.Content) {
                    $destinationFolder = Split-Path -Path $destinationPath -Parent
                    if (-not (Test-Path -Path $destinationFolder -PathType Container)) {
                        New-Item -Path $destinationFolder -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
                    }
                    $fileToCopy.Content | Out-File -FilePath $destinationPath -Force -Confirm:$false -Encoding ascii
                }
                else {
                    Write-Host -Object "- Missing source and content; unable to copy file" -ForegroundColor DarkYellow
                }
            }
        }
        finally {
            Write-Verbose -Message '- dismounting virtual harddisk'
            Dismount-VHD -Path $vhd.Path -ErrorAction SilentlyContinue
        }
    }
}
