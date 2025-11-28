output "new_vm_ip" {
  value       = vsphere_virtual_machine.vm_dev_todo_2.guest_ip_addresses[0]
  description = "O endereço IP da VM Debian recém-provisionada."
}