@echo off
echo **
echo * Connect to build share
Net use B: \\192.168.199.7\Build  >> c:\buildlog.txt
If not exist B:\VMTools\Setup64.exe goto NoBuild
type b:\automate\version.txt >> c:\buildlog.txt
echo ** 
echo * Install TFTP server
echo * Install TFTP server >> c:\buildlog.txt
md c:\TFTP-Root  >> c:\buildlog.txt
md "C:\Program Files\Tftpd64_SE" >> c:\buildlog.txt
xcopy b:\Automate\DC\Tftpd64_SE\*.* "C:\Program Files\Tftpd64_SE\" >> c:\buildlog.txt
"C:\Program Files\Tftpd64_SE\Tftpd64_SVC.exe" -install >> c:\buildlog.txt
sc config "Tftpd32_svc" start= auto >> c:\buildlog.txt
sc start "Tftpd32_svc" >> c:\buildlog.txt
xcopy b:\Automate\DC\TFTP-Root\*.* C:\TFTP-Root\ /s /y  >> c:\buildlog.txt
If not exist B:\ESX41\isolinux\initrd.img goto ESXi41
mkdir C:\TFTP-Root\ESX41 >> c:\buildlog.txt
echo ** 
echo * Add ESX 4.1 to TFTP 
echo * Add ESX 4.1 to TFTP  >> c:\buildlog.txt
xcopy B:\ESX41\isolinux\vmlinuz C:\TFTP-Root\ESX41 >> c:\buildlog.txt
xcopy B:\ESX41\isolinux\initrd.img C:\TFTP-Root\ESX41 >> c:\buildlog.txt

:ESXi41
If not exist b:\ESXi41\install.vgz goto ESXi50
echo ** 
echo * Add ESXi 4.1 to TFTP 
echo * Add ESXi 4.1 to TFTP  >> c:\buildlog.txt
mkdir C:\TFTP-Root\ESXi41 >> c:\buildlog.txt
xcopy b:\ESXi41\vmkboot.gz C:\TFTP-Root\ESXi41 >> c:\buildlog.txt
xcopy b:\ESXi41\vmkernel.gz C:\TFTP-Root\ESXi41 >> c:\buildlog.txt
xcopy b:\ESXi41\sys.vgz C:\TFTP-Root\ESXi41 >> c:\buildlog.txt
xcopy b:\ESXi41\cim.vgz C:\TFTP-Root\ESXi41 >> c:\buildlog.txt
xcopy b:\ESXi41\ienviron.vgz C:\TFTP-Root\ESXi41 >> c:\buildlog.txt
xcopy b:\ESXi41\install.vgz C:\TFTP-Root\ESXi41 >> c:\buildlog.txt
xcopy b:\ESXi41\mboot.c32 C:\TFTP-Root\ESXi41 >> c:\buildlog.txt

:ESXi50
If not exist b:\ESXi50\TOOLS.T00 goto ESXiDone
echo ** 
echo * Add ESXi 5.0 to TFTP 
echo * Add ESXi 5.0 to TFTP >> c:\buildlog.txt
mkdir C:\TFTP-Root\ESXi50  >> c:\buildlog.txt
xcopy b:\ESXi50\*.* C:\TFTP-Root\ESXi50 /s /c /q  >> c:\buildlog.txt
echo * Check for ESXi 5.0 RTM >> c:\buildlog.txt
b:\Automate\dc\hashdeep64 -r -a -k b:\Automate\dc\ESXi50RTM.md5 B:\ESXi50  >> c:\buildlog.txt
IF errorlevel 1 goto NotESXi50
echo * Found ESXi 5.0 RTM, adding to PXE  >> c:\buildlog.txt
copy b:\Automate\DC\ESXi5_0_RTM\b*.cfg C:\TFTP-Root\ESXi50 /y >> c:\buildlog.txt
Goto ESXiDone

