#Requires -Version 5.0
$configurationPath = 'C:\Setup\configuration.json'
if (Test-Path -Path $configurationPath -PathType Leaf) {
    $script:configuration = Get-Content $configurationPath | ConvertFrom-Json

    if (-not $script:configuration.AgentName) {
        $script:configuration |
            Add-Member -MemberType NoteProperty -Name AgentName -Value "Agent-$($env:COMPUTERNAME)"
    }

    if (-not $script:configuration.PoolName) {
        $script:configuration |
            Add-Member -MemberType NoteProperty -Name PoolName -Value 'default'
    }

    if (-not $script:configuration.AgentFolder) {
        $script:configuration |
            Add-Member -MemberType NoteProperty -Name AgentFolder -Value 'C:\Agent'
    }

    $script:domainCredential = New-Object -TypeName PSCredential -ArgumentList "Administrator@$($configuration.Domain.Name)",(ConvertTo-SecureString $configuration.Domain.AdministratorPassword -AsPlainText -Force)
}

Get-ChildItem -Path "$PSScriptRoot\Internal" -Filter '*.ps1' | ForEach-Object {
    . $_.FullName
}

Get-ChildItem -Path "$PSScriptRoot\Functions" -Filter '*.ps1' | ForEach-Object {
    . $_.FullName
}
