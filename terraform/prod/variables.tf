# Variáveis de Configuração

variable "region" {
  description = "Região AWS para implantação."
  type        = string
  default     = "us-east-1"
}

variable "app_name_todo" {
  description = "Nome base da aplicação todo (usado para tags e nomes de recursos)."
  type        = string
  default     = "app-todo"
}

variable "container_port" {
  description = "Porta que o container todo expõe (interna)."
  type        = number
  default     = 5000
}