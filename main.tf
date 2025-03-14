# Main Terraform configuration

# AWS Infrastructure
module "aws" {
  source = "./modules/aws"

  aws_region   = var.aws_region
  environment  = var.environment
  project_name = var.project_name
}

# Azure Infrastructure
module "azure" {
  source = "./modules/azure"

  azure_location = var.azure_location
  environment    = var.environment
  project_name   = var.project_name
}

# GCP Infrastructure
module "gcp" {
  source = "./modules/gcp"

  gcp_region   = var.gcp_region
  environment  = var.environment
  project_name = var.project_name
}
