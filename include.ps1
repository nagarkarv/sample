function LaunchWebsite($url){
    
    Write-Host "Launch the website"
    $ie = New-Object -com InternetExplorer.Application
    $ie.visible = $true
    $ie.Navigate($url)
}

function CreateDirectory ($dirName){
	# Create the directory only of it does not exist
	if(!(Test-Path -Path $dirName))
	{
		New-Item $dirName -type Directory
	}
	Else
	{
		Write-Host "$dirName already exists..."
	}
}

function CreateAppPool($appPoolName) {

	if(!(Test-Path IIS:\AppPools\$appPoolName))
	{
		New-Item IIS:\AppPools\$appPoolName
	}
	Else
	{	
		Write-Host "AppPool $appPoolName already exists..."
	}
}

function ConfigureSiteOnIIS($site, $app, $physicalPath,$port,$appPoolName){
	# Setup Site
	if(Test-Path IIS:\Sites\$site)
	{
		Write-Host "Site $site already exists, removing and reconfiguring..."
		Remove-Item IIS:\Sites\$site -Recurse
	}
	New-Item IIS:\Sites\$site -physicalPath $physicalPath -bindings @{protocol="http";bindingInformation=":8080:"}
	
	# Setup application within this site
	if(Test-Path IIS:\Sites\$site\$app)
	{	
		Write-Host "App $app already exists, removing and reconfiguring..."	
		Remove-Item IIS:\Sites\$site\$app -Recurse
	}
	New-Item IIS:\Sites\$site\$app -physicalPath $physicalPath\$app -type Application
	Set-ItemProperty IIS:\Sites\$site\$app -name applicationPool -value $appPoolName
    CreateDefaultWebDotConfig $physicalPath
    CreateDefaultWebDotConfig "$physicalPath\$app"
}

function CreateDefaultWebDotConfig($sitePath){

    $path = "$sitePath\web.config"
    $doc = [xml] "<?xml version=""1.0"" encoding=""utf-8""?>"
    $configuration = $doc.CreateElement("configuration")
    $server = $doc.CreateElement("system.webServer")
    $defaultDocument = $doc.CreateElement("defaultDocument")
    $files = $doc.CreateElement("files")
    $add = $doc.CreateElement("add")
     
    $configuration.AppendChild($server)
    $server.AppendChild($defaultDocument)
    $defaultDocument.AppendChild($files)
    $files.AppendChild($add)
    $add.SetAttribute("value","Default.html")

    $doc.AppendChild($configuration)

    $doc.Save($path)
    #UpdateWebConfigFilePermissions $path

    Write-Host "Default Web.config create: $sitePath\web.config"
}

function UpdateWebConfigFilePermissions($Folder){

    $acl = Get-Acl $Folder
    $permission = "EULONWL09241\IIS_IUSRS","FullControl","Allow"
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
    $acl.SetAccessRule($accessRule)
    $acl | Set-Acl $Folder



    <#Write-Host "Updating file permissions for : $folder"
    #$iis_iusr_grp = "EULONWL09241\IIS_IUSRS"
    #$iusrs = "IUSR"
    #$InheritanceFlag = [System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit
    #$PropagationFlag = [System.Security.AccessControl.PropagationFlags]::None
    #$objType = [System.Security.AccessControl.AccessControlType]::Allow 

    #$acl = Get-Acl $Folder
    #$permission = $user,"Read", $InheritanceFlag, $PropagationFlag, $objType
    #$permission = $iusrs,"Read"
    #$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($iusrs,"Read", $InheritanceFlag, $PropagationFlag, $objType)
    #$accessRule = New-Object System.Security.AccessControl.DirectoryObjectSecurity($iusrs,"Read", $InheritanceFlag, $PropagationFlag, $objType)
    #$acl.SetAccessRule($accessRule)
    #Set-Acl $Folder $acl
    #>
}
