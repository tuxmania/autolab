@echo off
echo **
echo * Enable DHCP
sc config dhcpserver start= auto > c:\buildlog.txt
echo **
echo * Setup recall of build script
copy \\192.168.199.7\Build\Automate\DC\Phase2.cmd c:\ >> c:\buildlog.txt
type \\192.168.199.7\Build\Automate\version.txt  >> c:\buildlog.txt
reg add HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run /v Build /t REG_SZ /d "cmd /c c:\Phase2.cmd" /f  >> c:\buildlog.txt
echo **
echo * Install Active Directory and reboot
copy \\192.168.199.7\Build\Automate\DC\dcpromo.txt c:\ >> c:\buildlog.txt
dcpromo /answer:c:\dcpromo.txt  >> c:\buildlog.txt
