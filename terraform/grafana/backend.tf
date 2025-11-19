  terraform{
    backend "s3" {
        bucket = "chronyka-monitoring-state" # O mesmo bucket
        key    = "dummy"   # Chave ÚNICA para o QA
        region = "us-east-1"
        encrypt = true
    }
  }
