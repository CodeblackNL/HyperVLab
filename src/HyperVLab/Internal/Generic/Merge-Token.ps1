#Requires -Version 5.0

function Merge-Token {
    param (
        [PSCustomObject]$InputObject,
        [Hashtable]$Tokens
    )

    function MergeToken {
        param (
            [string]$Value,
            [Hashtable]$Tokens
        )

        if ($Value -and $Value -match '\{(?<token>.*)\}') {
            foreach ($match in $Matches) {
                $Value = $Value.Replace("{$($match.token)}", $Tokens.($match.token))
            }
        }

        return $Value
    }

    foreach ($property in $InputObject.GetType().GetProperties()) {
        $value = $InputObject.($property.Name)

        if ($property.PropertyType.Name -eq 'string') {
            $InputObject.($property.Name) = MergeToken -Value $value -Tokens $Tokens
        }
        elseif ($value -is [System.Collections.Hashtable]) {
            foreach ($key in @($value.Keys)) {
                $value.$key = MergeToken -Value $value.$key -Tokens $Tokens
            }
        }
        elseif ($value -is [System.Collections.IEnumerable]) {
            foreach ($item in $value) {
                Merge-Token -InputObject $item -Tokens $Tokens
            }
        }
    }
}
