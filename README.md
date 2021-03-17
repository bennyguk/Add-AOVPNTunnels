# Add-AOVPNTunnels
A PowerShell script to deploy and manage Always On VPN Device and User tunnels using Group Policy as an alternative to Microsoft Intune.

## To use
There are a few prerequisites to use this script. These are:
1. Valid ProfileXML files for Device and User tunnels. I recommend testing these profiles with powershell locally before using this script for deployment:
   * [Microsoft's documentation](https://docs.microsoft.com/en-us/windows-server/remote/remote-access/vpn/always-on-vpn/deploy/vpn-deploy-client-vpn-connections)
   * Example ProfileXML files can be downloaded from Richard Hicks' github page here:
     * [Device profileXML example](https://github.com/richardhicks/aovpn/blob/master/ProfileXML_Device.xml)
     * [User ProfileXML example](https://github.com/richardhicks/aovpn/blob/master/ProfileXML_User.xml)  
3. The script depends on [New-AovpnConnection.ps1](https://github.com/richardhicks/aovpn/blob/master/New-AovpnConnection.ps1) created by Richard Hicks.

3. Create a new Group Policy Object that is enabled for computer settings and is linked to OUs that contain computer objects that you wish to delpoy the VPN profile to. You may optionally chose to also use a group to filter the policy so that only specific computers will receive the policy.  
4. Copy the files (Add-OAVPNTunnels.ps1, [New-AovpnConnection.ps1](https://github.com/richardhicks/aovpn/blob/master/New-AovpnConnection.ps1), [profileXML_device.xml](https://github.com/richardhicks/aovpn/blob/master/ProfileXML_Device.xml) and [profileXML_device.xml](https://github.com/richardhicks/aovpn/blob/master/ProfileXML_User.xml)) to a network location that client devices can access to copy the files locally. I have chosen to use the folder that stores that Group Policy created earlier for central mangement and fault tolerance as the files will be replicated to all domain controllers. (\\domain.com\SYSVOL\domain.com\Policies\{75F40CD7-4B93-4258-AC30-9F6C21FDA399}\Machine\Scripts\*)  
5. Configure the Files Preference in the new policy:
   * Computer Configuration -> Preferences -> Windows Settings -> Files. Create a new file:
   * In the [general tab](/GPPCreateFileGeneral.JPG?raw=true "GPP Files general tab"), configure the source folder for your script and ProfileXML files followed by '\\*'.
   * Specify a local destination folder. I have chosen to create a new folder under the Windows directory. GPP will automaticall create the folder if it is missing.
   * Make sure the Action is replace.
   * In the [common tab](/GPPCreateFileCommon.JPG?raw=true "GPP Files common tab") check the box 'Remove this item when it is no longer required'.

6. Configure the Scheduled Tasks Preference in the new policy:
   * Computer Configuration -> Preferences -> Control Panel Settings -> Scueduled Tasks. New Scheduled Tasks (At least Windows 7):
   * [General Tab:](/GPPTasksGeneral.JPG?raw=true "GPP Files general tab")
     * Action: Replace
     * Give the task a name.
     * Use the NT AUTHORITY\SYSTEM account.
     * Check the box 'Run with highest privileges'.
     * Configure for: Windows 7, Windows Server 2008 R2. (If there is a later OS, choose that instead).  
   * [Triggers:](/GPPTasksTriggers.JPG?raw=true "GPP Files common tab")
     * Add a new trigger to run at log on (I tried with 'at startup', but could not get it to run reliably).
     * Configure the task to run for any user.  
   * [Actions:](/GPPTasksActions.JPG?raw=true "GPP Files common tab")
     * Action: Start a program
     * Program/Script: PowerShell
     * Add arguments(optional): `-ExecutionPolicy Bypass -File "%windir%\AOVPN\AddAOVPNTunnels.ps1"`  
   * [Settings:](/GPPTasksSettings.JPG?raw=true "GPP Files common tab")
     * Tick 'Allow task to be run on demand' (for troubleshooting).  
   * [Common:](/GPPTasksCommon.JPG?raw=true "GPP Files common tab")
     * Tick 'Remove this item when it is no longer applied'.  

## More information
The reason that I chose to use scheduled tasks that run local script files is because I discovered that startup scripts require a network connection to work. This is not always poossible on portable devices and I found it unreliable on wireless connections.

I have tested the script on Windows 10 version 1909, 2004 and 20H2.

The code has been tested with the v10.1.1.2016 version of the Cireson portal and with IE11, Chrome 87 and Edge.

