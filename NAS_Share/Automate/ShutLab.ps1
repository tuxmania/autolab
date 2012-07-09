# Script to Shutdown AutoLab
#
#
# Version 0.8
#
#
Write-Host " "
Write-Host "This script will shutdown your lab, enter Y to proceed"  -foregroundcolor "cyan"
$ReBuild = Read-Host 
If ([string]::Compare($ReBuild, "Y", $True) -eq "0"){
    Write-Host "Shutting down your lab" -foregroundcolor "cyan"
    Add-PSSnapin VMware.VimAutomation.Core
    Write-Host "Connect to vCenter" -foregroundcolor "Green"
    $null = connect-viserver vc.lab.local
    Write-Host "Shutdown any running VMs" -foregroundcolor "Green"
    $null = get-VM | Where-Object {$_.PowerState -eq "PoweredOn"}| stop-vm -Confirm:$false
    Write-Host "Shutdown ESX servers" -foregroundcolor "Green"
    $null = get-VMhost | stop-vmhost -Confirm:$false -force
    Write-Host "Shutdown DC" -foregroundcolor "Green"
    $null = stop-Computer -comp dc.lab.local -force
    Write-Host "Shutdown VC" -foregroundcolor "Green"
    $null = stop-Computer -comp vc.lab.local -force
    Write-Host "Exit and wait for everything to go away" -foregroundcolor "cyan"
} Else {
Write-Host "Leaving your lab running" -foregroundcolor "cyan"
}