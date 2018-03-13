terraform {
  backend "s3" {
    # Configured by `terraform init`
    bucket = "snm-nl-operations-goterrible-development-config"
    key = "tfstate/supla/terraform.tfstate"
    region = "eu-west-1"
  }
}