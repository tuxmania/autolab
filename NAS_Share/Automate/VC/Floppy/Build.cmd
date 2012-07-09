@echo off
echo **
echo * Install dotnet 3.5
start /wait \\192.168.199.7\build\VIM_50\redist\dotnet\dotnetfx35.exe /qb /norestart
echo **
echo * Install Load Storm by Andrew Mitchel
start /wait msiexec /i "a:\Load Storm.msi" /q
echo **
echo * Disable screen lock
regedit /s a:\NoSCRNSave.reg
echo **
echo * Install VMware Tools and reboot
start /wait \\192.168.199.7\build\VMTools\Setup.exe /s /v "/qn"
timeout 60