# Add-AOVPNTunnels
A PowerShell script to deploy and manage Always On VPN Device and User tunnels using Group Policy as an alternative to Microsoft Intune.

## To use
There are a few prerequisites to use this script. These are:
1. Valid ProfileXML files for Device and User tunnels. I recommend testing these profiles with powershell locally before using this script for deployment:
   * [Microsoft's documentation](https://docs.microsoft.com/en-us/windows-server/remote/remote-access/vpn/always-on-vpn/deploy/vpn-deploy-client-vpn-connections)
   * Example ProfileXML files can be downloaded from Richard Hicks' github page here:
     * [Device profileXML example](https://github.com/richardhicks/aovpn/blob/master/ProfileXML_Device.xml)
     * [User ProfileXML example](https://github.com/richardhicks/aovpn/blob/master/ProfileXML_User.xm)


2. Create a new Group Policy Object that is enabled for computer settings and is linked to OUs that contain computer objects that you wish to delpoy the VPN profile to. You may optionally chose to also use a group to filter the policy so that only specific computers will receive the policy.  
3. Copy the files (Add-OAVPNTunnels, New-AovpnConnection, profileXML_device and profileXML_device) to a network location that client devices can access to copy the files locally. I have chosen to use the folder that stores that Group Policy created earlier for central mangement and fault tolerance as the files will be replicated to all domain controllers.  
4. Configure the Files Preference in the new policy:
   * Computer Configuration -> Preferences -> Windows Settings -> Files. Create a new file:
   * In the general tab, configure the source folder for your script and ProfileXML files followed by '\\*'.
   * Specify a local destination folder. I have chosen to create a new folder under the Windows directory. GPP will automaticall create the folder if it is missing.
   * Make sure the Action is replace.
   * In the common tab check the box 'Remove this item when it is no longer required'.

![alt text](/GPPCreateFileGeneral.JPG?raw=true "GPP Files general tab")
![alt text](/GPPCreateFileCommon.JPG?raw=true "GPP Files common tab")

5. Configure the Scheduled Tasks Preference in the new policy:
   * Computer Configuration -> Preferences -> Control Panel Settings -> Scueduled Tasks. New Scheduled Tasks (At least Windows 7):
   * General Tab:
     * Action: Replace
     * Give the task a name.
     * Use the NT AUTHORITY\SYSTEM account.
     * Check the box 'Run with highest privileges'.
     * Configure for: Windows 7, Windows Server 2008 R2. (If there is a later OS, choose that instead).  
   * Triggers:
     * Add a new trigger to run at log on (I tried with 'at startup', but could not get it to run reliably).
     * Configure the task to run for any user.  
   * Actions:
     * Action: Start a program
     * Program/Script: PowerShell
     * Add arguments(optional): `-ExecutionPolicy Bypass -File "%windir%\AOVPN\AddAOVPNTunnels.ps1"`  
   * Settings:
     * Tick 'Allow task to be run on demand' (for troubleshooting).  
   * Common:
     * Tick 'Remove this item when it is no longer applied'.  


More information on how to use the Script Loader can be found [here](https://cireson.com/blog/how-to-organize-your-customspace-with-a-script-loader/).

## More information
The code has been tested with the v10.1.1.2016 version of the Cireson portal and with IE11, Chrome 87 and Edge.

The original discussion about this code can be found [here](https://community.cireson.com/discussion/1851/pulsating-save-button-in-drawer-taskbar?).

A new discussion has been created to cover the modifications to the original code [here](https://community.cireson.com/discussion/5848/pulsating-save-next-aro-button-in-drawer-taskbar).
