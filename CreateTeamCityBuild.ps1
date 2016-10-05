<#-------------------------------
#
# Script to create Projects on http://teamcity based on the 2 templates
#
# 1. Build from Stash & run Nunits
# 2. Auto Deploy to Dev using octopus
# 
--------------------------------#>

function Test(){

}

<#-------------------------------
# Create a new TeamCity Project
--------------------------------#>
function CreateTeamCityProject($ProjectName,$Cred){

    $TeamCityUrl = $TeamCityBaseURL + "httpAuth/app/rest/projects/"
    # Setup ID and Project name
    $id = "WebsiteWww" + $ProjectName + "Com"
    $name = "www." + $ProjectName + ".com"

    # Create Project

    $body = @"
<newProjectDescription name='$name' id='$id'></newProjectDescription>
"@

    Invoke-RestMethod -Credential $Cred -Uri $TeamCityUrl -Body $body -Method POST -ContentType "application/xml"
}


<#------------------------------------------------------
# Create a new Build configuration to build the project
-------------------------------------------------------#>
function CreateBuildConfigFromTemplate($ProjectName,$Cred){
    #Create build from template

    $ParentId = "WebsiteWww" + $ProjectName + "Com"
    $TeamCityUrl =  $TeamCityBaseURL + "httpAuth/app/rest/projects/$ParentId/buildTypes"
    $template = "template:Stash_Build_RunTests"

    $name = "www." + $ProjectName + ".com - Build"

   $body = @"
<newBuildTypeDescription name='$name' sourceBuildTypeLocator='$template' copyAllAssociatedSettings='true' shareVCSRoots='false'/>
"@

    Invoke-RestMethod -Credential $Cred -Uri $TeamCityUrl -Body $body -Method POST -ContentType "application/xml"
}


<#--------------------------------------------
# Create a new AutoDeploy build configuration
---------------------------------------------#>
function CreateAutoDeployConfigFromTemplate($ProjectName,$Cred){
    #Create build from template

    $ParentId = "WebsiteWww" + $ProjectName + "Com"
    $TeamCityUrl =  $TeamCityBaseURL + "httpAuth/app/rest/projects/$ParentId/buildTypes"
    $template = "template:Auto_Deploy_to_Dev_Octopus"

    $name = "www." + $ProjectName + ".com - AutoDeploy to DEV"

    $body = @"
<newBuildTypeDescription name='$name' sourceBuildTypeLocator='$template' copyAllAssociatedSettings='true' shareVCSRoots='false'/>
"@

    Invoke-RestMethod -Credential $Cred -Uri $TeamCityUrl -Body $body -Method POST -ContentType "application/xml"
}


<#-------------------------------
# Attach Stash VCS root
--------------------------------#>
function AttachVCSRoot($ProjectName, $Cred){

    $BuildProjectId = "WebsiteWww" + $ProjectName + "Com_" + "Www" + $ProjectName + "ComBuild"
    
    $TeamCityUrl = $TeamCityBaseURL + "httpAuth/app/rest/buildTypes/$BuildProjectId/vcs-root-entries"

    $StashVCS =@"
<vcs-root-entry id="$BuildProjectId"><vcs-root id="Stash" name="Stash" href="/httpAuth/app/rest/vcs-roots/id:Stash"/><checkout-rules/></vcs-root-entry>
"@

    #Attach the Stash VCS Root
    Invoke-RestMethod -Credential $Cred -Uri $TeamCityUrl -Body $StashVCS -Method POST -ContentType "application/xml"

}

<#-------------------------------
# Set Parameters on the build project
--------------------------------#>
function SetBuildParameter($ProjectName,$Cred, $ParamName, $ParamValue){

    $projectId = "www." + $ProjectName + ".com - Build"
    $TeamCityUrl = $TeamCityBaseURL + "httpAuth/app/rest/buildTypes/$projectId/parameters/" + $ParamName

    #Attach the Stash VCS Root
    Invoke-RestMethod -Credential $Cred -Uri $TeamCityUrl -Body $ParamValue -Method PUT -ContentType "text/plain"
}

