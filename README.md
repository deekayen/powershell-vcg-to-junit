# powershell-vcg-to-junit
PowerShell script to convert VisualCodeGrepper results to jUnit for Jenkins integration.
VisualCodeGrepper is static code analysis tool that can be found at http://sourceforge.net/projects/visualcodegrepp/

Example usage in Jenkins PowerShell plugin would be:
C:\tools\scripts\vcg.ps1 -verbose -scanTargetLocation $env:WORKSPACE -vcgReportLocation "$($env:WORKSPACE)\vcgresults.xml" -unitTestReportLocation "$($env:WORKSPACE)\testresults.xml"

After that testresults.xml can be used in post-build action to publish junit result report.