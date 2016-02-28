#Requires -Version 4.0

Get-ChildItem "$PSScriptRoot\Internal" -Filter '*.ps1' |% {
    . $_.FullName
}

Get-ChildItem "$PSScriptRoot\Functions" -Filter '*.ps1' |% {
    . $_.FullName
}


<# DONE:

Get-LabConfiguration
Get-LabVMConfiguration
Get-LabOSImage
New-LabOSImage

#>
<# TODO:

New-LabConfiguration
  create a new lab-configuration-file from a template, some details will be filled in from provided parameters

New-LabVM
  create a new lab-VM based on a machine-configuration

Remove-LabVM
  delete an existing lab-VM, remove it from the AD, and clean up all VM-files

Enter-LabVMSession
  enter a remote session, based on machine-configuration

New-Lab
  create all machines for a lab based on a lab-configuration





#>
