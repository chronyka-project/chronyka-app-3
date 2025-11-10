
# 1. Obter o Datacenter pelo Nome
data "vsphere_datacenter" "datacenter" {
  name = "Chronyka-Datacenter" 
}

# 2. Obter o Resource Pool
data "vsphere_resource_pool" "pool" {
  name          = "172.16.58.67/Resources" 
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

# 3. Obter o Datastore
data "vsphere_datastore" "datastore" {
  name          = "datastore1"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

# 4. Obter o Template da VM
data "vsphere_virtual_machine" "template" {
  name          = "VM-TEMPLATE_CLONE_DO_CLONE"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

# Obtém o ID da Rede onde a nova VM será conectada
data "vsphere_network" "network" {
  name          = "VM Network"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}
