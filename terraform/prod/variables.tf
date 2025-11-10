# Variáveis
# ==============================================================================
variable "app_name" {
  description = "Nome da Aplicação e do ambiente"
  default     = "todo-prod"
}

variable "ami_id" {
  description = "ID da AMI personalizada pronta"
  default     = "ami-0d49d937cd969fb11"
}

variable "key_name" {
  description = "Nome da sua Key Pair da AWS para SSH/Ansible"
  default     = "flask-key"
}