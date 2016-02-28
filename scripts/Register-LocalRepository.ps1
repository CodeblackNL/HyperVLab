
# change the path for the packages as desired
$packagesPath = 'D:\Packages'
# change the name of the repository as desired, but also change it in Publish-ToLocalRepository.ps1
$repositoryName = 'LocalDev'

# create the folder to hold the packages
New-Item -Path $packagesPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
# register the folder as a package-source
$packageSource = Get-PackageSource $repositoryName -ErrorAction SilentlyContinue
if ($packageSource) {
    Unregister-PackageSource $repositoryName | Out-Null
}
Register-PackageSource -Name $repositoryName -Location $packagesPath -ProviderName PowerShellGet -Trusted | Out-Null

# show the package-sources
Get-PackageSource
