
# 1. Configuração do Provedor
provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true
}

# 2. Definição da VM
resource "vsphere_virtual_machine" "vm_dev_todo" {
  name             = "dev-todo"
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id

  # Configurações do hardware
  num_cpus = 2
  memory   = 2048
  guest_id = "debian11_64Guest"

  # Disco principal.
  disk {
    label            = "disk0"
    size             = 20
  }
  
  # Adiciona a interface de rede à VM
  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = "vmxnet3"
  }

  # Clonagem a partir de um template
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    customize {
      # Use linux_options ou windows_options dependendo do seu template
      linux_options { 
        host_name = "dev-todo"
        domain    = "local" # Altere conforme seu domínio
      }

      # Configuração Estática da Rede
      network_interface {
        # O IP AGORA É CONHECIDO NO PLAN!
        ipv4_address = "172.16.58.4"  # <-- Use uma variável para o IP desejado!
        ipv4_netmask = 21            # <-- Use uma variável para a máscara!
      }

      # Gateway da rede
      ipv4_gateway = "172.16.58.254" # <-- Use uma variável para o gateway!
    }
  }
}