# Script to add add ESX servers to vCenter and do initial configuration
#
#
# Version 0.8
#
#
. "C:\PSFunctions.ps1"
If (Test-Administrator){ 
    Write-host " "
    Write-Host "This script should not be 'Run As Administrator'" -foregroundcolor "Red"
    Write-host " "
    Write-Host "Just double click the shortcut" -foregroundcolor "Red"
    Write-host " "
    Exit    
}

Add-PSSnapin VMware.VimAutomation.Core
for ($i=1;$i -le 2; $i++){
    $vmhost = "host$i.lab.local"
    $ping = new-object System.Net.NetworkInformation.Ping
    $Reply = $ping.send($vmhost)
    if ($Reply.status –ne “Success”) {
        Write-Host $vmhost " not responding to ping, exiting"  -foregroundcolor "red"
        Write-Host "Re-run this script when both ESXi hosts are running"  -foregroundcolor "red"
        exit
    }
}
Write-Host " "
$AskDS=$True
$AskVM=$True
$AskKey=$True
If (Test-Path "b:\automate\Automate.ini"){
    Write-Host "Found b:\automate\Automate.ini file, using settings from there" -foregroundcolor "Cyan"
    $iniFile = Convert-IniFile "b:\automate\Automate.ini" 
    Switch ($iniFile["Automation"]["BuildDatastores"]){
        "True"{
            $CreateDS = 0
            $AskDS=$False
        } 
        "true"{
            $CreateDS = 0
            $AskDS=$False
        } 
        "False"{
            $CreateDS = -1
            $AskDS=$False
        } 
        "False"{
            $CreateDS = -1
            $AskDS=$False
        } 
        "Ask"{ $AskDS=$True} 
        "ask"{ $AskDS=$True} 
    }
    
    Switch ($iniFile["Automation"]["BuildVM"]){
        "True"{
            $CreateVM = 0
            $AskVM=$False
        } 
        "true"{
            $CreateVM = 0
            $AskVM=$False
        } 
        "False"{
            $CreateVM = -1
            $AskVM=$False
        } 
        "False"{
            $CreateVM = -1
            $AskVM=$False
        } 
        "Ask"{ $AskVM=$True} 
        "ask"{ $AskVM=$True} 
    }
    $ProdKey = $iniFile["Automation"]["ProductKey"]
    $AskKey=$False
}
If ($AskDS) {
    $DSyes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Create New Datastores"
    $DSno = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Skip Datastore creation."
    $DSoptions = [System.Management.Automation.Host.ChoiceDescription[]]($DSyes, $DSno)
    $CreateDS = $host.ui.PromptForChoice("Create Datastores", "Do you want to automatically create datastores on the iSCSI LUNs?", $DSoptions, 0) 
}
If ($AskVM) {
    Write-Host " "
    $VMyes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Create WinTemplate VM."
    $VMno = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Skip VM creation."
    $VMoptions = [System.Management.Automation.Host.ChoiceDescription[]]($VMyes, $VMno)
    $CreateVM = $host.ui.PromptForChoice("Create VM", "Do you want to automatically create a VM and start installing windows?", $VMoptions, 0) 
    Write-Host " "
}
If (($ProdKey -eq "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX") -or ($AskKey=$False)){
    Write-Host "Please enter windows product key to use in Guest OS Customization spec"  -foregroundcolor "cyan"
    $ProdKey = read-Host "Product Key"
    write-Host " "
}
Write-Host "Connect to vCenter, this takes a while and will show a Warning in yellow"  -foregroundcolor "Green"
$Null = connect-viserver vc.lab.local
Write-Host "Create Datacenter and Cluster"  -foregroundcolor "green"
if ((Get-DataCenter | where {$_.Name -eq "Lab"}) -eq $Null) {
    $Null = New-DataCenter -Location (Get-Folder -NoRecursion) -Name Lab
}    
if ((Get-Cluster | where {$_.Name -eq "local"}) -eq $Null) {
    $Cluster = New-Cluster Local -DRSEnabled -Location Lab -DRSAutomationLevel PartiallyAutomated 
}

