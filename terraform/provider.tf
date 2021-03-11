provider "aws" {
  region = var.region
}

#terraform {
#  backend "s3" {
#    bucket  = "terraform-state-duran"
#    key     = "terraform.tfstate"
#    region  = "us-east-1"
#    profile = "particular"
#  }
#}