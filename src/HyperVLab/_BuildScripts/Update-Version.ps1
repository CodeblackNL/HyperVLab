<#
.SYNOPSIS
    Script for updating the version as part of a TFS build.
.DESCRIPTION
    Script for updating the version as part of a TFS build; updates version attributes before building.

.PARAMETER  Version
    Specifies the version to use. May contain the following tokens :'YYYY', 'YY', 'M', 'D', 'J' and 'B'.
.PARAMETER  VersionPattern
    Specifies the version, or pattern, for the nuget-packages.
    Depending on the provided version (either through the Version or BuildNumber parameters)
    the default is '#.#.#.#' (.NET) or '#.#.###' (SemVer).
.PARAMETER  Disabled
    Convenience option so you can debug this script or disable it in your build definition
    without having to remove it from the 'Pre-build script path' build process parameter.
#>
[CmdletBinding()]
param (
)


set-alias ?: Invoke-Ternary -Option AllScope -Description "PSCX filter alias"
filter Invoke-Ternary ([scriptblock]$decider, [scriptblock]$ifTrue, [scriptblock]$ifFalse) {
    if (& $decider) { 
        & $ifTrue
    } else { 
        & $ifFalse 
    }
}

function Update-Version {
<#
    .SYNOPSIS
        Updates the version-attributes in source-code.
    .DESCRIPTION
        Updates the version-attributes, using a base-version and patterns.
        The base-version can be provided, or is retrieved from the build-number.
        Versions may be specified in a .Net (0.0.0.0) or SemVer (semver.org) format.

        For example, if the 'Build number format' build process parameter is
        $(BuildDefinitionName)_$(Year:yyyy).$(Month).$(DayOfMonth)$(Rev:.r),
        then your build numbers come out like this: "HelloWorld_2014.11.08.2".
        This function would then apply version 2014.11.8.2.

    .PARAMETER  SourcesDirectory
        Specifies the root-directory containing the source-files.
    .PARAMETER  AssemblyVersionFilePattern
        Specifies the pattern to use for finding source-files containing the version-attributes. Default is 'AssemblyInfo.*'.
    .PARAMETER  BuildNumber
        Specifies the build-number from which to take the version-number, if available.
        This parameter is ignored if the Version parameter is provided.
    .PARAMETER  Version
        Specifies the version to use. May contain the following tokens :'YYYY', 'YY', 'M', 'D', 'J' and 'B'.
    .PARAMETER  AssemblyVersionPattern
        Specifies the version, or pattern, for the assembly-version.
        Depending on the provided version (either through the Version or BuildNumber parameters)
        the default is '#.#.#.#' (.NET) or '#.#.#.0' (SemVer).
    .PARAMETER  FileVersionPattern
        Specifies the version, or pattern, for the assembly-file-version.
        Depending on the provided version (either through the Version or BuildNumber parameters)
        the default is '#.#.#.#' (.NET) or '#.#.#.0' (SemVer).
    .PARAMETER  ProductVersionPattern
        Specifies the version, or pattern, for the assembly-informational-version.
        Depending on the provided version (either through the Version or BuildNumber parameters)
        the default is '#.#.#.#' (.NET) or '#.#.###' (SemVer).
    .PARAMETER  PackageVersionPattern
        Specifies the version, or pattern, for the nuget-packages.
        Depending on the provided version (either through the Version or BuildNumber parameters)
        the default is '#.#.#.#' (.NET) or '#.#.###' (SemVer).
    .PARAMETER  WhatIf
        Specifies that no changes should be made.
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$SourcesDirectory,
        [Parameter(Mandatory = $true)]
        [string]$BuildNumber
    )

    if ($BuildNumber -match '(?<major>\d+)\.(?<minor>\d+)\.(?<build>\d+)\.(?<revision>\d+)') {
        $version = "$($Matches.major).$($Matches.minor).$($Matches.build).$($Matches.revision)"
    }
    else {
        $version = '0.0.0.0'
    }

    Write-Verbose "Version: $version"

    $files = @()
    $files += Get-ChildItem -Path $sourcesDirectory -Recurse -Include "*.nuspec"
    $files += Get-ChildItem -Path $sourcesDirectory -Recurse -Include "HyperVLab.psd1"

    if($files) {
        Write-Verbose "Will apply $version to $($files.count) files."

        foreach ($file in $files) {
			Set-ItemProperty -Path $file.FullName -Name IsReadOnly -Value $false

            $fileExtension = $file.Extension.ToLowerInvariant()
            if ($fileExtension -eq ".nuspec") {
                [xml]$xmlContent = Get-Content -Path $file.FullName

                Write-Verbose "Replacing version-token in '$($file.FullName)'."
                $xmlContent.package.metadata.version = $version
                $xmlContent.Save($file)
            }
            elseif ($fileExtension -eq ".psd1") {
                $fileContent = @()
                $update = $false
                foreach ($line in @(Get-Content -Path $file)) {
                    if ($line -match "ModuleVersion(\W)*=(\W)*['""](?<version>.*)['""]") {
                        $fileContent += $line.Replace(($Matches.version), $version)
                        $update = $true
                    }
                    else {
                        $fileContent += $line
                    }
                }

                if ($update) {
                    Write-Verbose "Replacing version-token in '$($file.FullName)'."
                    Set-Content -Path $file.FullName -Value $fileContent
                }
            }
            else {
                $fileContent = Get-Content -Path $file -Raw
                if ($fileContent.Contains('{version}')) {
                    Write-Verbose "Replacing version-token in '$($file.FullName)'."
                    $fileContent = $fileContent.Replace('{version}', $version)
                    Set-Content -Path $file.FullName -Value ($fileContent)
                }
            }

            Write-Verbose "$($file.FullName) - version applied"
        }
    }
    else {
        Write-Warning "No files found."
    }
}

# retrieve the necessary environment-variables, provided by the build-service (https://www.visualstudio.com/docs/build/define/variables)
$buildNumber = $env:BUILD_BUILDNUMBER
$sourcesDirectory = $env:BUILD_SOURCESDIRECTORY

if (-not $Disabled) {
    Update-Version -SourcesDirectory $sourcesDirectory `
                   -BuildNumber $buildNumber `
                   -Verbose:$VerbosePreference
}
else {
    Write-Verbose "Script disabled; update of version skipped"
}