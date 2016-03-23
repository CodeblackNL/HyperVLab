Import-Module $PSScriptRoot\..\Helper.psm1 -Verbose:$false

# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData @'
CheckCompletionMessage    = Checking DHCP configuration completion ...
TestCompletionMessage     = DHCHP configuration is not completed
CompletingMessage         = Completing DHCP configuration ...
CompletedMessage          = DHCP configuration is now completed
TestCompletedMessage      = DHCHP configuration is completed and cannot be reversed
'@
}

function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
        [String]$MachineName
	)

#region Input Validation

    # Check for DhcpServer module/role
    Assert-Module -moduleName DHCPServer
    
#endregion Input Validation

    $ensure = 'Absent'
    try
    {
		if ((Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\ServerManager\Roles\12 -Name ConfigurationState).ConfigurationState -eq 2) {

            # !!(Get-DhcpServerInDC | Where { $_.DnsName -eq $dnsHostname })

			$ensure = 'Present'
		}
    }
    catch
    {
    }

	@{
		MachineName = $MachineName
		Ensure = $ensure
	}
}

function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
        [String]$MachineName,

		[ValidateSet('Present','Absent')]
		[String]$Ensure = 'Present'
	)

#region Input Validation
    
    # Check for DhcpServer module/role
    Assert-Module -moduleName DHCPServer

#endregion Input Validation

    # Remove $Debug from PSBoundParameters and pass it to validate-properties helper function
    If($PSBoundParameters['Debug']) {$null = $PSBoundParameters.Remove('Debug')}

    Validate-ResourceProperties @PSBoundParameters -Apply
}

function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
        [String]$MachineName,

		[ValidateSet('Present','Absent')]
		[String]$Ensure = 'Present'
	)

#region Input Validation

    # Check for DhcpServer module/role
    Assert-Module -moduleName DHCPServer

#endregion Input Validation

    # Remove $Debug from PSBoundParameters and pass it to validateProperties helper function
    If($PSBoundParameters['Debug']) {$null = $PSBoundParameters.Remove('Debug')}

    Validate-ResourceProperties @PSBoundParameters
}

#region Helper function

# Internal function to validate dhcpOptions properties
function Validate-ResourceProperties
{
    [CmdletBinding()]
    param
    (
		[parameter(Mandatory = $true)]
        [String]$MachineName,

		[ValidateSet('Present','Absent')]
        [String]$Ensure = 'Present',

        [switch]$Apply
    )

    $checkCompletionMessage = $($LocalizedData.CheckCompletionMessage)
    Write-Verbose -Message $checkCompletionMessage
    
	try
	{
		$configurationState = (Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\ServerManager\Roles\12 -Name ConfigurationState).ConfigurationState
	}
	catch { }

	if ($configurationState -eq 2) {
        # If completion should be absent
        if($Ensure -eq "Absent")
        {
            if($Apply)
            {
                $testCompletedMessage = $LocalizedData.TestCompletedMessage
                Write-Verbose -Message $testCompletedMessage
            }
            else
            {
                return $true	# $false
            }
        } # end ensure -eq Absent
        else
        {
            if(-not $Apply)
            {
                return $true
            }
        } # end ensure -eq Present
	}
	else
	{
        $testCompletionMessage = $($LocalizedData.TestCompletionMessage)
        Write-Verbose -Message $testCompletionMessage

        if($Ensure -eq "Present")
        {
            if($Apply)
            {
                $completingMessage = $LocalizedData.CompletingMessage
                Write-Verbose -Message $completingMessage

				## authorize the DHCP Server in Active Directory
				#$dnsHostname = (Get-WmiObject win32_computersystem).DnsHostname
				#Add-DhcpServerInDC -DnsName $dnsHostname

				# Complete the DHCP configuration
				$objectOU = [ADSI]"WinNT://$MachineName"
				$group = $objectOU.Create("Group","DHCP Users")
				$group.CommitChanges()
				$groupAdmin = $objectOU.Create("Group","DHCP Administrators")
				$groupAdmin.CommitChanges()

				# Mark the DHCP configuration as completed
				Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\ServerManager\Roles\12 -Name ConfigurationState -Value 2

				Restart-Service -Name DHCPServer –Force
                
                $completedMessage = $($LocalizedData.CompletedMessage) -f $Name
                Write-Verbose -Message $completedMessage
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
#endregion Helper function

Export-ModuleMember -Function *-TargetResource