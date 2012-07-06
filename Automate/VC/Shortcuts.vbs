set WshShell = WScript.CreateObject("WScript.Shell")
set oShortCutLink = WshShell.CreateShortcut("C:\Users\Public\Desktop\vSphere.lnk")
oShortCutLink.TargetPath = "C:\Program Files (x86)\VMware\Infrastructure\Virtual Infrastructure Client\Launcher\VpxClient.exe"
oShortCutLink.Arguments = "-s vc.lab.local -PassthroughAuth"
oShortCutLink.Save

set oShortCutLink = WshShell.CreateShortcut("C:\Users\Public\Desktop\VMware vSphere Client.lnk")
oShortCutLink.TargetPath = "C:\Program Files (x86)\VMware\Infrastructure\Virtual Infrastructure Client\Launcher\VpxClient.exe"
oShortCutLink.Save
 
set oShortCutLink = WshShell.CreateShortcut("C:\Users\Public\Desktop\Build Log.lnk")
oShortCutLink.TargetPath = "c:\BuildLog.txt"
oShortCutLink.Save

set oShortCutLink = WshShell.CreateShortcut("C:\Users\Public\Desktop\Validate.lnk")
oShortCutLink.TargetPath = "%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe"
oShortCutLink.Arguments = " -noexit c:\validate.ps1"
oShortCutLink.Save

set oShortCutLink = WshShell.CreateShortcut("C:\Users\Public\Desktop\Shutdown Lab.lnk")
oShortCutLink.TargetPath = "%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe"
oShortCutLink.Arguments = " -noexit c:\shutlab.ps1"
oShortCutLink.Save

set oShortCutLink = WshShell.CreateShortcut("C:\Users\Public\Desktop\Add Hosts.lnk")
oShortCutLink.TargetPath = "%SystemRoot%\syswow64\WindowsPowerShell\v1.0\powershell.exe"
oShortCutLink.Arguments = " -noexit c:\AddHosts.ps1"
oShortCutLink.Save

set oShortCutLink = WshShell.CreateShortcut("C:\Users\Public\Desktop\Internet Explorer.lnk")
oShortCutLink.TargetPath = "C:\Program Files (x86)\Internet Explorer\iexplore.exe"
oShortCutLink.Save
