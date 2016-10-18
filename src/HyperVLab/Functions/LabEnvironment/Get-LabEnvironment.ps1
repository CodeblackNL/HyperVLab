#Requires -Version 5.0

function Get-LabEnvironment
{
    [CmdletBinding(DefaultParameterSetName = 'EnvironmentName')]
    param (
        [Parameter(Mandatory = $false, Position = 0, ParameterSetName = 'EnvironmentName')]
        [string[]]$Name,
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'EnvironmentPath')]
        [string]$Path
    )

    if ($($PSCmdlet.ParameterSetName) -eq 'EnvironmentName') {
        $folderPath = Join-Path -Path $script:configurationPath -ChildPath 'environments'

        if (Test-Path -Path $folderPath -PathType Container)
        {
            foreach ($file in (Get-ChildItem -Path $folderPath -Filter '*.json'))
            {
                if (-not $Name -or @($Name |? { [System.IO.Path]::GetFileNameWithoutExtension($file.Name) -like $_ }).Length -gt 0)
                {
                    Write-Output (Convert-FromJsonObject `
                        -InputObject (Get-Content -Path $file.FullName -Raw | ConvertFrom-Json) `
                        -TypeName 'LabEnvironment')
                }
            }
        }
    }
    else {
        if (Test-Path -Path $Path -PathType Leaf)
        {
            Write-Output (Convert-FromJsonObject `
                -InputObject (Get-Content -Path $Path -Raw | ConvertFrom-Json) `
                -TypeName 'LabEnvironment')
        }
    }
}