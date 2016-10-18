function Uninstall-LabVMTfsAgent {
    param (
        [string]$ServerUrl = $script:configuration.TfsServerUrl,
        [string]$AgentName = $script:configuration.AgentName,
        [string]$AgentFolder = $script:configuration.AgentFolder,
        [string]$WorkFolder = $script:configuration.WorkFolder
    )

    <#$serviceName = "vsoagent.$((New-Object -TypeName System.Uri -ArgumentList $ServerUrl).Host).$AgentName"
    if (Get-Service -Name $serviceName -ErrorAction SilentlyContinue) {
        $servicePath = ((Get-WmiObject -Class Win32_Service -Filter "Name='$serviceName'").PathName -split ' ' | Select-Object -First 1).Trim('"')
        if ($servicePath -and (Test-Path -Path $servicePath)) {
            $agentPath = Split-Path $servicePath.TrimEnd('vsoAgentService.exe')
            if($agentPath -and (Test-Path -Path $agentPath)) {
            }
        }
    }#>

    # unconfigure
    if (Test-Path -Path $AgentFolder -PathType Container) {
        Invoke-Expression -Command "$(Join-Path -Path $AgentFolder -ChildPath 'Agent\VsoAgent.exe') /Unconfigure /NoPrompt"
    }

    # remove working-folder
    if ($WorkFolder -and (Test-Path -Path $WorkFolder -PathType Container)) {
        Remove-Item $WorkFolder -Recurse -Force
    }

    # remove agent-folder
    if ($AgentFolder -and (Test-Path $AgentFolder -PathType Container)) {
        Remove-Item $AgentFolder -Recurse -Force
    }
}
