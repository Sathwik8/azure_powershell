function Add-MCDataDisk {
<#
    https://docs.microsoft.com/en-us/azure/virtual-machines/windows/tutorial-manage-data-disk
    https://docs.microsoft.com/en-us/powershell/module/az.compute/new-azdiskconfig?view=azps-3.5.0    
#>    
    [CmdLetBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $VMName,
        [int]    $DiskSizeGB, # 128
        [ValidateSet('Premium_LRS', 'StandardSSD_LRS', 'UltraSSD_LRS', 'Standard_LRS')]
        [string] $SkuName = 'Premium_LRS', #   Premium_LRS, StandardSSD_LRS, and UltraSSD_LRS,  Standard_LRS,
        [string] $ResourceGroupName
    )
    $fn = $MyInvocation.MyCommand.Name

    # Get the existing Disk 
    $vm = Get-AzVM -Name $VMName
    $dd = $vm.StorageProfile.DataDisks
    $newLun = $dd[$dd.Count -1].Lun + 1
    $diskName = "{0}_DataDisk_{1}" -f $VMName, $newLun
    $tags = $vm.Tags

    # Create disk config
    $diskConfig = New-AzDiskConfig -Location $vm.Location -CreateOption Empty -DiskSizeGB $DiskSizeGB -SkuName $SkuName -Tag $tags

    # Create the data disk
    $dataDisk = New-AzDisk -ResourceGroupName $vm.ResourceGroupName -DiskName $diskName -Disk $diskConfig

    # Add disk to the VM config
    $vm = Add-AzVMDataDisk -VM $vm -Name $diskName -CreateOption Attach -ManagedDiskId $dataDisk.Id -Lun $newLun -Caching ReadOnly

    # Update VM with the new disk
    Update-AzVM  -VM $vm -ResourceGroupName $vm.ResourceGroupName 	
}

Add-MCDataDisk -VMName $VMName -DiskSizeGB $DiskSizeGB -SkuName $SkuName