for ($i=1;$i -le 2; $i++){
    $Num = $i +10
    $VMHost = "host"
    $VMHost += $i
    $VMHost += ".lab.local"
    $VMotionIP = "172.16.199."
    $VMotionIP += $Num
    $IPStoreIP1 = "172.17.199."
    $IPStoreIP1 += $Num
    $IPStoreIP2 = "172.17.199."
    $Num = $i +20
    $IPStoreIP2 += $Num
    $FTIP = "172.16.199."
    $FTIP += $Num
    $Num = $i +40
    $vHeartBeatIP = "172.16.199."
    $vHeartBeatIP += $Num
    Write-Host $VMHost -foregroundcolor "cyan"
    if ((Get-VMHost | where {$_.Name -eq $VMHost}) -eq $Null) {
        $VMHostObj = add-vmhost $VMhost -user root -password VMware1! -Location Lab -force:$true
        If ($VMHostObj.ConnectionState -ne "Connected"){
            Write-Host " "
            Write-Host "Connecting " $VMHost " has failed, is the ESXi server built?"  -foregroundcolor "red"
            Write-Host " "
            exit
        }
        If ($vmhostObj.ExtensionData.Config.Product.FullName.Contains("ESXi")) {
            # These services aren't relevent on ESX Classic, only ESXi
            $Null = Add-VmHostNtpServer -NtpServer “192.168.199.4” -VMHost $VMhost
            $ntp = Get-VMHostService -VMHost $VMhost | Where {$_.Key -eq ‘ntpd’}
            $Null = Set-VMHostService $ntp -Policy "On"
            $SSH = Get-VMHostService -VMHost $VMhost | Where {$_.Key -eq ‘TSM-SSH’}
            $Null = Set-VMHostService $SSH -Policy "On"
            $TSM = Get-VMHostService -VMHost $VMhost | Where {$_.Key -eq ‘TSM’}
            $Null = Set-VMHostService $TSM -Policy "On"
            if ($vmhostObj.version.split(".")[0] -ne "4"){ 
                $null = Set-VMHostAdvancedConfiguration -VMHost $VMhost -Name "UserVars.SuppressShellWarning" -Value 1
            }
        }
        $DSName = $VMHost.split('.')[0]
        $DSName += "_Local"
        $sharableIds = Get-ShareableDatastore | Foreach { $_.ID } 
        $Null = Get-Datastore -vmhost $vmhost | Where { $sharableIds -notcontains $_.ID } | Set-DataStore -Name $DSName
        $switch = Get-VirtualSwitch -vmHost $vmHost 
        $Null = set-VirtualSwitch $switch -Nic vmnic0,vmnic1 -confirm:$False
        $pg = New-VirtualPortGroup -Name vMotion -VirtualSwitch $switch -VLanId 16
        If ($vmhostObj.ExtensionData.Config.Product.FullName.Contains("ESXi")) {
            $Null = New-VMHostNetworkAdapter -VMHost $vmhost -Portgroup $pg -VirtualSwitch $switch -IP $VMotionIP -SubnetMask "255.255.255.0" -vMotionEnabled:$true -ManagementTrafficEnabled:$True
        } Else {
            $Null = New-VMHostNetworkAdapter -VMHost $vmhost -Portgroup $pg -VirtualSwitch $switch -IP $VMotionIP -SubnetMask "255.255.255.0" -vMotionEnabled:$true 
            $pg = New-VirtualPortGroup -Name vHeartBeat -VirtualSwitch $switch -VLanId 16
            $Null = New-VMHostNetworkAdapter -VMHost $vmhost -Portgroup $pg -VirtualSwitch $switch -IP $vHeartBeatIP -SubnetMask "255.255.255.0" -ConsoleNIC 
        }
        $pg = New-VirtualPortGroup -Name FT -VirtualSwitch $switch -VLanId 16
        $Null = New-VMHostNetworkAdapter -VMHost $vmhost -Portgroup $pg -VirtualSwitch $switch -IP $FTIP -SubnetMask "255.255.255.0" -FaultToleranceLoggingEnabled:$true
        $pg = New-VirtualPortGroup -Name IPStore1 -VirtualSwitch $switch -VLanId 17
        $Null = New-VMHostNetworkAdapter -VMHost $vmhost -Portgroup $pg -VirtualSwitch $switch -IP $IPStoreIP1 -SubnetMask "255.255.255.0" 
        $pg = New-VirtualPortGroup -Name IPStore2 -VirtualSwitch $switch -VLanId 17
        $Null = New-VMHostNetworkAdapter -VMHost $vmhost -Portgroup $pg -VirtualSwitch $switch -IP $IPStoreIP2 -SubnetMask "255.255.255.0" 
        $Null = Get-VMHostStorage $VMHost | Set-VMHostStorage -SoftwareIScsiEnabled $true
        $Null = get-virtualportgroup -name vMotion | Get-NicTeamingPolicy | Set-NicTeamingPolicy -MakeNicActive vmnic1
        $Null = get-virtualportgroup -name vMotion | Get-NicTeamingPolicy | Set-NicTeamingPolicy -MakeNicStandby vmnic0
        $pnic = (Get-VMhostNetworkAdapter -VMHost $VMHost -Physical)[2]
        $switch = New-VirtualSwitch -VMhost $vmHost -Nic $pnic.DeviceName -NumPorts 128 -Name vSwitch1
        $Null = New-VirtualPortGroup -Name Servers -VirtualSwitch $switch
        $Null = New-VirtualPortGroup -Name Workstations -VirtualSwitch $switch
        $Null = set-VirtualSwitch $switch -Nic vmnic2,vmnic3 -confirm:$False
        if ($vmhostObj.version.split(".")[0] -ne "4"){ 
            $Null = remove-datastore -VMhost $vmhost -datastore remote-install-location -confirm:$False
        }
        $Null = New-Datastore -nfs -VMhost $vmhost -Name Build -NFSHost "172.17.199.7" -Path "/mnt/LABVOL/Build" -readonly
        $MyIQN = "iqn.1998-01.com.vmware:" + $VMHost.split('.')[0]
        $Null = Get-VMHostHba -VMhost $vmhost -Type iScsi | Set-VMHostHBA -IScsiName $MyIQN 
        $Null = Get-VMHostHba -VMhost $vmhost -Type iScsi | New-IScsiHbaTarget -Address 172.17.199.7 -Type Send
        $Null = Get-VMHostStorage $VMHost -RescanAllHba
        $Null = Move-VMhost $VMHost -Destination Local
    }
}
Write-Host "Restart both hosts for consistency, takes a few minutes"  -foregroundcolor "cyan"
$Null = Restart-VMHost -VMHost host1.lab.local -confirm:$False -Force
$Null = Restart-VMHost -VMHost host2.lab.local -confirm:$False -Force
#Wait until both hosts disconnected
do {
    start-sleep 5
    $Host1 = Get-vmhost host1.lab.local
    $Host2 = Get-vmhost host2.lab.local
}
While  (($host1.ConnectionState -eq "Connected") -and ($host2.ConnectionState -eq "Connected"))
#Wait for both hosts reconnected
do {
    start-sleep 5
    $Host1 = Get-vmhost host1.lab.local
    $Host2 = Get-vmhost host2.lab.local
}
While  (($host1.ConnectionState -ne "Connected") -or ($host2.ConnectionState -ne "Connected"))
Write-Host "All connected"  -foregroundcolor "cyan"
if ((Get-OSCustomizationSpec | where {$_.Name -eq "Windows"}) -eq $Null) {
    $Null = New-OsCustomizationSpec -Name Windows -OSType Windows -FullName Lab -OrgName Lab.local -NamingScheme VM -ProductKey $ProdKey -LicenseMode PerSeat -AdminPass VMware1! -Workgroup Workgroup -ChangeSid -AutoLogonCount 999
}
If ($CreateDS -eq 0) {
    Write-Host "Create Datastores on iSCSI"  -foregroundcolor "green"
    $iSCSILUNs = get-scsilun -vmhost $VMHost -CanonicalName "t10.*"
    If ($vmhostobj.version.split(".")[0] -ne "4") {
        if (((Get-Datastore | where {$_.Name -eq "iSCSI1"}) -eq $Null) ) {
            $null = New-Datastore -VMHost $VMHost -Name iSCSI1 -Path $iSCSILUNs[2].CanonicalName -Vmfs -FileSystemVersion 5
            Write-Host "Created iSCSi1 Datstore"  -foregroundcolor "cyan"
        }
        Else {
	   Write-Host "Register all VMs found on existing datastore iSCSI1"  -foregroundcolor "cyan"
	   Register-VMs ("iSCSI1")
        }
    }
    if ((Get-Datastore | where {$_.Name -eq "iSCSI2"}) -eq $Null) {
        $null = New-Datastore -VMHost $VMHost -Name iSCSI2 -Path $iSCSILUNs[1].CanonicalName -Vmfs -FileSystemVersion 3
        Write-Host "Created iSCSi2 Datstore"  -foregroundcolor "cyan"
    }
    Else {
	Write-Host "Register all VMs found on existing datastore iSCSI2"  -foregroundcolor "cyan"
	Register-VMs ("iSCSI2")
    }
    if ((Get-Datastore | where {$_.Name -eq "iSCSI3"}) -eq $Null) {
        $null = New-Datastore -VMHost $VMHost -Name iSCSI3 -Path $iSCSILUNs[0].CanonicalName -Vmfs -FileSystemVersion 3
        Write-Host "Created iSCSi3 Datstore"  -foregroundcolor "cyan"
    }
    Else {
	Write-Host "Register all VMs found on existing datastore iSCSI3"  -foregroundcolor "cyan"
	Register-VMs ("iSCSI3")
    }
}    

