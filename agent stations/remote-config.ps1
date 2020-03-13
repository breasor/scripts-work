## RemoteConfig setup
#!ps1
#timeout=90000
# Power Settings

powercfg.exe /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
powercfg.exe -x -monitor-timeout-ac 0
powercfg.exe -x -monitor-timeout-dc 0
powercfg.exe -x -disk-timeout-ac 0
powercfg.exe -x -disk-timeout-dc 0
powercfg.exe -x -standby-timeout-ac 0
powercfg.exe -x -standby-timeout-dc 0
powercfg.exe -x -hibernate-timeout-ac 0
powercfg.exe -x -hibernate-timeout-dc 0

# Disable Windows Updates
Stop-Service wuauserv -Force -NoWait
Set-Service wuauserv -StartupType Disabled -Force

# Change Windows Feedback frequency to "Never"
New-Item -Path HKCU:\Software\Microsoft\Siuf\Rules -Force
New-ItemProperty -Path HKCU:\Software\Microsoft\Siuf\Rules -Name NumberOfSIUFInPeriod -PropertyType DWord -Value 0 -Force

# Do not let apps on other devices open and message apps on this device, and vice versa
New-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\CDP -Name RomeSdkChannelUserAuthzPolicy -PropertyType DWord -Value 0 -Force

# Turn off automatic installing suggested apps
New-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager -Name SilentInstalledAppsEnabled -PropertyType DWord -Value 0 -Force

# Show "This PC" on Desktop
New-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -PropertyType DWord -Value 0 -Force

# Turn off check boxes to select items
New-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name AutoCheckSelect -PropertyType DWord -Value 0 -Force

# Unpin Microsoft Edge and Microsoft Store from taskbar
$Signature = @{
	Namespace = "WinAPI"
	Name = "GetStr"
	Language = "CSharp"
	MemberDefinition = @"
		[DllImport("kernel32.dll", CharSet = CharSet.Auto)]
		public static extern IntPtr GetModuleHandle(string lpModuleName);
		[DllImport("user32.dll", CharSet = CharSet.Auto)]
		internal static extern int LoadString(IntPtr hInstance, uint uID, StringBuilder lpBuffer, int nBufferMax);
		public static string GetString(uint strId)
		{
			IntPtr intPtr = GetModuleHandle("shell32.dll");
			StringBuilder sb = new StringBuilder(255);
			LoadString(intPtr, strId, sb, sb.Capacity);
			return sb.ToString();
		}
"@
}
if (-not ("WinAPI.GetStr" -as [type]))
{
	Add-Type @Signature -Using System.Text
}
$unpin = [WinAPI.GetStr]::GetString(5387)
$apps = (New-Object -ComObject Shell.Application).NameSpace("shell:::{4234d49b-0245-4df3-b780-3893943456e1}").Items()
$apps | Where-Object -FilterScript {$_.Path -like "Microsoft.MicrosoftEdge*"} | ForEach-Object -Process {$_.Verbs() | Where-Object -FilterScript {$_.Name -eq $unpin} | ForEach-Object -Process {$_.DoIt()}}
$apps | Where-Object -FilterScript {$_.Path -like "Microsoft.WindowsStore*"} | ForEach-Object -Process {$_.Verbs() | Where-Object -FilterScript {$_.Name -eq $unpin} | ForEach-Object -Process {$_.DoIt()}}

# Do not show user first sign-in animation
New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System -Name EnableFirstLogonAnimation -PropertyType DWord -Value 0 -Force

# Turn on Storage Sense
New-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy -Name 01 -PropertyType DWord -Value 1 -Force
# Run Storage Sense every month
New-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy -Name 2048 -PropertyType DWord -Value 30 -Force
# Delete temporary files that apps aren't using
New-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy -Name 04 -PropertyType DWord -Value 1 -Force
# Delete files in recycle bin if they have been there for over 30 days
New-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy -Name 256 -PropertyType DWord -Value 30 -Force
# Never delete files in "Downloads" folder
New-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy -Name 512 -PropertyType DWord -Value 0 -Force

# Turn off hibernate for devices, except laptops
if ((Get-CimInstance -ClassName Win32_ComputerSystem).PCSystemType -ne 2)
{
	powercfg /hibernate off
}

# Turn off AutoPlay for all media and devices
New-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers -Name DisableAutoplay -PropertyType DWord -Value 1 -Force



#Stops edge from taking over as the default .PDF viewer    
Write-Output "Stopping Edge from taking over as the default .PDF viewer"
$NoPDF = "HKCR:\.pdf"
$NoProgids = "HKCR:\.pdf\OpenWithProgids"
$NoWithList = "HKCR:\.pdf\OpenWithList" 
If (!(Get-ItemProperty $NoPDF  NoOpenWith)) {
    New-ItemProperty $NoPDF NoOpenWith 
}        
If (!(Get-ItemProperty $NoPDF  NoStaticDefaultVerb)) {
    New-ItemProperty $NoPDF  NoStaticDefaultVerb 
}        
If (!(Get-ItemProperty $NoProgids  NoOpenWith)) {
    New-ItemProperty $NoProgids  NoOpenWith 
}        
If (!(Get-ItemProperty $NoProgids  NoStaticDefaultVerb)) {
    New-ItemProperty $NoProgids  NoStaticDefaultVerb 
}        
If (!(Get-ItemProperty $NoWithList  NoOpenWith)) {
    New-ItemProperty $NoWithList  NoOpenWith
}        
If (!(Get-ItemProperty $NoWithList  NoStaticDefaultVerb)) {
    New-ItemProperty $NoWithList  NoStaticDefaultVerb 
}
        