:NotESXi50
echo * Check for ESXi 5.0 Update 1 >> c:\buildlog.txt
b:\Automate\dc\hashdeep64 -r -a -k b:\Automate\dc\ESXi50U1.md5 B:\ESXi50 >> c:\buildlog.txt
IF errorlevel 1 goto NotESXi50U1
echo * Found ESXi 5.0 Update 1, adding to PXE  >> c:\buildlog.txt
copy b:\Automate\DC\ESXi5_0_U1\b*.cfg C:\TFTP-Root\ESXi50 /y >> c:\buildlog.txt
Goto ESXiDone

:NotESXi50U1

:ESXiDone
echo ** 
echo * Authorise and configure DHCP
echo * Authorise and configure DHCP >> c:\buildlog.txt
netsh dhcp add server dc.lab.local 192.168.199.4 >> c:\buildlog.txt
netsh dhcp server 192.168.199.4 add scope 192.168.199.0 255.255.255.0 "Lab scope" "Scope for lab.local" >> c:\buildlog.txt
netsh dhcp server 192.168.199.4 scope 192.168.199.0 add iprange 192.168.199.100 192.168.199.199 >> c:\buildlog.txt
netsh dhcp server 192.168.199.4 scope 192.168.199.0 set optionvalue 003 IPADDRESS 192.168.199.2 >> c:\buildlog.txt
netsh dhcp server 192.168.199.4 scope 192.168.199.0 set optionvalue 005 IPADDRESS 192.168.199.4 >> c:\buildlog.txt
netsh dhcp server 192.168.199.4 scope 192.168.199.0 set optionvalue 006 IPADDRESS 192.168.199.4 >> c:\buildlog.txt
netsh dhcp server 192.168.199.4 scope 192.168.199.0 set optionvalue 015 STRING lab.local >> c:\buildlog.txt
netsh dhcp server 192.168.199.4 scope 192.168.199.0 set optionvalue 066 STRING 192.168.199.4 >> c:\buildlog.txt
netsh dhcp server 192.168.199.4 scope 192.168.199.0 set optionvalue 067 STRING pxelinux.0 >> c:\buildlog.txt
netsh dhcp server 192.168.199.4 scope 192.168.199.0 set state 1 >> c:\buildlog.txt
echo **
echo * Create DNS Records
echo * Create DNS Records >> c:\buildlog.txt
dnscmd localhost /config /UpdateOptions 0x0 >> c:\buildlog.txt
dnscmd localhost /zoneadd 199.168.192.in-addr.arpa /DsPrimary >> c:\buildlog.txt
dnscmd localhost /RecordAdd lab.local vc A 192.168.199.5 >> c:\buildlog.txt
dnscmd localhost /RecordAdd lab.local vma A 192.168.199.6 >> c:\buildlog.txt
dnscmd localhost /RecordAdd lab.local nas A 192.168.199.7 >> c:\buildlog.txt
dnscmd localhost /RecordAdd lab.local host1 A 192.168.199.11 >> c:\buildlog.txt
dnscmd localhost /RecordAdd lab.local host2 A 192.168.199.12 >> c:\buildlog.txt
dnscmd localhost /config lab.local /allowupdate 1 >> c:\buildlog.txt
dnscmd localhost /RecordAdd 199.168.192.in-addr.arpa 5 PTR vC.lab.local >> c:\buildlog.txt
dnscmd localhost /RecordAdd 199.168.192.in-addr.arpa 6 PTR vma.lab.local >> c:\buildlog.txt
dnscmd localhost /RecordAdd 199.168.192.in-addr.arpa 7 PTR nas.lab.local >> c:\buildlog.txt
dnscmd localhost /RecordAdd 199.168.192.in-addr.arpa 11 PTR host1.lab.local >> c:\buildlog.txt
dnscmd localhost /RecordAdd 199.168.192.in-addr.arpa 12 PTR host2.lab.local >> c:\buildlog.txt
dnscmd localhost /config 199.168.192.in-addr.arpa /allowupdate 1 >> c:\buildlog.txt
dnscmd localhost /resetforwarders 192.168.199.2 /slave >> c:\buildlog.txt
echo **
echo * Install SQL Express
echo * Install SQL Express >> c:\buildlog.txt
b:\VIM_50\redist\SQLEXPR\SQLEXPR_x64_ENU.exe /IACCEPTSQLSERVERLICENSETERMS /action=Install /FEATURES=SQL,Tools /SQLSYSADMINACCOUNTS="Lab\Domain Admins" /SQLSVCACCOUNT="Lab\vi-admin" /SQLSVCPASSWORD="VMware1!" /AGTSVCACCOUNT="Lab\vi-admin" /AGTSVCPASSWORD="VMware1!" /ADDCURRENTUSERASSQLADMIN /SECURITYMODE=SQL /SAPWD="VMware1!" /INSTANCENAME=SQLExpress /BROWSERSVCSTARTUPTYPE="Automatic" /TCPENABLED=1 /NPENABLED=1 /SQLSVCSTARTUPTYPE=Automatic /qs  >> c:\buildlog.txt
If Not Exist B:\sqlmsssetup.exe Goto NoStudio
echo **
echo * Install SQL Express Management Studio
echo * Install SQL Express Management Studio >> c:\buildlog.txt
B:\sqlmsssetup.exe /ACTION=INSTALL /IACCEPTSQLSERVERLICENSETERMS /FEATURES=Tools /qs  >> c:\buildlog.txt