Write-Host "Setup HA on Cluster, now that we have shared storage" -foregroundcolor "Green"
$Cluster = Get-Cluster -Name "Local"
$null = set-cluster -cluster $Cluster -HAEnabled:$True -HAAdmissionControlEnabled:$True -confirm:$False
$null = New-AdvancedSetting -Entity $cluster -Type ClusterHA -Name 'das.isolationaddress1' -Value "192.168.199.4" -confirm:$False -force
$null = New-AdvancedSetting -Entity $cluster -Type ClusterHA -Name 'das.usedefaultisolationaddress' -Value false -confirm:$False -force
$spec = New-Object VMware.Vim.ClusterConfigSpecEx
$Null = $spec.dasConfig = New-Object VMware.Vim.ClusterDasConfigInfo
$Null = $spec.dasConfig.admissionControlPolicy = New-Object VMware.Vim.ClusterFailoverResourcesAdmissionControlPolicy
$Null = $spec.dasConfig.admissionControlPolicy.cpuFailoverResourcesPercent = 50
$Null = $spec.dasConfig.admissionControlPolicy.memoryFailoverResourcesPercent = 50
$Cluster = Get-View $Cluster
$Null = $Cluster.ReconfigureComputeResource_Task($spec, $true)

if ($vmhostObj.version.split(".")[0] -eq "5"){ 
    $Datastore = Get-Datastore -VMhost $vmHost -name "iSCSI1"
    $VMName="WinTemplate"
} Else {
    $Datastore = Get-Datastore -VMhost $vmHost -name "iSCSI2"
    $VMName="WinTemplate4"
    Write-Host "Waiting four minutes for HA to complete configuration" -foregroundcolor "green"
    start-sleep 240
}
If (($CreateVM -eq 0) -and ((Get-VM -name $VMName -ErrorAction "SilentlyContinue") -eq $null )) {
    $null = New-PSDrive -Name iSCSI1 -PSProvider ViMdatastore -Root '\' -Location $Datastore 
    start-sleep 2
    #Create new VM if existing VM or template doesn't exist
    If (!(Test-Path iSCSI1:\$VMName\$VMName.vmdk)){
        Write-Host "Create first VM"  -foregroundcolor "green"
        (Get-Content b:\Automate\VC\Floppy\winnt.sif) | Foreach-Object {$_ -replace "xxxxx-xxxxx-xxxxx-xxxxx-xxxxx", $ProdKey} | Set-Content b:\Automate\VC\Floppy\winnt.sif
        b:\automate\vc\bfi.exe -f=b:\WinInstall.flp b:\automate\vc\floppy\ -t=6
        $MyVM = New-VM -Name $VMName -VMhost $vmHost -datastore $Datastore -NumCPU 1 -MemoryMB 384 -DiskMB 3072 -DiskStorageFormat Thin -GuestID winNetEnterpriseGuest
        $null = New-CDDrive -VM $MyVM -ISOPath [Build]WinInstall.iso -StartConnected
        $null = New-FloppyDrive -VM $MyVM -FloppyImagePath [Build]WinInstall.flp -StartConnected
        # PowerCLI to set boot order from http://communities.vmware.com/message/1889377
        $intHDiskDeviceKey = ($MyVM.ExtensionData.Config.Hardware.Device | ?{$_.DeviceInfo.Label -eq "Hard disk 1"}).Key
        $oBootableHDisk = New-Object -TypeName VMware.Vim.VirtualMachineBootOptionsBootableDiskDevice -Property @{"DeviceKey" = $intHDiskDeviceKey}
        $oBootableCDRom = New-Object -Type VMware.Vim.VirtualMachineBootOptionsBootableCdromDevice
        $spec = New-Object VMware.Vim.VirtualMachineConfigSpec -Property @{"BootOptions" = New-Object VMware.Vim.VirtualMachineBootOptions -Property @{BootOrder = $oBootableCDRom, $oBootableHDisk}} 
        $Null = $MyVM.ExtensionData.ReconfigVM_Task($spec)
        Write-Host "Power on VM and Install Windows"  -foregroundcolor "green"
        $Null = Start-VM $MyVM
    }
    Else{
        Write-Host "Found existing WinTemplate"  -foregroundcolor "green"
        If (Test-Path iSCSI1:\$VMName\$VMName.vmtx){
        Write-Host "Register existing WinTemplate template"  -foregroundcolor "green"
        $vmxFile = Get-Item iSCSI1:\$VMName\$VMName.vmtx
        $Null = New-Template -VMHost $VMHost -TemplateFilePath $vmxFile.DatastoreFullPath
        Write-Host "Existing WinTemplate Template added to inventory"  -foregroundcolor "cyan"
        }
    }
    start-sleep 2
    $null = Remove-PSDrive iSCSI1
}

Write-Host " "

$Null = Disconnect-VIServer -Server * -confirm:$False
