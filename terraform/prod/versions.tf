terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Configuração do Backend State
  backend "s3" {
    bucket = "chronyka-terraform-state2" 
    key    = "app-3/prod/terraform.tfstate"   
    region = "us-east-1"
    encrypt = true
  }
}
