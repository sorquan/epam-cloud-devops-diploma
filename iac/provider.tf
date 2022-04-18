provider "aws" {
  region     = var.provider_config["region"]
  access_key = var.provider_config["access_key"]
  secret_key = var.provider_config["secret_key"]

  default_tags {
    tags = {
      Deployment = "Terraform"
    }
  }
}