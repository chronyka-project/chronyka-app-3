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
  name        = "prometheus-${var.environment}-${var.app_name}"
  url         = "http://localhost:9090" # Assumindo que Prometheus roda na mesma VM que o Grafana, na porta 9090
  is_default  = false
  access_mode = "proxy"
}

# Local para gerar o JSON do Dashboard dinamicamente
locals {
  dashboard_config = jsondecode(
    templatefile("${path.module}/../dashboards/todo_metrics.json.tftpl", {
      environment = var.environment
      datasource_name = grafana_data_source.prometheus.name
    })
  )
}

resource "grafana_dashboard" "todo_app_dashboard" {
  overwrite   = true
  config_json = jsonencode(local.dashboard_config)
}