#Appends an underscore '_' to the Registry key for Edge
$Edge = "HKCR:\AppXd4nrz8ff68srnhf9t5a8sbjyar1cr723_"
If (Test-Path $Edge) {
    Set-Item $Edge AppXd4nrz8ff68srnhf9t5a8sbjyar1cr723_ 
}

# Uninstall all UWP apps from all accounts, except the followings...
$ExcludedApps = @(
	# iTunes
	"AppleInc.iTunes"
	# Intel UWP-panel
	"AppUp.IntelGraphicsControlPanel"
	"AppUp.IntelGraphicsExperience"
	# Microsoft Desktop App Installer
	"Microsoft.DesktopAppInstaller"
	# Sticky Notes
	"Microsoft.MicrosoftStickyNotes"
	# Screen Sketch
	"Microsoft.ScreenSketch"
	# Microsoft Store
	"Microsoft.StorePurchaseApp"
	"Microsoft.WindowsStore"
	# Web Media Extensions
	"Microsoft.WebMediaExtensions"
	# Photos and Video Editor
	"Microsoft.Windows.Photos"
	# Calculator
	"Microsoft.WindowsCalculator"
	# NVIDIA Control Panel
	"NVIDIACorp.NVIDIAControlPanel"
)
$OFS = "|"
Get-AppxPackage -PackageTypeFilter Bundle -AllUsers | Where-Object {$_.Name -cnotmatch $ExcludedApps} | Remove-AppxPackage -AllUsers
$OFS = " "
# Uninstall all provisioned UWP apps from System account, except the followings...
# App packages will not be installed when new user accounts are created
$ExcludedApps = @(
	# Intel UWP-panel
	"AppUp.IntelGraphicsControlPanel"
	"AppUp.IntelGraphicsExperience"
	# Microsoft Desktop App Installer
	"Microsoft.DesktopAppInstaller"
	# HEIF Image Extensions
	"Microsoft.HEIFImageExtension"
	# Sticky Notes
	"Microsoft.MicrosoftStickyNotes"
	# Screen Sketch
	"Microsoft.ScreenSketch"
	# Microsoft Store
	"Microsoft.StorePurchaseApp"
	"Microsoft.WindowsStore"
	# VP9 Video Extensions
	"Microsoft.VP9VideoExtensions"
	# Web Media Extensions
	"Microsoft.WebMediaExtensions"
	# WebP Image Extension
	"Microsoft.WebpImageExtension"
	# Photos and Video Editor
	"Microsoft.Windows.Photos"
	# Calculator
	"Microsoft.WindowsCalculator"
	# NVIDIA Control Panel
	"NVIDIACorp.NVIDIAControlPanel"
)
$OFS = "|"
Get-AppxProvisionedPackage -Online | Where-Object -FilterScript {$_.DisplayName -cnotmatch $ExcludedApps} | Remove-AppxProvisionedPackage -Online
$OFS = " "

# Turn off Game bar
New-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR -Name AppCaptureEnabled -PropertyType DWord -Value 0 -Force
New-ItemProperty -Path HKCU:\System\GameConfigStore -Name GameDVR_Enabled -PropertyType DWord -Value 0 -Force
# Turn off Xbox Game Bar tips
New-ItemProperty -Path HKCU:\Software\Microsoft\GameBar -Name ShowStartupPanel -PropertyType DWord -Value 0 -Force

# Turn on logging of all PowerShell script input to the Microsoft-Windows-PowerShell/Operational event log
if (-not (Test-Path -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging))
{
	New-Item -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging -Force
}
New-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging -Name EnableScriptBlockLogging -PropertyType DWord -Value 1 -Force
# Turn on events auditing generated when a process is created or starts
auditpol /set /subcategory:"Process Creation" /success:enable /failure:enable
# Include command line in process creation events
New-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System\Audit -Name ProcessCreationIncludeCmdLine_Enabled -PropertyType DWord -Value 1 -Force


# Popup Allowed
$PopupList = @("[*.]ansafone.com"
               ,"[*.]solutran.com"
               ,"[*.]mypurecloud.com"
               )
New-Item -path HKLM:\SOFTWARE\Policies\Google\Chrome\PopupsAllowedForUrls -Force
$PopupList | ForEach-Object { $counter = 1}{ New-ItemProperty -path HKLM:\SOFTWARE\Policies\Google\Chrome\PopupsAllowedForUrls -Name $counter -Value $_ -Force; $counter++}



