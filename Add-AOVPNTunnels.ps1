<#
.SYNOPSIS
    A script to deploy Always On VPN Device and User tunnels using Group Policy.

.DESCRIPTION
    If you do not have Microsoft Intune, this script can be used as an alternative for the deployment and management of Alway On VPN Device and User tunnels.
    
    The script requires New-AovpnConnection.ps1 (available from https://github.com/richardhicks/aovpn/blob/master/New-AovpnConnection.ps1)
    and is designed to be used with Group Policy Preferences to copy the files locally and create a scheduled task that runs this script. 
    
    Uses the Application Event Log to record information, warnings and errors. Events are logged under a new AOVPN event source.

    The script must be executed under the context of the SYSTEM account.
    
    For more information, please see https://github.com/bennyguk
#>

# Configure script to run in the local directory specified in Group Policy Preferences.
Set-Location -Path 'Path'

# Set $Warningpreference to 'stop' so that caught exceptions in New-AovpnConnection.ps1 that use Write-Warning output to the Application Event Log.
# Set $ErrorActionPreference to 'Stop' so that unhandled exceptions are displayed in the Event log using Write-Eventlog
$WarningPreference = "Stop"
$ErrorActionPreference = "Stop"

# Specify Device and User tunnel names
$DeviceTunnel = "DeviceTunnel"
$UserTunnel = "UserTunnel"

# Add AOVPN Event log source to the Application Event Log if missing.
If (![System.Diagnostics.EventLog]::SourceExists("AOVPN")) {
[System.Diagnostics.EventLog]::CreateEventSource("AOVPN", "Application")
}

# Get the file hash for the User and Device tunnel XML files.
$DeviceHash = (Get-FileHash .\profileXML_device.xml).Hash
$UserHash = (Get-FileHash .\profileXML_User.xml).Hash

# Run New-AovpnConnection.ps1 to create a new Device Tunnel
function Install-DeviceTunnel {
    Try {
        & '.\New-AovpnConnection.ps1' -xmlFilePath '.\profileXML_device.XML' -ProfileName $DeviceTunnel -AllUserConnection -DeviceTunnel
        Write-EventLog -LogName "Application" -Source "AOVPN" -EventID 1002 -EntryType Information -Message "AOVPN Device Tunnel has been successfully installed."
        }
    Catch {
        Write-EventLog -LogName "Application" -Source "AOVPN" -EventID 1004 -EntryType Error -Message "An error occured installing the Device Tunnel. The error details are:`n$_"
        }
}

# Run New-AovpnConnection.ps1 to create a new User Tunnel
function Install-UserTunnel {
    Try {
        & '.\New-AovpnConnection.ps1' -xmlFilePath '.\profileXML_User.XML' -ProfileName $UserTunnel -AllUserConnection
        Write-EventLog -LogName "Application" -Source "AOVPN" -EventID 1003 -EntryType Information -Message "AOVPN User Tunnel has been successfully installed."
        }
    Catch {
        Write-EventLog -LogName "Application" -Source "AOVPN" -EventID 1005 -EntryType Error -Message "An error occurred installing the User Tunnel. The error details are:`n$_"
        }
}

# Check if the Device Tunnel exists. If not, create it. If it does exist, check for changes in the ProfileXML that need to be deployed.
If (!((Get-VpnConnection -AllUserConnection).Name -eq $DeviceTunnel)) {
    Try {
        Write-EventLog -LogName "Application" -Source "AOVPN" -EventID 1000 -EntryType Warning -Message "AOVPN Device Tunnel is not installed."

        # Optional - Display the Device Tunnel on the Network flyout menu - Can only be used to display the status of the tunnel, not connect or disconnect.
        If (!(Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Flyout\VPN' -Name ‘ShowDeviceTunnelInUI’ -ErrorAction SilentlyContinue)) {
        New-Item -Path ‘HKLM:\SOFTWARE\Microsoft\Flyout\VPN’ -Force
        New-ItemProperty -Path ‘HKLM:\Software\Microsoft\Flyout\VPN\’ -Name ‘ShowDeviceTunnelInUI’ -PropertyType DWORD -Value 1 -Force
        }

        # Optional - Ensure related services can be started and start if not already started
        Set-Service -Name IKEEXT -StartupType Automatic
        Set-Service -Name PolicyAgent -StartupType Automatic
        Set-Service -Name IKEEXT -Status Running
        Set-Service -Name PolicyAgent -Status Running

        Install-DeviceTunnel
        }
    Catch {
        Write-EventLog -LogName "Application" -Source "AOVPN" -EventID 1004 -EntryType Error -Message "An error occurred installing the Device Tunnel. The error details are:`n`r$_"
        }
}
Else {
    If (Test-Path -Path .\profileXML_device.XML.hash -PathType Leaf) {
        $DeviceHashFile = Get-Content -Path .\profileXML_device.XML.hash
        If ($DeviceHash -eq $DeviceHashFile) {
            Write-EventLog -LogName "Application" -Source "AOVPN" -EventID 1006 -EntryType Information -Message "AOVPN Device Tunnel configuration is up to date."
        }
        Else {
            Write-EventLog -LogName "Application" -Source "AOVPN" -EventID 1008 -EntryType Warning -Message "AOVPN Device Tunnel configuration update is needed."
            Try {
                # Delete Device Tunnel
                Remove-VpnConnection -Name $DeviceTunnel -AllUserConnection -Force
                Write-EventLog -LogName "Application" -Source "AOVPN" -EventID 1010 -EntryType Information -Message "AOVPN Device Tunnel has been deleted."

                # Recreate Device Tunnel with the new configuration
                Install-DeviceTunnel

                # Update the hash file
                Set-Content .\profileXML_device.XML.hash -Value $DeviceHash
                }
            Catch {
                Write-EventLog -LogName "Application" -Source "AOVPN" -EventID 1004 -EntryType Error -Message "An error occurred installing the Device Tunnel. The error details are:`n`r$_"
            }
        }
    }
    # If the hash file is missing, create it.
    Else {
        New-Item -Path . -Name "profileXML_device.XML.hash" -ItemType "file" -Value $DeviceHash
    }
}

# Check if the User Tunnel exists. If not, create it. If it does exist, check for changes in the ProfileXML that need to be deployed.
If (!((Get-VpnConnection -AllUserConnection).Name -eq $UserTunnel)) {
   
    Write-EventLog -LogName "Application" -Source "AOVPN" -EventID 1001 -EntryType Warning -Message "AOVPN User Tunnel is not installed."
    Try {
        Install-UserTunnel
        }
    Catch {
        Write-EventLog -LogName "Application" -Source "AOVPN" -EventID 1005 -EntryType Error -Message "An error occurred installing the User Tunnel. The error details are:`n`r$_"
        }
}
Else {
    If (Test-Path -Path .\profileXML_User.XML.hash -PathType Leaf) {
        $UserHashFile = Get-Content -Path .\profileXML_User.XML.hash
        If ($UserHash -eq $UserHashFile) {
            Write-EventLog -LogName "Application" -Source "AOVPN" -EventID 1007 -EntryType Information -Message "AOVPN User Tunnel configuration is up to date."
        }
        Else {
            Write-EventLog -LogName "Application" -Source "AOVPN" -EventID 1009 -EntryType Warning -Message "AOVPN User Tunnel configuration update is needed."
            Try {
                # Delete User Tunnel
                Remove-VpnConnection -Name $UserTunnel -AllUserConnection -Force
                Write-EventLog -LogName "Application" -Source "AOVPN" -EventID 1011 -EntryType Information -Message "AOVPN User Tunnel has been deleted."
                
                # Recreate User Tunnel with the new configuration
                Install-UserTunnel
                
                # Update the hash file
                Set-Content .\profileXML_User.XML.hash -Value "$UserHash"                
            }
            Catch {
                Write-EventLog -LogName "Application" -Source "AOVPN" -EventID 1005 -EntryType Error -Message "An error occurred installing the User Tunnel. The error details are:`n`r$_"
            }
        }
    }
    # If the hash file is missing, create it.
    Else {
        New-Item -Path . -Name "profileXML_User.XML.hash" -ItemType "file" -Value $UserHash
    }    
}
