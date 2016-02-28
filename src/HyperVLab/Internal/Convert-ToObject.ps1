function Convert-ToObject {
    param (
        [Hashtable]$InputObject
    )
    
    if ($InputObject) {
        $outputObject = New-Object PSCustomObject
        
        $InputObject.Keys | ForEach-Object {
            $value = $InputObject[$_]
            if($value -is [Hashtable]) {
                $outputObject | Add-Member -MemberType NoteProperty -Name $_ -Value (Convert-ToObject -InputObject $value)
            }
            else {
                $outputObject | Add-Member -MemberType NoteProperty -Name $_ -Value $value
            }
        }
    }
    
    return $outputObject
}