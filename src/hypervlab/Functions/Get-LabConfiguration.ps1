#Requires -Version 4.0
<#
        .SYNOPSIS
        Retrieves the configuration of a complete lab-environment.
        .DESCRIPTION
        Retrieves the configuration of a complete lab-environment, as an array of machine-configurations.

        .PARAMETER Path
        The path to a lab-environment configuration-file.

        .EXAMPLE
        PS C:\> Get-LabConfiguration -Path 'D:\HyperV\Labs\CLDLAB\Configuration.ps1'
#>
function Get-LabConfiguration {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [parameter(Mandatory = $false)]
        [Hashtable]$Parameters
    )

    if (-not (Test-Path $Path -PathType Leaf)) {
        throw 'The provided path to the configuration file does not exist.'
    }
    
    switch ([System.IO.Path]::GetExtension($Path)) {
        '.ps1' {
            $configurationData = & $Path @Parameters
        }
        #'.json' { }
        default {
            throw 'The provided path does not reference a valid configuration file.'
        }
    }
    
    if (-not $configurationData) {
        throw 'Failed to load the lab-configuration from the provided path.'
    }

    $allNode = $configurationData | Where-Object { $_.MachineName -eq '*' }
    
    $labConfiguration = $configurationData | Where-Object { $_.MachineName -ne '*' } | ForEach-Object {
        return Convert-ToObject -InputObject (Merge-Dictionary -Primary $allNode -Secondary $_)
    }
    
    return $labConfiguration
}
