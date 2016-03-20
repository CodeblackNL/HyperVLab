#Requires -Version 4.0

function Convert-ToObject {
    param (
        [Hashtable]$InputObject
    )
    
    if ($InputObject) {
        $outputObject = New-Object -TypeName PSCustomObject
        
        $InputObject.Keys | ForEach-Object {
            $value = $InputObject[$_]
            if($value -is [Array]) {
                $outputObject `
                    | Add-Member -MemberType NoteProperty -Name $_ -Value ($value `
                    | ForEach-Object { Convert-ToObject -InputObject $_ })
            }
            elseif($value -is [Hashtable]) {
                $outputObject | Add-Member -MemberType NoteProperty -Name $_ -Value (Convert-ToObject -InputObject $value)
            }
            else {
                $outputObject | Add-Member -MemberType NoteProperty -Name $_ -Value $value
            }
        }
    }
    
    return $outputObject
}