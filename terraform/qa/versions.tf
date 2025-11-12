
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = ">= 2.7.0"
    }
  }

  backend "s3" {
    bucket = "chronyka-terraform-state" 
    key    = "app-3/qa/terraform.tfstate"   
    region = "us-east-1"
    encrypt = true
  }
}
