# Build Validation script for vSphere 5 AutoLab
#
# Version 0.6
#
#
# Include the functions script, this is used to keep this script clean
. "c:\PSFunctions.ps1"

$Global:Pass = $True

If (Test-Administrator)
{ Write-Host "Great, script is running as administrator" -foregroundcolor "Green"}
else
{Write-Host "You must run this script in an elevated PowerShell prompt" -foregroundcolor "red"
Write-Host "Right click the PowerShell shortcut and select 'Run as Administrator'" -foregroundcolor "red"
exit
}
$CompName = gc env:computername
Write-Host "Validating" $CompName -foregroundcolor "cyan"
Write-Host "Validate Build Share required components" -foregroundcolor "cyan"
Check-OptionalFile "\\192.168.199.7\Build\ESX41\TRANS.TBL" "ESX41"
Check-OptionalFile "\\192.168.199.7\Build\ESXi41\tboot.gz" "ESXi41"
Check-File "\\192.168.199.7\Build\ESXi50\BOOT.CFG" "ESXi50"
Check-OptionalFile "\\192.168.199.7\Build\VIM_41\vpx\VMware-viclient.exe" "vCenter 4.1"
Check-File "\\192.168.199.7\Build\VIM_50\vCenter-Server\VMware-vcserver.exe" "vCenter 5.0"
Check-File "\\192.168.199.7\Build\VMTools\Setup.exe" "VMware Tools"
Check-File "\\192.168.199.7\Build\VMware-PowerCLI.exe" "VMware PowerCLI Installer"
Check-File "\\192.168.199.7\Build\WinInstall.iso" "Windows Installer iso"
Check-OptionalFile "\\192.168.199.7\Build\WinInstall.flp" "Windows Installer floppy"
If ( $CompName -eq "DC")
{
    Write-Host "Validate SQL & TFTP Install" -foregroundcolor "cyan"
    Check-File "C:\Program Files\Microsoft SQL Server\MSSQL10_50.SQLEXPRESS\MSSQL\DATA\vCenter.mdf" "vCenter Database"
    Check-File "C:\Program Files\Microsoft SQL Server\MSSQL10_50.SQLEXPRESS\MSSQL\DATA\VUM.mdf" "vCenter Update Manager Database"
    Check-File "C:\Program Files\Tftpd64_SE\Tftpd64_SVC.exe" "TFTP Server"
    Check-File "C:\TFTP-Root\pxelinux.0" "PXE boot file"
    Check-File "C:\TFTP-Root\pxelinux.cfg" "PXE boot configuration file"
    Check-OptionalFile "C:\TFTP-Root\ESX41\vmlinuz" "ESX 4.1 install boot image"
    Check-OptionalFile "C:\TFTP-Root\ESXi41\vmkboot.gz" "ESXi 4.1 install boot image"
    Check-File "C:\TFTP-Root\ESXi50\weaselin.i00" "ESXi 5.0 install boot image"

    Write-Host "Check Domain" -foregroundcolor "cyan"
    $domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain() 
    If ( $domain.Name -eq "lab.local")
    {write-host ("Correct Domain") -foregroundcolor "green"}
    Else
    {
        write-host ("Domain Broken") -foregroundcolor "red"
        $Global:Pass = $False
    }
    Write-Host "Check Services"  -foregroundcolor "cyan"
    Check-ServiceRunning "Active Directory Domain Services"
    Check-ServiceRunning "DHCP Server"
    Check-ServiceRunning "DNS Server"
    Check-ServiceRunning "Netlogon"
    Check-ServiceRunning "Tftpd32_svc"
    Check-ServiceRunning "SQL Server (SQLEXPRESS)"
    Check-ServiceRunning "SQLBrowser"
    Check-ServiceRunning "VMTools"
    Write-Host "Check DNS"  -foregroundcolor "cyan"
    Check-DNSRecord ("dc.lab.local")
    Check-DNSRecord ("vc.lab.local")
    Check-DNSRecord ("vma.lab.local")
    Check-DNSRecord ("nas.lab.local")
    Check-DNSRecord ("host1.lab.local")
    Check-DNSRecord ("host2.lab.local")
    Check-DNSRecord ("192.168.199.4")
    Check-DNSRecord ("192.168.199.5")
    Check-DNSRecord ("192.168.199.6")
    Check-DNSRecord ("192.168.199.7")
    Check-DNSRecord ("192.168.199.11")
    Check-DNSRecord ("192.168.199.12")
}
If ( $CompName -eq "VC")
{
    Write-Host "Check Files" -foregroundcolor "cyan"
    Check-File "C:\ProgramData\VMware\VMware VirtualCenter\sysprep\svr2003\sysprep.exe" "Windows 2003 SysPrep"
    Check-File "C:\ProgramData\VMware\VMware VirtualCenter\sysprep\xp\sysprep.exe" "Windows XP SysPrep"
    Write-Host "Check Services" -foregroundcolor "cyan"
    Check-ServiceRunning "VMTools"
    Check-ServiceRunning "VMware VirtualCenter Management Webservices"
    Check-ServiceRunning "VMware VirtualCenter Server"
    $VCReg = Get-ItemProperty -Path "HKLM:\SOFTWARE\VMware, Inc.\VMware VirtualCenter"
    If ($VCReg.InstalledVersion.StartsWith("4")) {Check-ServiceRunning "VMware vCenter Update Manager Service"}
    If ($VCReg.InstalledVersion.StartsWith("5")) {Check-ServiceRunning "VMware vSphere Update Manager Service"}
    Check-ServiceRunning "ADAM_VMwareVCMSDS"
}
Write-Host "The final result" -foregroundcolor "cyan"
If ($Global:Pass -eq $False )
{
    write-host ("*****************************************") -foregroundcolor "red"
    write-host ("*") -foregroundcolor "red"
    write-host ("* Oh dear, we seem to have a problem") -foregroundcolor "red"
    write-host ("*") -foregroundcolor "red"
    write-host ("* Check the build log to see what failed") -foregroundcolor "red"
    write-host ("*") -foregroundcolor "red"
    write-host ("*****************************************") -foregroundcolor "red"
}
Else
{
    write-host ("**************************************") -foregroundcolor "green"
    write-host ("*") -foregroundcolor "green"
    write-host ("*   Build looks good") -foregroundcolor "green"
    write-host ("*") -foregroundcolor "green"
    write-host ("*   Move on to the next stage") -foregroundcolor "green"
    write-host ("*") -foregroundcolor "green"
    write-host ("**************************************") -foregroundcolor "green"
}