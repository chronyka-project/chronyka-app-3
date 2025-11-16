# 1. Configuração do Provedor Grafana
terraform {
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 2.15"
    }
  }
}

provider "grafana" {
  url  = var.grafana_url
  auth = var.grafana_api_key
}

# 2. Recurso: Fonte de Dados Prometheus (Garante que ela exista)
resource "grafana_data_source" "prometheus" {
  type        = "prometheus"
  name        = var.datasource_name
  url         = "http://localhost:9090" # Assumindo que Prometheus roda na mesma VM que o Grafana, na porta 9090
  is_default  = false
  access_mode = "proxy"
}

# Local para gerar o JSON do Dashboard dinamicamente
locals {
  # Isso irá ler o arquivo flask_metrics.json.tftpl e substituir ${environment}
  dashboard_config = templatefile("${path.module}/dashboards/todo_metrics.json.tftpl", {
    environment = var.environment
  })
}

# 3. Recurso: Importação do Dashboard
resource "grafana_dashboard" "todo_app_dashboard" {
  # 🛑 REMOVIDO: O atributo 'uid' foi removido daqui
  # uid   = "flask-app-${var.environment}" 
  
  # 🟢 ALTERADO: Usa o local gerado dinamicamente
  config_json = local.dashboard_config
  overwrite   = true
}

/*resource "grafana_dashboard" "flask_app_dashboard" {
  template_id = 15053
  title       = "Flask App - ${var.environment}"
  folder_uid  = grafana_folder.ambiente_folder.uid 
  overwrite   = true
}*/