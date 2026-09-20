terraform {
  backend "s3" {
    bucket = "afee87ae65ab4365-terraform-remote-backend"
    key    = "terraform/state/aws-dev/supabase/terraform.tfstate"
    region = "eu-central-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}