:NoStudio
timeout 30
echo **
echo * Create vCentre Database
echo * Create vCentre Database >> c:\buildlog.txt
"C:\Program Files\Microsoft SQL Server\100\Tools\Binn\sqlcmd.exe" -S dc\SQLEXPRESS -i B:\Automate\DC\MakeDB.txt >> c:\buildlog.txt
echo **
echo * elevate vi-admin rights
echo * elevate vi-admin rights >> c:\buildlog.txt
net group "Domain Admins" vi-admin /add >> c:\buildlog.txt
echo **
echo * Make Win32Time authoritative for NTP time 
echo * Make Win32Time authoritative for NTP time  >> c:\buildlog.txt
reg add HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\W32Time\Config /v AnnounceFlags /t REG_DWORD /d 0x05 /f >> c:\buildlog.txt
echo **
echo * Cleanup
echo * Cleanup >> c:\buildlog.txt
reg delete HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run /v Build /f >> c:\buildlog.txt
regedit /s b:\Automate\DC\ExecuPol.reg >> c:\buildlog.txt
regedit -s b:\Automate\Dc\NoSCRNSave.reg
wscript b:\Automate\DC\Shortcuts.vbs
copy b:\Automate\validate.ps1 c:\ >> c:\buildlog.txt
copy b:\Automate\PSFunctions.ps1 c:\ >> c:\buildlog.txt
if not exist b:\automate\automate.ini Goto NoAutoFile
@setlocal enableextensions enabledelayedexpansion
echo **
echo * Set Timezone
set currarea=
for /f "delims=" %%a in (b:\automate\automate.ini) do (
    set ln=%%a
    if "x!ln:~0,1!"=="x[" (
        set currarea=!ln!
    ) else (
        for /f "tokens=1,2 delims==" %%b in ("!ln!") do (
            set currkey=%%b
            set currval=%%c
            if "x[Automation]"=="x!currarea!" if "xTZ"=="x!currkey!" (
                tzutil /s "!currval!" >> c:\buildlog.txt
            )
        )
    )
)
@setlocal disableextensions disabledelayedexpansion

:NoAutoFile
echo **
echo * Installing VMware tools, build complete after reboot
echo * Installing VMware tools, build complete after reboot >> c:\buildlog.txt
echo *
echo * Rebuild vCentre next
echo **
B:\VMTools\setup64.exe /s /v "/qn" >> c:\buildlog.txt
timeout 30
del c:\phase2.cmd >> c:\buildlog.txt

:NoBuild
echo **
echo * Build sources not found, is the NAS VM running?
echo **
echo * Make sure Build share is available and populated
echo **
echo * Restart this machine when Build share is available
echo **
echo * Build will proceeed after restart
echo **
pause