#Requires -Version 5.0

function Publish-LabConfiguration {
    [CmdletBinding(DefaultParameterSetName = 'EnvironmentName_DscPullServer')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Environment_DscPullServer', ValueFromPipeline = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'Environment_ComputerName', ValueFromPipeline = $true)]
        [LabEnvironment[]]$Environment,
        [Parameter(Mandatory = $true, ParameterSetName = 'EnvironmentName_DscPullServer')]
        [Parameter(Mandatory = $true, ParameterSetName = 'EnvironmentName_ComputerName')]
        [string[]]$EnvironmentName,
        [Parameter(Mandatory = $true, ParameterSetName = 'Machine_DscPullServer', ValueFromPipeline = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'Machine_ComputerName', ValueFromPipeline = $true)]
        [LabMachine[]]$Machine,
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        [Parameter(Mandatory = $true, ParameterSetName = 'Environment_DscPullServer')]
        [Parameter(Mandatory = $true, ParameterSetName = 'EnvironmentName_DscPullServer')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Machine_DscPullServer')]
        [LabMachine]$DscPullServer,
        [Parameter(Mandatory = $true, ParameterSetName = 'Environment_ComputerName')]
        [Parameter(Mandatory = $true, ParameterSetName = 'EnvironmentName_ComputerName')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Machine_ComputerName')]
        [string]$ComputerName,
        [Parameter(Mandatory = $false, ParameterSetName = 'Environment_ComputerName')]
        [Parameter(Mandatory = $false, ParameterSetName = 'EnvironmentName_ComputerName')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Machine_ComputerName')]
        [PSCredential]$Credential
    )

    Process {
        if ($($PSCmdlet.ParameterSetName) -in 'EnvironmentName_DscPullServer','EnvironmentName_ComputerName') {
            if ($EnvironmentName) {
                $Environment = Get-LabEnvironment -Name $EnvironmentName
            }
            else {
                $Environment = Get-LabEnvironment
            }
        }

        if ($Environment) {
            $Machine = Get-LabMachine -Environment $Environment
        }

        if (-not $Machine) {
            return
        }

        if (-not $OutputPath) {
            $OutputPath = Join-Path -Path (Get-Location) -ChildPath 'PublishLabConfiguration'
        }
        if (-not (Test-Path -Path $OutputPath -PathType Container)) {
            New-Item -Path $OutputPath -ItemType Directory -Force
        }

        if ($DscPullServer) {
            $ComputerName = ($DscPullServer.NetworkAdapters.StaticIPAddress | Sort | Select -First 1)
            if (-not $ComputerName) {
                $ComputerName = $DscPullServer.Name
            }

            $Credential = New-Object -TypeName PSCredential -ArgumentList "$($DscPullServer.Name)\Administrator",$DscPullServer.AdministratorPassword
        }

        $groups = $Machine | Group -Property Environment
        
        foreach ($group in $groups) {
            $machines = $group.Group
            $e = $machines.Environment | Select -First 1
            Write-Verbose "Machines for environment '$($e.Name)': $($machines.Name)"

            $configurationFilePath = $e.ConfigurationFilePath
            $certificateFilePath = $e.CertificateFilePath
            if ($configurationFilePath -and $e.ConfigurationName) {
                if ($configurationFilePath.StartsWith('.')) {
                    $configurationFilePath = [System.IO.Path]::GetFullPath((Join-Path -Path (Split-Path -Path $e.Path -Parent) -ChildPath $configurationFilePath))
                }
                if ($certificateFilePath.StartsWith('.')) {
                    $certificateFilePath = [System.IO.Path]::GetFullPath((Join-Path -Path (Split-Path -Path $e.Path -Parent) -ChildPath $certificateFilePath))
                }

                if (Test-Path -Path $configurationFilePath -PathType Leaf) {
                    Write-Verbose "Loading configuration"
                    try {
                        . $configurationFilePath
                    }
                    catch {
                        Write-Error $_
                    }

                    Write-Verbose "Preparing configuration-data"
                    $configurationData = @{
                        AllNodes = @($machines |% {
                            #$m = Convert-PSObjectToHashtable -InputObject $_
                            $m = $_.ToHashtable()
                            $m.NodeName = $_.Name
                            $m.PSDscAllowDomainUser = $true
                            $m
                        })
                    }

                    if ($certificateFilePath -and (Test-Path -Path $certificateFilePath -PathType Leaf)) {
                        $configurationData.AllNodes += @{
                            NodeName = '*'
                            CertificateFile = $certificateFilePath
                            Thumbprint = $e.CertificateThumbprint
                        }
                    }
                    else {
                        $configurationData.AllNodes += @{
                            NodeName = '*'
                            PSDscAllowPlainTextPassword = $true
                        }
                    }

                    Write-Verbose "Generating MOF's"
                    . $e.ConfigurationName -ConfigurationData $configurationData -OutputPath $OutputPath | Out-Null

                    Write-Verbose "Finding imported DSC-modules in configuration"
                    $content = get-content -Path $configurationFilePath -Encoding Ascii
                    $moduleNames = $content |% {
                        if ($_ -match 'Import[–-]DscResource [–-]ModuleName ''?(?<ModuleName>\w*)''?') {
                            $Matches.ModuleName
                        }
                    }
                    Write-Verbose "Found imported DSC-modules: '$moduleNames'"

                    # publish MOF's and modules
                    Publish-DscModuleAndMof -Path $OutputPath -ModuleNames $moduleNames -ComputerName $ComputerName -Credential $Credential

                    Write-Verbose "Finished machines for environment '$($group.Name)'"
                }
                else {
                    Write-Verbose "Configuration-file not present; skipping machines for environment '$($group.Name)'"
                }
            }
            else {
                Write-Verbose "Configuration-file not specified; skipping machines for environment '$($group.Name)'"
            }
        }
    }
}
