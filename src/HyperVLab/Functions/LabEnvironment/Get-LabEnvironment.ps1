#Requires -Version 5.0

function Get-LabEnvironment {
    [CmdletBinding(DefaultParameterSetName = 'EnvironmentName')]
    param (
        [Parameter(Mandatory = $false, Position = 0, ParameterSetName = 'EnvironmentName')]
        [string[]]$Name,
        [Parameter(Mandatory = $true, ParameterSetName = 'EnvironmentPath')]
        [string[]]$Path
    )

    $filePaths = @()
    if ($($PSCmdlet.ParameterSetName) -eq 'EnvironmentName') {
        $environmentsFilePath = Join-Path -Path $script:configurationPath -ChildPath 'environments.json'
        if (Test-Path -Path $environmentsFilePath -PathType Leaf) {
            $environments = Get-Content -Path $environmentsFilePath -Raw | ConvertFrom-Json | Convert-PSObjectToHashtable
            foreach ($environmentName in $environments.Keys) {
                if (-not $Name -or $Name -contains $environmentName) {
                    $filePaths += $environments.$environmentName
                }                
            }
        }
    }
    else {
        foreach ($p in $Path) {
            $filePaths += $p
        }
    }

    foreach ($filePath in $filePaths) {
        $environmentFilePath = $filePath
        Write-Verbose "Processing path '$environmentFilePath'"

        if (Test-Path -Path $environmentFilePath -PathType Container) {
            Write-Verbose "path '$environmentFilePath' is folder, assuming filename is missing"
            $environmentFilePath = Join-Path -Path $environmentFilePath -ChildPath 'environment.json'
        }

        if (Test-Path -Path $environmentFilePath -PathType Leaf) {
            Write-Verbose "file '$environmentFilePath' found"
            $environment = Convert-FromJsonObject -InputObject (Get-Content -Path $environmentFilePath -Raw | ConvertFrom-Json) -TypeName 'LabEnvironment'
            if (-not $Name -or $Name -contains $environment.Name) {
                $environment.Path = $environmentFilePath

                if ($environment.TokensFilePath) {
                    $tokensFilePath = $environment.TokensFilePath
                    if ($tokensFilePath.StartsWith('.')) {
                        $tokensFilePath = [System.IO.Path]::GetFullPath((Join-Path -Path (Split-Path -Path $environment.Path -Parent) -ChildPath $tokensFilePath))
                    }

                    if (Test-Path -Path $tokensFilePath -PathType Leaf) {
                        try {
                            $tokens = Get-Content -Path $tokensFilePath -Raw | ConvertFrom-Json | Convert-PSObjectToHashtable
                            Merge-Token -InputObject $environment -Tokens $tokens
                        }
                        catch {
                        }
                    }
                }

                Write-Output $environment
            }
        }
    }
}