<#-------------------------------
# Set Parameters on the build project
--------------------------------#>
function SetDeployParameter($ProjectName,$Cred, $ParamName, $ParamValue){

    $projectId = "www." + $ProjectName + ".com - AutoDeploy to DEV"
    $TeamCityUrl = $TeamCityBaseURL + "httpAuth/app/rest/buildTypes/$projectId/parameters/" + $ParamName

    #Attach the Stash VCS Root
    Invoke-RestMethod -Credential $Cred -Uri $TeamCityUrl -Body $ParamValue -Method PUT -ContentType "text/plain"
}


<#-----------------------------------------------------
# Add artifact dependencies on the AutoDeploy project
------------------------------------------------------#>
function SetArtifactDependency($ProjectName,$Cred){

    Write-Host "--SetArtifactDependency--"

    $BuildProjectName = "www." + $ProjectName + ".com - Build"
    Write-Host "BuildProjectName = $BuildProjectName"

    $BuildProjectId = "WebsiteWww" + $ProjectName + "Com_" + "Www"+ $ProjectName + "ComBuild"
    Write-Host "BuildProjectId = $BuildProjectId"

    $DeployProjectId = "www." + $ProjectName + ".com - AutoDeploy to DEV"
    Write-Host "DeployProjectId = $DeployProjectId"
        
    $name = "www." + $ProjectName + ".com"
    Write-Host "ProjectName = $name"

    $nameId = "WebsiteWww" + $ProjectName + "Com"
    Write-Host "ProjectName Id = $nameId"

    #$TeamCityUrl = "http://teamcity/httpAuth/app/rest/buildTypes/$DeployProjectId/artifact-dependencies/"
    $TeamCityUrl = $TeamCityBaseURL + "httpAuth/app/rest/buildTypes/$DeployProjectId/artifact-dependencies/"
    Write-Host "TeamCity URL = $TeamCityUrl"
    
    $body =@"
        <artifact-dependency id="1" type="artifact_dependency">
             <properties>
                 <property name="cleanDestinationDirectory" value="true"/>
                 <property name="pathRules" value="*.nupkg"/>
                 <property name="revisionName" value="lastSuccessful"/>
                 <property name="revisionValue" value="latest.lastSuccessful"/>
             </properties>
             <source-buildType id="$BuildProjectId"
                               name="$BuildProjectName"
                               href="/httpAuth/app/rest/buildTypes/id:$BuildProjectId"
                               projectName="$name"
                               projectId="$nameId"
                               webUrl="http://teamcity/viewType.html?buildTypeId=$BuildProjectId"/>
         </artifact-dependency>
"@  
    Invoke-RestMethod -Credential $Cred -Uri $TeamCityUrl -Body $body -Method POST -ContentType "application/xml"
}

<#-------------------------------
# Main Control Function
--------------------------------#>
function Main(){
     [cmdletbinding()]
     Param(
            [Parameter(Mandatory=$true, HelpMessage='Please enter project name: e.g www.amm.com')]
            [String]$ProjectName,

            [Parameter(Mandatory=$true, HelpMessage='Please enter stash repository name: e.g lf/www.latinfinance.com.git')]
            [String]$StashRepo,

            [Parameter(Mandatory=$true, HelpMessage='Please enter Visual Studio Solution Name(Without .sln):')]
            [String]$SolutionName
     )
     
     Write-Host "TeamCity Base URL = $TeamCityBaseURL"

     # Get user credentials (Note: You shoud have admin access to create & configure projects
     $cred = Get-Credential

     # Create TC project
     CreateTeamCityProject $ProjectName $cred
     
     # Create Build Configuration to build the project from template
     CreateBuildConfigFromTemplate $ProjectName $cred
         
     # Create Auto Deploy build configuration from template
     CreateAutoDeployConfigFromTemplate $ProjectName $cred
     
     # Attach the Stash VCS root
     AttachVCSRoot $ProjectName $cred
     
     # Set the stash repository
     SetBuildParameter $ProjectName $Cred "repo" $StashRepo
     
     # Set the Project Name
     $name = "www." + "$ProjectName" + ".com"
     SetBuildParameter $ProjectName $Cred "project name" $name
     
     # Set the Visual Studio solution name
     SetBuildParameter $ProjectName $Cred "solution name" $SolutionName

     # Set Artifact dependency on the Build project for the deploy to dev project
     SetArtifactDependency $ProjectName $Cred

     # Set project name in deploy configuration
     SetDeployParameter $ProjectName $Cred "project.name" $name
     
     #>
}


# Call function to create build configuration
$TeamCityBaseURL = "http://teamcity/"
cls
Main
#Test
