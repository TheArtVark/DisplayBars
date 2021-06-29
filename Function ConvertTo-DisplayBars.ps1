
Function ConvertTo-DisplayBars {
<#
.SYNOPSIS
Displays array of values as rows of asterisks.

.DESCRIPTION
This function can take an array of values and display them as rows of asteriks with various options for the output.

.NOTES
ColorDisplay can only be used on PowerShell version 5 or greater.

.PARAMETER Values
An array of the values to be displayed.

.PARAMETER Minimum
The value that is the low 'starting point' for the displayed row.

.PARAMETER Maximum
The value that is the high 'end point' for the displayed row.

.PARAMETER AutoRange
If this switch is used the function will get the Minimum and Maximum values from the array of provided values

.PARAMETER DisplayValue
If this switch is each 'asterisk bar' will be preceded by the actual value.

.PARAMETER DisplayMinMaxHeader
Display a header with the minimum and maximum values.

.PARAMETER BarPrefix
Add a prefix to each bar.

.PARAMETER DisplayColors
Expects an array of two integers. If set, AND PowerShell is at least version 5.0, the output will be displayed using Red, Yellow and Green.
The values should be seen as percentage of the RANGE of values.

.EXAMPLE
Display a simple range of values with a header using colors:
ConvertTo-DisplayBars -Values @(120,56,34,66,78,23,45,90) -AutoRange -DisplayValue -ColorDisplay @(50,70) -DisplayMinMaxHeader

Show a bar for each WiFi signal strength reading:
While ($true) {
    $intSignalStrength = [int][regex]::Match((netsh wlan show interfaces),'\bSignal\b\s*:\s*(\d+)',[System.Text.RegularExpressions.RegexOptions]::Singleline).Groups[1].Value
    [string]$strPrefix = "Signal strength "
    ConvertTo-DisplayBars -Values $intSignalStrength -Minimum 0 -Maximum 100 -BarPrefix $strPrefix -ColorDisplay @(50,70) -DisplayValue
    Start-Sleep -Seconds 5
}

.AUTHOR
Ton de Vreede

.VERSION 1.0
#>
    [CmdletBinding(DefaultParameterSetName = 'ManualRange')]
    param (
        [Parameter(Mandatory = $true, HelpMessage = 'The array to be shown in bars.')]
        [int[]]$Values,
        [Parameter(Mandatory = $true, ParameterSetName = 'ManualRange', HelpMessage = 'Minimum expected value.')]
        [int]$Minimum,
        [Parameter(Mandatory = $true, ParameterSetName = 'ManualRange', HelpMessage = 'Maximum expected value.')]
        [int]$Maximum,
        [Parameter(Mandatory = $true, ParameterSetName = 'AutoRange', HelpMessage = 'Set the range of values automatically.')]
        [switch]$AutoRange,
        [Parameter(Mandatory = $false, HelpMessage = "Display the value before each 'displaybar'.")]
        [switch]$DisplayValue,
        [Parameter(Mandatory = $false, HelpMessage = 'Display a header with the minimum and maximum values.')]
        [switch]$DisplayMinMaxHeader,
        [Parameter(Mandatory = $false, HelpMessage = 'Use this to add a prefix to each bar.')]
        [string]$BarPrefix,
        [Parameter(Mandatory = $false, HelpMessage = 'Use colors in the bars. An array of 2 values is expected, for the minimum percentage value for the bar to be yellow and the minimum percentage value for the bar to be green. PS5 and later only.')]
        [array]$ColorDisplay
    )
    
    # Set a bool for using colors in display output. Fail if PSversion is below 5
    [bool]$bolColors = $false
    If ($($PSBoundParameters.ContainsKey('ColorDisplay')) -and ($PSVersionTable.PSVersion.Major -ge 5)) {
        $bolColors = $true
    }
        
    # Get screen buffer size and set max ouput width to 90% of that.
    [int]$intBufferSize = $host.UI.RawUI.BufferSize.Width * .9

    # If there is a prefix, subtract the length of that from the buffer size.
    if ($PSBoundParameters.ContainsKey('BarPrefix')) {
        $intBufferSize = $intBufferSize - $BarPrefix.Length
    }

    # Set range if AutoRange has been specified
    If ($PSCmdlet.ParameterSetName -eq 'AutoRange') {
        $MeasuredValues = $Values | Measure-Object -Minimum -Maximum
        [int]$Minimum = $MeasuredValues.Minimum
        [int]$Maximum = $MeasuredValues.Maximum
    }

    # Write line with min and max values if required
    If ($PSBoundParameters.ContainsKey('DisplayMinMaxHeader')) {
        [string]$strHeaderLine = "Min: $($Minimum.ToString())"
        For ($i = 1; $i -le ($intBufferSize - ($Minimum.ToString().Length + $Maximum.ToString().Length + 10)); $i ++) {
            $strHeaderLine += ' '
        }
        $strHeaderLine += "Max: $($Maximum.ToString())"
        Write-Output -InputObject $strHeaderLine
    }

    # Get the value range
    [int]$intValueRange = $Maximum - $Minimum

    # Get size of steps
    [double]$dblStepSize = $intBufferSize / $intValueRange

    # Get pad length if values should be displayed
    If ($PSBoundParameters.ContainsKey('DisplayValue')) {
        [int]$intPad = $Maximum.toString().Length
    }

    # First write a line with the min and max values
    Foreach ($Value in $Values) {
        [string]$strValueLine = $null
        
        # Set the line length
        [int]$intBarLength = (($value - $Minimum) * $dblStepSize)
        If ($intBarLength -ge 0) {
            $strValueLine += '*' * $intBarLength
        }
        Else {
            $strValueLine = 'X'
        }
        If ($PSBoundParameters.ContainsKey('DisplayValue')) {
            $strValueLine = $Value.ToString().PadLeft($intPad, ' ') + ": $strValueLine"
        }

        # Add the prefix if required
        if ($PSBoundParameters.ContainsKey('BarPrefix')) {
            $strValueLine = "$BarPrefix$strValueLine"
        }

        # Use color output if specified
        If ($bolColors) {
            [int]$intPercentage = (($value - $Minimum) / $intValueRange) * 100
            switch ($intPercentage) {
                { $_ -le $ColorDisplay[0] } { $strColor = 'Red'; Break }
                { $_ -le $ColorDisplay[1] } { $strColor = 'Yellow'; Break }
                Default { $strColor = 'Green' }
            }
            Write-Host -Object $strValueLine -ForegroundColor $strColor
        }
        Else {
            Write-Output $strValueLine
        }
    }
}
