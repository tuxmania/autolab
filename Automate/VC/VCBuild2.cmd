@echo off
if not exist b:\automate\automate.ini Goto NoAutoFile
@setlocal enableextensions enabledelayedexpansion
set currarea=
for /f "delims=" %%a in (b:\automate\automate.ini) do (
    set ln=%%a
    if "x!ln:~0,1!"=="x[" (
        set currarea=!ln!
    ) else (
        for /f "tokens=1,2 delims==" %%b in ("!ln!") do (
            set currkey=%%b
            set currval=%%c
            if "x[Automation]"=="x!currarea!" if "xVCInstall"=="x!currkey!" (
                Set VCInstall=!currval!
            )
        )
    )
)

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
If "A%VCInstall%A"=="A5A" goto vCenter5
If "A%VCInstall%A"=="A4A" goto vCenter4
If "A%VCInstall%A"=="ABaseA" goto Base
If "A%VCInstall%A"=="ANoneA" goto None

:NoAutoFile
echo **
echo * About to automate vCenter install.
echo *
echo * How much automation would you like?
echo *
echo * Press N for None, VMware Tools only
echo *       B for base, SQL client, ODBC DSN and Sysprep files
echo *       4 for vCenter 4.1 install
echo *       5 for vCenter 5.0 install
choice /c B45N /M "Select Automation level"
IF errorlevel 4 goto None
IF errorlevel 3 goto vCenter5
IF errorlevel 2 goto vCenter4
IF errorlevel 1 goto Base

:vCenter5
echo * vCenter 5.0 automation >> c:\buildLog.txt
echo * vCenter 5.0 automation
set Build=VC5
goto Base

:vCenter4
echo * vCenter 4.1 Automation >> c:\buildLog.txt
echo * vCenter 4.1 automation 
echo **
set Build=VC4
goto Base

:Base
echo **
echo * Install SQL Client
echo * Install SQL Client >> c:\buildLog.txt
md c:\temp
start /wait b:\VIM_50\redist\SQLEXPR\SQLEXPR_x64_ENU.exe /extract:c:\temp /quiet
if exist C:\temp\pcusource\1033_enu_lp\x64\setup\x64\sqlncli.msi copy C:\temp\pcusource\1033_enu_lp\x64\setup\x64\sqlncli.msi c:\temp >> c:\buildLog.txt
if exist C:\temp\1033_enu_lp\x64\setup\x64\sqlncli.msi copy C:\temp\1033_enu_lp\x64\setup\x64\sqlncli.msi c:\temp >> c:\buildLog.txt
start /wait msiexec /i C:\temp\sqlncli.msi ADDLOCAL=ALL IACCEPTSQLNCLILICENSETERMS=YES /qb
rd /s /q c:\temp
echo **
echo * Install 7Zip
echo * Install 7Zip >> c:\buildLog.txt
regedit /s b:\Automate\VC\vCenterDB.reg>> c:\buildLog.txt

echo **
echo * Create ODBC DSN
echo * Create ODBC DSN >> c:\buildLog.txt
start /wait msiexec /qb /i b:\Automate\VC\7z920-x64.msi  >> c:\buildLog.txt

if %Build% == VC5 Goto VC5
if %Build% == VC4 Goto VC4
Goto End

:VC5
echo * Install vCenter 5.0
echo * Install vCenter 5.0 >> c:\buildLog.txt
start /wait B:\VIM_50\vCenter-Server\VMware-vcserver.exe /q /s /w /L1033 /v" /qr WARNING_LEVEL=0 USERNAME=\"Lab\" COMPANYNAME=\"lab.local\" DB_SERVER_TYPE=Custom DB_DSN=\"VCenterDB\" DB_USERNAME=\"vpx\" DB_PASSWORD=\"VMware1!\" VPX_USES_SYSTEM_ACCOUNT=\"1\" FORMAT_DB=1 VCS_GROUP_TYPE=Single"
echo **
echo * Install vSphere Client 5.0
echo * Install vSphere Client 5.0 >> c:\buildLog.txt
start /wait B:\VIM_50\vSphere-Client\VMware-viclient.exe /q /s /w /L1033 /v" /qr"
echo **
echo * Install vSphere Client 5.0 VUM Plugin
echo * Install vSphere Client 5.0 VUM Plugin >> c:\buildLog.txt
start /wait B:\VIM_50\updateManager\VMware-UMClient.exe /q /s /w /L1033 /v" /qr"
echo **
echo * Install vCenter Update Manager 5.0
echo * Install vCenter Update Manager 5.0 >> c:\buildLog.txt
start /wait B:\VIM_50\updateManager\VMware-UpdateManager.exe /L1033 /v" /qn VMUM_SERVER_SELECT=192.168.199.5 VC_SERVER_IP=vc.lab.local VC_SERVER_ADMIN_USER=\"administrator\" VC_SERVER_ADMIN_PASSWORD=\"VMware1!\" VCI_DB_SERVER_TYPE=Custom VCI_FORMAT_DB=1 DB_DSN=\"VUM\" DB_USERNAME=\"vpx\" DB_PASSWORD=\"VMware1!\" "
goto DoSysPrep

