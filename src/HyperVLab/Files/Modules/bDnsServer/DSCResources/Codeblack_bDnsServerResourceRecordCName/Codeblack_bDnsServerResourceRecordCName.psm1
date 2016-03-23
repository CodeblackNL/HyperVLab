Import-Module $PSScriptRoot\..\Helper.psm1 -Verbose:$false

# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData @"
CheckingRecordMessage        = Checking CName record with name {0} in zone {1} ...
TestRecordMessage            = CName record is {0} and it should be {1} 
RemovingRecordMessage        = Removing CName record ...
DeleteRecordMessage          = CName record {0} is now absent

AddingRecordMessage          = Adding CName record ...
NewRecordMessage             = CName record {0} is now present
"@
}

function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory)]
		[String]$Name,

		[parameter(Mandatory)]
		[String]$HostNameAlias,

		[parameter(Mandatory)]
		[String]$ZoneName
	)

#region Input Validation

    # Check for DnsServer module/role
    Assert-Module -moduleName DnsServer

#endregion

	$record = Get-DnsServerResourceRecord -ZoneName $ZoneName | Where { $_.HostName -eq $Name }
    if($record)
    {
        $Ensure = "Present"
    }
    else
    {
        $Ensure = "Absent"
    }

    @{
		Name = $record.HostName
		Ensure = $Ensure
		HostNameAlias = $record.RecordData.HostNameAlias
        ZoneName = $ZoneName
	}
}

function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory)]
		[String]$Name,

		[parameter(Mandatory)]
		[String]$HostNameAlias,

		[parameter(Mandatory)]
		[String]$ZoneName,

		[ValidateSet("Present","Absent")]
		[String]$Ensure = "Present"
	)

    if($PSBoundParameters.ContainsKey('Debug')){$null = $PSBoundParameters.Remove('Debug')}
    Validate-ResourceProperties @PSBoundParameters -Apply
}

function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory)]
		[String]$Name,

		[parameter(Mandatory)]
		[String]$HostNameAlias,

		[parameter(Mandatory)]
		[String]$ZoneName,

		[ValidateSet("Present","Absent")]
		[String]$Ensure = "Present"
	)

#region Input Validation

    # Check for DnsServer module/role
    Assert-Module -moduleName DnsServer

#endregion

    if($PSBoundParameters.ContainsKey('Debug')){$null = $PSBoundParameters.Remove('Debug')}
    Validate-ResourceProperties @PSBoundParameters
}

#region Helper Functions
function Validate-ResourceProperties
{
    [CmdletBinding()]
    param
	(
		[parameter(Mandatory)]
		[String]$Name,

		[String]$HostNameAlias,

		[String]$ZoneName,

		[ValidateSet("Present","Absent")]
		[String]$Ensure = "Present",

        [Switch]$Apply
	)

    $recordMessage = $($LocalizedData.CheckingRecordMessage) -f $Name,$ZoneName 
    Write-Verbose -Message $recordMessage

	$record = Get-DnsServerResourceRecord -ZoneName $ZoneName | Where { $_.HostName -eq $Name }

    # Found CName record
    if($record)
    {
        $testRecordMessage = $($LocalizedData.TestRecordMessage) -f "present", $Ensure
        Write-Verbose -Message $testRecordMessage

        # If CName record should be absent
        if($Ensure -eq "Absent")
        {
            if($Apply)
            {
                $removingRecordMessage = $LocalizedData.RemovingRecordMessage
                Write-Verbose -Message $removingRecordMessage

				Remove-DnsServerResourceRecord -ZoneName $ZoneName -RRType "CName" -Name $Name -Force -Confirm:$false

                $deleteRecordMessage = $($LocalizedData.DeleteRecordMessage) -f $Name
                Write-Verbose -Message $deleteRecordMessage
            }
            else
            {
                return $false
            }
        } # end ensure -eq Absent
        else
        {
            if(-not $Apply)
            {
                return $true
            }
        } # end ensure -eq Present

    } # end found CName record
    
    # Not found CName Record
    else
    {
        $testRecordMessage = $($LocalizedData.TestRecordMessage) -f "absent", $Ensure
        Write-Verbose -Message $testRecordMessage

        if($Ensure -eq "Present")
        {
            if($Apply)
            {
                $addingRecordMessage = $LocalizedData.AddingRecordMessage
                Write-Verbose -Message $addingRecordMessage

				Add-DnsServerResourceRecordCName -Name $Name -HostNameAlias $HostNameAlias -ZoneName $ZoneName
                
                $newRecordMessage = $($LocalizedData.NewRecordMessage) -f $Name
                Write-Verbose -Message $newRecordMessage
            }
            else
            {
                return $false
            }
        } # end ensure -eq Present
        else
        {
            if(-not $Apply)
            {
                return $true
            }
        } # end ensure -eq Absent
    }
}
#endregion

Export-ModuleMember -Function *-TargetResource