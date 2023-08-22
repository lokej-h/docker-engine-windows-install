# Admin elevation + check by msft

# https://learn.microsoft.com/en-us/archive/blogs/virtual_pc_guy/a-self-elevating-powershell-script

 # Get the ID and security principal of the current user account
 $myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
 $myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
  
 # Get the security principal for the Administrator role
 $adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator
  
 # Check to see if we are currently running "as Administrator"
 if ($myWindowsPrincipal.IsInRole($adminRole))
{
    # We are running "as Administrator" - so change the title and background color to indicate this
    $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + "(Elevated)"
    $Host.UI.RawUI.BackgroundColor = "DarkBlue"
    clear-host
}
else
{
    # We are not running "as Administrator" - so relaunch as administrator

    # This line from https://superuser.com/questions/108207/how-to-run-a-powershell-script-as-administrator
    Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))

    # Exit from the current, unelevated, process
    exit
}

# --------
# the steps for installing docker engine manually are here
# https://docs.docker.com/engine/install/binaries/#install-server-and-client-binaries-on-windows

Write-Host "Attempting to stop docker if already installed..."
Stop-Service docker

Write-Host "Downloading latest Docker Engine to Downloads folder"

$dockerRepo = "https://download.docker.com/win/static/stable/x86_64/"

$raw = Invoke-WebRequest -Uri $dockerRepo

$latestFileHref = ($raw.Links | ?{$_.href -match ".zip"} | Select-Object -Last 1).href

Write-Host $latestFileHref

$downloadedFilePath = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path + '\' + $latestFileHref

Invoke-WebRequest -Uri ($dockerRepo + $latestFileHref) -OutFile $downloadedFilePath

Write-Host "Docker Engine downloaded"

# Installation

Write-Host "Extracting Docker Engine to Program Files"
Expand-Archive $downloadedFilePath -DestinationPath $Env:ProgramFiles -Force

Write-Host "Registering Service..."
&$Env:ProgramFiles\Docker\dockerd --register-service

Write-Host "Starting Service..."
Start-Service docker

Write-Host "Finished. If you want to run docker as a non-admin, add to the daemon.json in the opened folder."
Write-Host @"
{
    "hosts":  [
                  "npipe://"
              ],
    "group": "docker-users"
}
"@
explorer.exe C:\ProgramData\docker\config

# Pause at end for user to peruse
Write-Host -NoNewLine "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
exit