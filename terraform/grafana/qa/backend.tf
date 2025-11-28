  terraform{
    backend "s3" {
        bucket = "chronyka-monitoring-state" # O mesmo bucket
        key    = "app-3/qa/terraform.tfstate"   # Chave ÚNICA para o QA
        region = "us-east-1"
        encrypt = true
    }
  }
