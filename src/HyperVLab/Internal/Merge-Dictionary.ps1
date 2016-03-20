#Requires -Version 4.0

function Merge-Dictionary {
    param (
        [Parameter(Mandatory = $true)]
        [Hashtable]$Primary,
        [Parameter(Mandatory = $false)]
        [Hashtable]$Secondary
    )

    $merged = @{}

    foreach ($key in $Primary.Keys) {
        $value = $Primary[$key]
        if ($value -and $value.GetType().IsArray) {
            if ($value -is [Hashtable]) {
                $value = $value.Clone()
            }
            elseif ($value -is [Array]) {
                $value = $value | Where-Object { $_.Clone() }
            }
        }

        $merged[$key] = $value
    }

    if ($Secondary) {
        foreach ($key in $Secondary.Keys) {
            $secondaryValue = $Secondary[$key]
                
            if(-not $merged.Contains($key)) {
                if ($secondaryValue -and !!($secondaryValue.GetType().GetInterfaces() | Where-Object { $_.FullName -eq 'System.Collections.IDictionary' })) {
                    $secondaryValue = $secondaryValue.Clone()
                }
                
                $merged[$key] = $secondaryValue
            }
            else {
                $primaryValue = $merged[$key]

                if ($secondaryValue -and $primaryValue.GetType() -eq $secondaryValue.GetType()) {
                    if ($secondaryValue -is [Hashtable]) {
                        $secondaryValue = Merge-Dictionary -Primary $primaryValue -Secondary $secondaryValue
                    }
                    elseif ($secondaryValue -is [Array]) {
                        $primaryArray = $primaryValue | ForEach-Object { $_.Clone() }
                        $secondaryArray = $secondaryValue | ForEach-Object {
                            if (-not $_.Name) {
                                $_.Clone()
                            }
                            else {
                                $name = $_.Name
                                $existingValue = $primaryArray | Where-Object { $_.Name -eq $name }
                                if ($existingValue) {
                                    $index = $primaryArray.IndexOf($existingValue)
                                    $primaryArray[$index] = Merge-Dictionary -Primary $existingValue -Secondary $_
                                }
                                else {
                                    $_.Clone()
                                }
                            }
                        } | Where-Object { $_ -ne $null }

                        $secondaryValue = New-Object -TypeName object[] -ArgumentList ($primaryArray.Length + $secondaryArray.Length)
                        [Array]::Copy($primaryArray, $secondaryValue, $primaryArray.Length)
                        if ($secondaryArray) {
                            [Array]::Copy($secondaryArray, 0, $secondaryValue, $primaryArray.Length, $secondaryArray.Length)
                        }
                    }
                }
                `
                $merged[$key] = $secondaryValue
            }
        }
    }
    
    return $merged

}
