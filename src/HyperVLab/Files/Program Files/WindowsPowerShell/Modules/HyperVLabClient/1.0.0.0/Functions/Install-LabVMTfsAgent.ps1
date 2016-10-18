function Install-LabVMTfsAgent {
    param (
        [string]$ServerUrl = $script:configuration.TfsServerUrl,
        [PSCredential]$ServerCredential = $script:domainCredential,
        [string]$AgentName = $script:configuration.AgentName,
        [string]$AgentFolder = $script:configuration.AgentFolder,
        [string]$WorkFolder = $script:configuration.WorkFolder,
        [PSCredential]$AgentCredential,
        [string]$PoolName = $script:configuration.PoolName,
        [bool]$Force = $true
    )

    if (-not $AgentCredential -and $script:configuration.AgentUserName -and $script:configuration.AgentPassword) {
        $AgentCredential = New-Object -TypeName PSCredential -ArgumentList $script:configuration.AgentUserName,(ConvertTo-SecureString $script:configuration.AgentPassword -AsPlainText -Force)
    }

    Uninstall-LabVMTfsAgent -TfsServerUrl $TfsServerUrl -AgentName $AgentName -AgentFolder $AgentFolder -WorkFolder $WorkFolder

    try {
        # download agent-zip from TFS-instance
        $downloadPath = [System.IO.Path]::GetTempFileName()
        $url = "$($ServerUrl.TrimEnd('/'))/_apis/distributedtask/packages/agent"
        if ($ServerCredential) {
            Invoke-WebRequest -Uri $url -OutFile $downloadPath -Credential $ServerCredential
        }
        else {
            Invoke-WebRequest -Uri $url -OutFile $downloadPath
        }

        # unzip the agent-zip
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        if (Test-Path $AgentFolder -PathType Container) {
            Remove-Item $AgentFolder -Recurse -Force
        }
        [System.IO.Compression.ZipFile]::ExtractToDirectory($downloadPath, $AgentFolder)

        # configure the agent (https://www.visualstudio.com/docs/build/agents/windows)
        $configCommand = "$(Join-Path -Path $AgentFolder -ChildPath 'Agent\VsoAgent.exe') /Configure /NoPrompt"
        $configCommand += ' /RunningAsService'
        $configCommand += ' /Force'
        $configCommand += " /ServerUrl:$ServerUrl"
        $configCommand += " /Name:$AgentName"
        $configCommand += " /PoolName:$PoolName"
        if ($WorkFolder) {
            $configCommand += " /WorkFolder:$WorkFolder"
        }
        if ($AgentCredential) {
            $agentPassword = $AgentCredential.GetNetworkCredential().Password
            $configCommand += " /WindowsServiceLogonAccount:$($AgentCredential.UserName)"
            $configCommand += " /WindowsServiceLogonPassword:$AgentPassword"
        }

        Write-Host "Configuring TFS Agent with the following command: '$(if ($agentPassword) { $configCommand.Replace($agentPassword, '*******') } else { $configCommand })'"
        Invoke-Expression -Command $configCommand
    }
    finally {
        # clean up (delete downloaded agent-zip)
        if (Test-Path -Path $downloadPath) {
            Remove-Item -Path $downloadPath -Force
        }
    }
}
