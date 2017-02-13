#Requires -Version 5.0

function Set-LabEnvironment {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'TODO: implement ShouldProcess')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'TODO: implement ShouldProcess')]
    [CmdletBinding(DefaultParameterSetName = 'EnvironmentName')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'EnvironmentName')]
        [string[]]$Name,
        [Parameter(Mandatory = $true, ParameterSetName = 'EnvironmentObject', ValueFromPipeline = $true)]
        [LabEnvironment[]]$Environment,

        [Parameter(Mandatory = $false)]
        [string]$MachinesPath,
        [Parameter(Mandatory = $false)]
        [string]$FilesPath,
        [Parameter(Mandatory = $false)]
        [string]$ConfigurationFilePath,
        [Parameter(Mandatory = $false)]
        [string]$ConfigurationName,
        [Parameter(Mandatory = $false)]
        [Hashtable]$Properties,
        [Parameter(Mandatory = $false)]
        [switch]$PassThru
    )

    Process {
        if ($($PSCmdlet.ParameterSetName) -eq 'EnvironmentName') {
            if ($Name) {
                $Environment = Get-LabEnvironment -Name $Name
            }
            else {
                $Environment = Get-LabEnvironment
            }
        }

        if (-not $Environment) {
            return
        }

        foreach ($e in $Environment) {
            $labFilePath = Join-Path -Path $e.Path -ChildPath 'environment.json'
            if (-not (Test-Path -Path $labFilePath -PathType Leaf)) {
                throw "Unable to locate environment-file '$labFilePath'."
            }

            $update = $false
            $parameters = 'MachinesPath','FilesPath','ConfigurationFilePath','ConfigurationName'
            foreach ($parameter in $parameters) {
                if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey($parameter) -and $e.$parameter -ne $PSCmdlet.MyInvocation.BoundParameters.$parameter) {
                    $e.$parameter = $PSCmdlet.MyInvocation.BoundParameters.$parameter
                    $update = $true
                }
            }
            if ($Properties) {
                if (-not $e.Properties) {
                    $e.Properties = {}
                }
                foreach ($key in $Properties.Keys) {
                    if ($null -eq $Properties.$key) {
                        $e.Properties.$key = $Properties.$key
                    }
                    else {
                        $e.Properties.Remove($key)
                    }
                    $update = $true
                }
            }

            if ($update) {
                $e | ConvertTo-Json -Depth 9 | Out-File -FilePath $labFilePath
            }
        }

        if ($PassThru.IsPresent) {
            return $Environment
        }
    }
}