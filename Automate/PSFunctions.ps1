# Functions used in AutoLab PowerShell scripts
#
#
# Version 0.8
#

# This Function from the PowerCLI Blog
# http://blogs.vmware.com/vipowershell/2009/08/how-to-list-datastores-that-are-on-shared-storage.html
#
function Get-ShareableDatastore {
        # Get all datastores.
        $datastores = Get-Datastore
 
        # Load the HostStorageSystems of all hosts.
        $hosts = Get-VMHost | Get-View -property ConfigManager
        $storageSystems = @()
        foreach ($h in $hosts) {
                $sdi = Get-View $h.ConfigManager.StorageSystem -Property StorageDeviceInfo
                Write-Debug ("GSD: SDI for host $h is " + $sdi)
                $storageSystems += $sdi
        }
 
        foreach ($dso in $datastores) {
                $ds = $dso | Get-View -Property Info
 
                # Check if this datastore is NFS.
                $dsInfo = $ds.Info
                Write-Debug ("GSD: Is it NFS? " + $dsInfo.getType())
                if ($dsInfo -is [VMware.Vim.NasDatastoreInfo]) {
                        Write-Output $dso
                        continue
                }
 
                # Get the first extent of the datastore.
                $firstExtent = $dsInfo.Vmfs.Extent[0]
                Write-Debug ("GSD: first extent: " + $firstExtent.DiskName)
 
                # Find a host that maps this LUN.
                foreach ($hss in $storageSystems) {
                        $lun = $hss.StorageDeviceInfo.ScsiLun | Where { $_.CanonicalName -eq $firstExtent.DiskName }
 
                        if ($lun) {
                                Write-Debug ("GSD: found " + $lun.DeviceName + " on " + $hss.MoRef.Value)
                                Write-Debug ("GSD: LUN details: Name:" + $lun.DisplayName + ", Type:" + $lun.DeviceType + ", Vendor:" + $lun.Vendor + ", Model:" + $lun.Model)
 
                                # Search the adapter topology of this host, looking for the LUN.
                                $adapterTopology = $hss.StorageDeviceInfo.ScsiTopology.Adapter |
                                        Where { $_.Target |
                                                Where { $_.Lun |
                                                        Where { $_.ScsiLun -eq $lun.key }
                                                }
                                        } | Select -First 1
 
                                # We've found a host that has this LUN. Find how it maps to an adapter.
                                $adapter = $hss.StorageDeviceInfo.HostBusAdapter | Where { $_.Key -eq $adapterTopology.Adapter }
                                Write-Debug ("GSD: HBA type is: " + $adapter.getType())
 
                                # It's shared if it's Fibre Channel or iSCSI (we checked for NFS earlier)
                                if ($adapter -is [VMware.Vim.HostFibreChannelHba] -or $adapter -is [VMware.Vim.HostInternetScsiHba]) {
                                        Write-Debug "GSO: $dso is sharable"
                                        Write-Output $dso
                                }
 
                                # Otherwise it's not shared and we quit walking through hosts.
                                break
                        }
                }
        }
}

Function Check-File ($a, $b)
{
    if (test-Path $a) 
    {write-host ($b + " Found") -foregroundcolor "green"}
    Else
    {
        write-host ($b + " Missing") -foregroundcolor "red"
        $Global:Pass = $False
    }
}

Function Check-OptionalFile ($a, $b)
{
    if (test-Path $a) 
    {write-host ($b + " Found") -foregroundcolor "green"}
    Else
    {
        write-host ($b + " Missing") -foregroundcolor "Yellow"
    }
}

Function Check-ServiceRunning ($a)
{
    $SVC = Get-Service -name $a  -ErrorAction "SilentlyContinue"
    if ($SVC.Status -eq "Running") 
    {write-host ("Service " + $a + " Running") -foregroundcolor "green"}
    Else
    {
        write-host ("Service " + $a + " Not Running") -foregroundcolor "red"
        $Global:Pass = $False
    }
}

Function Check-DNSRecord ($a)
{
    $FWDIP = ""
    $ErrorActionPreference = "silentlycontinue"
    $FWDIP = [System.Net.Dns]::GetHostAddresses($a)
    $ErrorActionPreference = "continue"
    if ($FWDIP -eq "") 
    {
        write-host ("No DNS for " + $a ) -foregroundcolor "red"
        $Global:Pass = $False
    }
    Else
    {write-host ("DNS OK for " + $a) -foregroundcolor "green"}
}


function Test-Administrator  
{  
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)  
}

#
# This section from Luc Dekens http://www.lucd.info/2011/08/11/vmx-raiders-revisited/
#
Function Register-VMs ($a){
    # Collect .vmx paths of registered VMs on the datastore
    $registered = @{}
    $Datastore = Get-Datastore -name $a
    Get-VM -Datastore $Datastore | %{$_.Extensiondata.LayoutEx.File | where {$_.Name -like "*.vmx"} | %{$registered.Add($_.Name,$true)}}
    # Set up Search for .VMX Files in Datastore
    New-PSDrive -Name TgtDS -Location $Datastore -PSProvider VimDatastore -Root '\' | Out-Null
    $unregistered = @(Get-ChildItem -Path TgtDS: -Recurse | where {$_.FolderPath -notmatch ".snapshot" -and $_.Name -like "*.vmx" -and !$registered.ContainsKey($_.DatastoreFullPath)})
    Remove-PSDrive -Name TgtDS
    #Register all .vmx Files as VMs on the datastore
    foreach($VMXFile in $unregistered) {$null= New-VM -VMFilePath $VMXFile.DatastoreFullPath -VMHost $vmhost -Location "vm" -RunAsync}
}

#
# This section from dEPLOYMENT gUYS BLOG http://blogs.technet.com/b/deploymentguys/archive/2010/07/15/reading-and-modifying-ini-files-with-scripts.aspx
#

function Convert-IniFile ($file)
{
    $REGEX_INI_COMMENT_STRING = ";"
    $REGEX_INI_SECTION_HEADER = "^\s*(?!$($REGEX_INI_COMMENT_STRING))\s*\[\s*(.*[^\s*])\s*]\s*$"
    $REGEX_INI_KEY_VALUE_LINE = "^\s*(?!$($REGEX_INI_COMMENT_STRING))\s*([^=]*)\s*=\s*(.*)\s*$"

    $ini = @{}
    switch -regex -file $file {
        "$($REGEX_INI_SECTION_HEADER)" {
            $section = $matches[1]
            $ini[$section] = @{}
        }
        "$($REGEX_INI_KEY_VALUE_LINE)" {
            $name,$value = $matches[1..2]
            if ($name -ne $null -and $section -ne $null)
            {$ini[$section][$name] = $value }
        }
    }
    $ini
}
