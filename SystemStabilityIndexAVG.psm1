<#
.Synopsis
   Calculate AVG of SystemStabilityIndex for each day, month, year
.DESCRIPTION
   Using Win32_ReliabilityStabilityMetrics to retrieve data and calculate. Created by Kevin Bhunut www.kbrnd.com
.EXAMPLE
    Get-SystemStabilityIndexAVG -day
.EXAMPLE
   Get-SystemStabilityIndexAVG -ComputerName LocalHost -Year
#>
function Get-SystemStabilityIndexAVG
{
	[CmdletBinding()]
	[OutputType([psobject])]
	Param
	(
		# Param1 help description
		[Parameter(ValueFromPipelineByPropertyName = $true,
				   Position = 0)]
		[string[]]
		$ComputerName = 'localhost',
		
		# Param2 help description
		[switch]
		$Day,
		[switch]
		$Month,
		[switch]
		$Year
	)
	
	
	Begin
	{
		$objArray = New-Object System.Collections.ArrayList
	}
	Process
	{
		try
		{
			foreach ($computer in $ComputerName)
			{				
				$sourceData += Get-CimInstance -ClassName Win32_ReliabilityStabilityMetrics -ComputerName $Computer -ErrorAction stop `
				| select SystemStabilityIndex, TimeGenerated, PSComputerName
			}
			Switch ($PSBoundParameters.GetEnumerator().Where({ $_.Value -eq $true }).Key)
			{
				'Day' {
					Write-Verbose "Day"
					$sourceData = $sourceData | Group { $_.PSComputerName }, { $_.TimeGenerated.Date }
					foreach ($data in $sourceData)
					{					
						$hash = [ordered] @{
							ComputerName = $data.Group.Item(1).PsComputerName
							Date = $data.Group.Item(1).TimeGenerated.ToShortDateString();
							SystemStabilityIndexAVG = calculateStabilityAVG($data)
						}
						$obj = New-Object -TypeName psobject -Property $hash
						[void]$objArray.Add($obj)
					}
				}
				'Month'{
					Write-Verbose "Month"
					$sourceData = $sourceData | Group { $_.PSComputerName }, { $_.TimeGenerated.Year }, { $_.TimeGenerated.Month }
					foreach ($data in $sourceData)
					{					
						$hash = [ordered] @{
							ComputerName = $data.Group.Item(1).PsComputerName
							Date = $data.Group.Item(1).TimeGenerated.toString('MMM yyyy');
							SystemStabilityIndexAVG = calculateStabilityAVG($data)							
						}
						$obj = New-Object -TypeName psobject -Property $hash
						[void]$objArray.Add($obj)
					}
				}
				'Year'{
					Write-Verbose "Year"
					$sourceData = $sourceData | Group { $_.PSComputerName }, { $_.TimeGenerated.Year }
					foreach ($data in $sourceData)
					{
						$hash = [ordered] @{
							ComputerName = $data.Group.Item(1).PsComputerName
							Date = $data.Group.Item(1).TimeGenerated.Year;
							SystemStabilityIndexAVG = calculateStabilityAVG($data)
						}
						$obj = New-Object -TypeName psobject -Property $hash
						[void]$objArray.Add($obj)
					}					
				}
				default
				{
					Write-Warning "Please use Parameter -Day or -Month or -Year"
				}
			}
		}
		catch
		{
			write-error $_.Exception.Message;
		}		
	}
	End
	{
		Write-Output $objArray | ft -AutoSize
	}
}

function calculateStabilityAVG($Data)
{
	[double]$total = 0;
	
	foreach ($eaData in $data.Group)
	{
		
		$total += $eaData.SystemStabilityIndex
		
	}
	
	$avg = "{0:N3}" -f $($total/$Data.Group.Count)
	return $avg
}
