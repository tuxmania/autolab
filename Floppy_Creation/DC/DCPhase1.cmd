@echo off
type \\192.168.199.7\Build\Automate\version.txt  >> c:\buildlog.txt
echo **
echo * Activation du serveur DHCP
sc config dhcpserver start= auto >> c:\buildlog.txt
echo **
echo * Préparation de la phase 2 pour le prochain reboot
copy \\192.168.199.7\Build\Automate\DC\DCPhase2.cmd c:\ >> c:\buildlog.txt
reg add HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run /v Build /t REG_SZ /d "cmd /c c:\DCPhase2.cmd" /f  >> c:\buildlog.txt
echo **
echo * Installation d'Active Directory et reboot
copy \\192.168.199.7\Build\Automate\DC\dcpromo.txt c:\ >> c:\buildlog.txt
dcpromo /answer:c:\dcpromo.txt  >> c:\buildlog.txt
