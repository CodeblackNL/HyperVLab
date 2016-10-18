function New-UnattendXml {
    param (
        [string]$TemplateFilePath,
        [Hashtable]$Property,
        [string]$Destination
    )

    function RecurseNode {
        param (
            $XmlNode,
            [Hashtable]$Property
        )

        $childElements = @($XmlNode.ChildNodes |? { $_.NodeType -eq 'Element' })
        if ($childElements.Length -eq 0) {
            $regex = '({(.*)})'
            if ($XmlNode.InnerText -match $regex) {
                $propertyName = $XmlNode.InnerText -replace $regex,'$2'
                $XmlNode.InnerText = $Property.$propertyName
                if (-not $XmlNode.InnerText) {
                    $XmlNode.ParentNode.RemoveChild($XmlNode) | Out-Null
                }
            }
        }
        elseif ($XmlNode.ChildNodes) {
            foreach ($childNode in @($XmlNode.ChildNodes)) {
                RecurseNode -XmlNode $childNode -Property $Property
            }
        }
    }

    [xml]$unattendXml = Get-Content -Path $TemplateFilePath

    RecurseNode -XmlNode $unattendXml -Property $Property

    if ($Destination) {
        $unattendXml.Save($Destination)
    }
    else {
        return $unattendXml.OuterXml
    }
}
