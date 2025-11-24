variable "grafana_url" {
  description = "A URL base do seu servidor Grafana (ex: http://172.16.58.77:3000)"
  type        = string
}

variable "grafana_api_key" {
  description = "A chave de API do Grafana com permissões de Admin/Editor"
  type        = string
  sensitive   = true
}

variable "datasource_name" {
  description = "Nome da fonte de dados Prometheus no Grafana"
  type        = string
  default     = "Prometheus" # Altere se o nome da sua fonte de dados Prometheus for diferente
}

variable "environment" {
  description = "Nome do ambiente (dev, qa, prod)"
  type        = string
}

variable "app_name" {
  description = "Nome da aplicação"
  type        = string
}