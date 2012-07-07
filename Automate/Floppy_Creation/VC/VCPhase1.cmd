@echo off
type \\192.168.199.7\Build\Automate\version.txt  >> c:\buildlog.txt
echo **
echo * Connexion au partage réseau "\\192.168.199.7\Build"
net use B: \\192.168.199.7\Build >> c:\buildlog.txt
echo **
echo * Début de la phase 2, sans reboot 
call b:\Automate\VC\VCPhase2.cmd
