terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.43.0"
    }
  }

  backend "gcs" {
    bucket = "ad5e09f20ca25d86-terraform-remote-backend"
    prefix = "terraform/state/gcp-dev/supabase"
  }
}

provider "google" {
  project = "unreal-465316"
}