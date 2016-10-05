# Include (or dot-source the external files
. .\"include.ps1"

## Please provide access to computername/IIS_IUSRS group and IUSR user
 

function SetSiteDefaultContent($dirName,$defaultString="Default Hello World"){
	$defaultFile = "$dirName\default.htm"
	if(!(Test-Path $defaultFile))
	{
		Set-Content $defaultFile "$defaultString"
	}
	Else
	{
		Write-Host "$defaultFile already exists..."
	}
}


# Main Entry point
function Main {
    [CmdletBinding()]
	
    Param(
    [Parameter(Mandatory=$true, HelpMessage='Are you sure (Yes or No)?')]
    [String]$areYouSure
    )

    $testSite = "C:\users\vikram.nagarkar\documents\PowerShell\sites\TestSite"
	$testApp = "C:\users\vikram.nagarkar\documents\PowerShell\sites\TestSite\TestApp"
	$defaultFile = "C:\users\vikram.nagarkar\documents\PowerShell\sites\TestSite\TestApp\web.config"
	$appPoolName = "DemoAppPool"
	$site = "TestSite"
	$app = "TestApp"
	$port = "8080"

	Clear-Host

    Import-Module "WebAdministration"

	# Create New Directory for the website
	CreateDirectory $testSite
	CreateDirectory $testApp

	# Set Default site content
	SetSiteDefaultContent $testSite "Hello World"
	SetSiteDefaultContent $testApp
	
	# Create Application Pool
	CreateAppPool $appPoolName
	
	# Configure Site on IIS
	ConfigureSiteOnIIS $site $app $testSite $port $appPoolName
    "Default Test file!!!" | Out-File -FilePath "$testSite\test.html" -Force
		
	Write-Host "Website created successfully.. http://localhost:8080/"
	Write-Host "Please provide read access to IIS_IUSRS & IUSR for $testSite.."
    LaunchWebsite "http://localhost:8080/test.html"
}

Write-Host "Creating an E2E Website..."
Read-Host "Press any key to continue..."
Main
