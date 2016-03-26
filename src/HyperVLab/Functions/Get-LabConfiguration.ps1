#Requires -Version 5.0
<#
.SYNOPSIS
    Retrieves the configuration of a complete lab-environment.
.DESCRIPTION
    Retrieves the configuration of a complete lab-environment, as an array of machine-configurations.

.PARAMETER Path
    The path to a lab-environment configuration-file.
.PARAMETER Parameters
    The parameters to pass to the lab-environment configuration-file.

.EXAMPLE
    PS C:\> Get-LabConfiguration -Path 'D:\HyperV\Labs\CLDLAB\Configuration.ps1'

.NOTES
    Copyright (c) 2016 Jeroen Swart. All rights reserved.
#>
function Get-LabConfiguration {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,
        [parameter(Mandatory = $false, Position = 1)]
        [Hashtable]$Parameters
    )

    $Path = [System.IO.Path]::GetFullPath($Path)

    if (-not (Test-Path -Path $Path -PathType Leaf)) {
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

    $labPath = Split-Path -Path $Path -Parent
    if ((Split-Path -Path $labPath -Leaf) -eq 'configuration') {
        $labPath = Split-Path -Path $labPath -Parent
    }
    
    $allNode = $configurationData | Where-Object { $_.MachineName -eq '*' }
    
    $labConfiguration = $configurationData | Where-Object { $_.MachineName -ne '*' } | ForEach-Object {
        $machineConfiguration = Convert-ToObject -InputObject (Merge-Dictionary -Primary $allNode -Secondary $_)
        $machineConfiguration | Add-Member -MemberType NoteProperty -Name LabPath -Value $labPath
        $machineConfiguration | Add-Member -MemberType NoteProperty -Name ConfigurationPath -Value $Path
        return $machineConfiguration
    }
    
    return $labConfiguration
}
