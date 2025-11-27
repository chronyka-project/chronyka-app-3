# 1. Variável para o Usuário
variable "vsphere_user" {
  description = "vCenter username"
  type        = string
}

# 2. Variável para a Senha
variable "vsphere_password" {
  description = "vCenter password"
  type        = string
  sensitive   = true
}

# 3. Variável para o Servidor
variable "vsphere_server" {
  description = "vCenter Server hostname or IP"
  type        = string
}

# Variável para ignorar SSL
variable "vsphere_allow_unverified_ssl" {
  description = "Permitir certificados auto-assinados"
  type        = bool
  default     = true
}