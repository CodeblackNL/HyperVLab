#
# Module manifest for module 'HyperVLab'
#

@{
 
# Author of this module
Author = 'Jeroen Swart'

# Script module or binary module file associated with this manifest.
RootModule = 'HyperVLab.psm1'

# Version number of this module.
ModuleVersion = '0.0.0.0'

# ID used to uniquely identify this module
GUID = 'bbd0a9d3-8308-4e5b-9762-1cbc057dd1c4'

# Company or vendor of this module
CompanyName = 'www.codeblack.nl'

# Copyright statement for this module
Copyright = '(c) Jeroen Swart 2016. All rights reserved.'

# Description of the functionality provided by this module
Description = 'HyperVLab provides functions for managing a Hyper-V Lab.'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '5.0'

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
#RequiredModules = @(@{ModuleName='PowerShellGet'; ModuleVersion='0.0.0.1'})
#RequiredModules = 'PowerShellGet'

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
#TypesToProcess = @('ScriptAnalyzer.types.ps1xml')

# Format files (.ps1xml) to be loaded when importing this module
#FormatsToProcess = @('ScriptAnalyzer.format.ps1xml')

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module
FunctionsToExport = '*'
<#FunctionsToExport = @(
    'Get-LabConfiguration',
    'Get-LabVMConfiguration',
    'New-LabVM',
    'Remove-LabVM',
    'Enter-LabVMSession'
)
#>

# Cmdlets to export from this module
#CmdletsToExport = @('Get-LabVM','New-LabVM')
CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module
AliasesToExport = '*'

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess
PrivateData = @{
    PSData = @{
        ProjectUri = 'https://github.com/CodeblackNL/HyperVLab'
        LicenseUri = 'https://github.com/CodeblackNL/HyperVLab/blob/master/LICENSE'
        Tags = @('Hyper-V', 'Lab', 'VM')


#        IconUri = ''
#        ReleaseNotes = ''
#        ExternalModuleDependencies = @(@{ModuleName='PowerShellGet'; ModuleVersion='0.0.0.1'})
#        ExternalModuleDependencies = 'PowerShellGet'
    }
}

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''
}