:VC4
echo **
echo * Install vCenter 4.1
echo * Install vCenter 4.1 >> c:\buildLog.txt
start /wait B:\VIM_41\vpx\VMware-vcserver.exe /q /s /w /L1033 /v" /qr WARNING_LEVEL=0 USERNAME=\"Lab\" COMPANYNAME=\"lab.local\" DB_SERVER_TYPE=Custom DB_DSN=\"VCenterDB\" DB_USERNAME=\"vpx\" DB_PASSWORD=\"VMware1!\" VPX_USES_SYSTEM_ACCOUNT=\"1\" FORMAT_DB=1 VCS_GROUP_TYPE=Single"
echo **
echo * Install vSphere Client 4.1
echo * Install vSphere Client 4.1 >> c:\buildLog.txt
start /wait B:\VIM_41\vpx\VMware-viclient.exe /q /s /w /L1033 /v" /qr"
echo **
echo * Install vSphere Client 4.1 VUM Plugin
echo * Install vSphere Client 4.1 VUM Plugin >> c:\buildLog.txt
start /wait B:\VIM_41\updateManager\VMware-UMClient.exe /q /s /w /L1033 /v" /qr"
timeout 30
echo **
echo * Install vCenter Update Manager 4.1
echo * Install vCenter Update Manager 4.1 >> c:\buildLog.txt
start /wait B:\VIM_41\updateManager\VMware-UpdateManager.exe /L1033 /v" /qn VMUM_SERVER_SELECT=192.168.199.5 VC_SERVER_IP=vc.lab.local VC_SERVER_ADMIN_USER=\"administrator\" VC_SERVER_ADMIN_PASSWORD=\"VMware1!\" VCI_DB_SERVER_TYPE=Custom VCI_FORMAT_DB=1 DB_DSN=\"VUM\" DB_USERNAME=\"vpx\" DB_PASSWORD=\"VMware1!\" "
goto DoSysPrep

:DoSysPrep
echo **
echo **
echo * Populate Sysprep files
echo * Populate Sysprep files >> c:\buildLog.txt
"C:\Program Files\7-Zip\7z.exe" e b:\wininstall.iso -r -oC:\ Deploy.cab >> c:\buildLog.txt
expand C:\deploy.cab -f:* "C:\ProgramData\VMware\VMware VirtualCenter\sysprep\svr2003" >> c:\buildLog.txt
expand C:\deploy.cab -f:* "C:\ProgramData\VMware\VMware VirtualCenter\sysprep\xp" >> c:\buildLog.txt
del C:\deploy.cab 

:End
timeout 60
echo **
If not Exist b:\VMware-vSphere-CLI.exe goto NovCLI
echo * Install VMware vSphere CLI
echo * Install VMware vSphere CLI >> c:\buildLog.txt
start /wait b:\VMware-vSphere-CLI.exe /S /v/qn
timeout 120

:NovCLI
echo **
echo * Install VMware PowerCLI
echo * Install VMware PowerCLI >> c:\buildLog.txt
start /wait b:\VMware-PowerCLI.exe /S /v/qn
timeout 90
del "C:\Users\Public\Desktop\*.lnk"
wscript b:\Automate\vc\Shortcuts.vbs
regedit /s b:\Automate\VC\ExecuPol.reg >> c:\buildLog.txt
echo **
echo * Deploy PuTTY
echo * Deploy PuTTY >> c:\buildLog.txt
copy b:\Automate\vc\PuTTY.exe C:\Users\Public\Desktop\  >> c:\buildLog.txt
regedit -s b:\Automate\vc\PuTTY.reg
echo **
echo * Cleanup
regedit -s b:\Automate\vc\NoSCRNSave.reg
regedit -s b:\Automate\vc\vSphereClient.reg
del c:\eula*.* >> c:\buildLog.txt
del c:\install*.*  >> c:\buildLog.txt
del c:\VC* >> c:\buildLog.txt

:None
copy b:\Automate\*.ps1 c:\  >> c:\buildLog.txt
echo **
echo * Install VMware Tools  
echo * Install VMware Tools  >> c:\buildLog.txt
b:\VMTools\Setup64.exe /s /v "/qn"
timeout 60
