#Requires -Version 4.0
<#
.SYNOPSIS
    Retrieves the configuration of a single machine in a lab-environment.
.DESCRIPTION
    Retrieves the configuration of a single machine in a lab-environment.

.PARAMETER Path
    The path to a lab-environment configuration-file.
.PARAMETER Parameters
    The parameters to pass to the lab-environment configuration-file.
.PARAMETER LabConfiguration
    An object describing a lab-environment configuration.
.PARAMETER MachineName
    The name of the machine to retrieve the configuration for.

.EXAMPLE
    PS C:\> Get-LabConfiguration -Path 'D:\HyperV\Labs\CLDLAB\Configuration.ps1' -MachineName 'CLDLAB-DC'
.EXAMPLE
    PS C:\> Get-LabConfiguration -LabConfiguration $labConfiguration -MachineName 'CLDLAB-DC'

.NOTES
    Copyright (c) 2016 Jeroen Swart. All rights reserved.
#>
function Get-LabVMConfiguration {
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Path')]
        [string]$Path,
        [Parameter(Mandatory = $false, ParameterSetName = 'Path')]
        [Hashtable]$Parameters,
        [Parameter(Mandatory = $true, ParameterSetName = 'Configuration')]
        [PSCustomObject]$LabConfiguration,
        [Parameter(Mandatory = $true)]
        [string]$MachineName
    )

    if ($Path) {
        if (-not (Test-Path -Path $Path -PathType Leaf)) {
            throw 'The provided path to the configuration file does not exist.'
        }

        $LabConfiguration = Get-LabConfiguration -Path $Path -Parameters $Parameters
    }

    $machineConfiguration = $LabConfiguration | Where-Object { $_.MachineName -eq $MachineName }
    if (-not $machineConfiguration) {
        throw "The lab-configuration does not contain a configuration for machine '$MachineName'"
    }
    
    $machineConfiguration
}
