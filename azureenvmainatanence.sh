#!/bin/bash

#$1 for allvms or singlevm
#$2 is for start/dellocate/status
#$3 for resourcegroup  not required in allvms
#$3 for vmname    not required in allvms
comanrgnamestructure="CHS-RG-PERF-"
subscriptionid="subid"
inputrgname=$3
MyVm=$4  # Set MyVm to the fourth argument
datadiskname="diskname"
resourcegroups1=$(az group list --subscription $subscriptionid -o tsv | awk '{print $4}' | grep -i $comanrgnamestructure)
# Replace spaces with newlines in the resourcegroups string
resourcegroups=($(echo "$resourcegroups1" | tr ' ' '\n'))
if [[ $inputrgname == "FE" ]]; then
    resourcegroupname1=$(az group list --subscription $subscriptionid -o tsv | awk '{print $4}' | grep -i $comanrgnamestructure$inputrgname)
    resourcegroupname=($(echo "$resourcegroupname1" | tr ' ' '\n'))
    echo $resourcegroupname
elif [[ $inputrgname == "BE" ]]; then
    resourcegroupname1=$(az group list --subscription $subscriptionid -o tsv | awk '{print $4}' | grep -i $comanrgnamestructure$inputrgname)
    resourcegroupname=($(echo "$resourcegroupname1" | tr ' ' '\n'))
    echo $resourcegroupname
elif [[ $inputrgname == "DB" ]]; then
    resourcegroupname1=$(az group list --subscription $subscriptionid -o tsv | awk '{print $4}' | grep -i $comanrgnamestructure$inputrgname)
    resourcegroupname=($(echo "$resourcegroupname1" | tr ' ' '\n'))
    echo $resourcegroupname
else
    echo "nothing"
fi

az logout
az login --service-principal -u 'b2bd28c9-71bc-451e-93d4-4071c5774a6f' -p '1VH8Q~BQT5VYalABr6S9vE2eTc0jqcr8d-~oWaqj' --tenant '4500f2ab-1b42-4ed2-83a0-879a52ca1dce'
echo "Successfully login to CHSUS subscription"

startallvm() {
    local rgname="$1"
    echo "Performing start-action on resource group: $rgname"
    vm_names=$(az vm list -g $rgname --query "[].name" -o tsv)
    for vm_name in $vm_names; do
        echo "Starting VM with VM-Name $vm_name inside Resource_group $rgname"
        if [[ $vm_name == "chsperfmgeus0" ]] && [[ $rgname == "CHS-RG-PERF-DB-VM-DC" ]]; then
            echo "Starting Disk Conversion Standard to Premium for $datadiskname"
            az disk update --resource-group CHS-RG-PERF-DB-VM-DC --name $datadiskname --sku Premium_LRS
            echo "$datadiskname successfully converted to Premimium LRS"
        fi
        az vm start --resource-group "$rgname" --name "$vm_name"
        echo "$vm_name Started successfully"
        sleep 5
    done
            
}

deallocateallvm() {
    local rgname="$1"
    echo "Performing stop-action on resource group: $rgname"
    vm_names=$(az vm list -g $rgname --query "[].name" -o tsv)
    for vm_name in $vm_names; do
        echo "Deallocating VM with VM-Name $vm_name inside Resource_group $rgname" 
        az vm deallocate --resource-group $rgname --name $vm_name
        echo "$vm_name Deallocated Successfully"
        if [[ $vm_name == "chsperfmgeus0" ]] && [[ $rgname == "CHS-RG-PERF-DB-VM-DC" ]]; then
            echo "Starting Disk Conversion Premium to Standard for $datadiskname"
            az disk update --resource-group $rgname --name $datadiskname --sku Standard_LRS
            echo "$datadiskname successfully converted to Standard LRS"
        fi
    done
}

statusallvm(){
    local rgname="$1"
    echo "Performing status-action on resource group: $rgname"
    vm_names=$(az vm list -g $rgname --query "[].name" -o tsv)
    for vm_name in $vm_names; do
        echo "Showing VM Status with VM-Name $vm_name inside Resource_group $rgname" 
        az vm get-instance-view --name $vm_name --resource-group $rgname --query instanceView.statuses[1] -o tsv
    done
}

startsinglevm() {
    echo "Going to start VM with name: $MyVm"
    if [[ $MyVm == "chsperfmgeus0" ]] && [[ $resourcegroupname == "CHS-RG-PERF-DB-VM-DC" ]]; then
        cnvttoPremium
    fi
    echo "VM : $MyVm Starting" 
    az vm start --resource-group $resourcegroupname --name $MyVm
    echo "$MyVm Startted Successfully"
}
deallocatesinglevm() {
    echo "Going to Deallocate VM with name: $MyVm"
    echo "$MyVm Deallocation Started"
    az vm deallocate --resource-group $resourcegroupname --name $MyVm
    echo "$MyVm Deallocated Successfully"
    if [[ $MyVm == "chsperfmgeus0" ]] && [[ $resourcegroupname == "CHS-RG-PERF-DB-VM-DC" ]]; then
        cnvttoStandard
    fi 
    
}
statussinglevm(){
    echo "Going to get status of VM with name: $MyVm"
    az vm get-instance-view --name $MyVm --resource-group $resourcegroupname --query instanceView.statuses[1] -o tsv
}

cnvttoPremium() {
    echo "Yes the VM name is chsperfmgeus0 So going to convert DataDisk TYPE To Premium"
    az disk update --resource-group $resourcegroupname --name $datadiskname --sku Premium_LRS
    echo "$datadiskname converted to Premium Sucessfully"
}
cnvttoStandard() {
    echo "Yes the VM name is chsperfmgeus0 So going to convert DataDisk TYPE To Standard"
    az disk update --resource-group $resourcegroupname --name $datadiskname --sku Standard_LRS
    echo "$datadiskname converted to Standard LRS Sucessfully"
}

if [[ $1 == "allvms" ]] && [[ $2 == "start" ]]; then
    echo "Starting all VMs"
    for rg in "${resourcegroups[@]}"; do
        startallvm "$rg"
    done
elif [[ $1 == "allvms" ]] && [[ $2 == "deallocate" ]]; then
    echo "Deallocating all VMs"
    for rg in "${resourcegroups[@]}"; do
        deallocateallvm "$rg"
    done
elif [[ $1 == "allvms" ]] && [[ $2 == "status" ]]; then
    echo "Current state of all VM"
    for rg in "${resourcegroups[@]}"; do
        statusallvm "$rg"
    done
elif [[ $1 == "singlevm" ]] && [[ $2 == "start" ]]; then
    echo "Starting single VM"
    startsinglevm
elif [[ $1 == "singlevm" ]] && [[ $2 == "status" ]]; then
    echo "Current State of single VM"
    statussinglevm
elif [[ $1 == "singlevm" ]] && [[ $2 == "deallocate" ]]; then
    echo "Deallocating single VM"
    deallocatesinglevm
else
    echo "Usage: $0 [alvms|singlevm] [start|deallocate|status] [ResourceGroup] [Forsinglevm->vmname]"
    exit 1
fi
