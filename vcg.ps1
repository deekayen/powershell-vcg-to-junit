# https://github.com/solita/powershell-vcg-to-junit
[cmdletbinding()]
param(
	[Parameter(Mandatory=$true)]
	[string]
	$scanTargetLocation,
	[string]
	$vcgLocation = "C:\Program Files (x86)\VisualCodeGrepper\",
	[string]
	$vcgReportLocation = "D:\temp\vcgresults.xml",
	[string]
	$unitTestReportLocation = "D:\temp\vcgtestresults.xml",
	[string]
	$scanLanguage = "CS"
)
# error action to stop
$erroractionpreference = "Stop"
# sanity check
If (-not (Test-Path $vcgLocation)) { Write-Error "Install VisualCodeGrepper and/or check path $vcgLocation" }
Write-Verbose "VCG location: $vcgLocation"
Write-Verbose "VCG report: $vcgReportLocation"
Write-Verbose "Unit tests end result: $unitTestReportLocation"
Write-Verbose "Scan target: $scanTargetLocation"

<#
.SYNOPSIS 
Gets the information about all alerts from file

.DESCRIPTION
Gets the information about all alerts from file

.EXAMPLE
script:Save-VcgReport
#>
function script:Save-VcgReport
{
    [CmdletBinding()]
    param()
    
    [xml]$xmlReport = Get-Content $vcgReportLocation
	$alerts = $xmlReport.CodeIssueCollection | % { $_.CodeIssue }
    $alertMeasure = $alerts | measure 
    # Transform the report to testsuite xml supported by jenkins
    # Create a new XML File with config root node
    [System.XML.XMLDocument]$oXMLDocument=New-Object System.XML.XMLDocument
    # create testsuite node and add attribute 
    [System.XML.XMLElement]$oXMLRoot=$oXMLDocument.CreateElement("testsuite")
    $null = $oXMLDocument.appendChild($oXMLRoot)
    $null = $oXMLRoot.SetAttribute("tests",$alertMeasure.Count)
    # create dummy test, without atleast one test the jenkins plugin won't work
    [System.XML.XMLElement]$oXMLTestcase=$oXMLRoot.appendChild($oXMLDocument.CreateElement("testcase"))
    $null = $oXMLTestcase.SetAttribute("classname","Dummy")
    $null = $oXMLTestcase.SetAttribute("name","Dummy test")

    # create tests and failures 
    Foreach($alert in $alerts)
    {
	    if ($alert.Severity -eq "High" -or $alert.Severity -eq "Critical")
        {
		    # create test
		    [System.XML.XMLElement]$oXMLTestcase=$oXMLRoot.appendChild($oXMLDocument.CreateElement("testcase"))
		    $null = $oXMLTestcase.SetAttribute("classname",$alert.FileName)
		    $null = $oXMLTestcase.SetAttribute("name",$alert.Title)

		    # create failure
		    [System.XML.XMLElement]$oXMLTestFailure=$oXMLTestcase.appendChild($oXMLDocument.CreateElement("failure"))
		    $null = $oXMLTestFailure.SetAttribute("type",$alert.Severity)
		    # create a "stacktrace"
		    [string]$stackTrace = 
@"
	Error at file: {0}
	Codeline: {1}
	Description: {2}
"@ -f $alert.FileName, $alert.CodeLine, $alert.Description
		    #store stacktrace
		    $null = $oXMLTestFailure.AppendChild($oXMLDocument.CreateTextNode($stackTrace))
        }
    }
    # Save File
    $oXMLDocument.Save($script:unitTestReportLocation)
    Write-Verbose ("Report saved to "+$script:unitTestReportLocation)
}

$currentLocation = $psscriptroot
cd $vcgLocation
& .\VisualCodeGrepper.exe -c -t $scanTargetLocation -l $scanLanguage -x $vcgReportLocation | Write-Verbose
cd $currentLocation

Save-VcgReport
