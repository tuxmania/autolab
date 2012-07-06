@echo off
echo *************************
echo *
echo **
echo * Connect to build share
net use B: \\192.168.199.7\Build >> c:\buildlog.txt
type b:\automate\version.tct  >> c:\buildlog.txt
echo *
echo * Transfer to vcbuild2.cmd 
call b:\Automate\VC\VCBuild2.cmd