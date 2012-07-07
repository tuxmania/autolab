@echo off
echo **
echo * Connect to build share \\192.168.199.7\Build
net use B: \\192.168.199.7\Build >> c:\buildlog.txt
type b:\automate\version.tct  >> c:\buildlog.txt
echo *
echo * Transfer to VCPhase2.cmd 
call b:\Automate\VC\VCPhase2.cmd
