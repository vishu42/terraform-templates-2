terraform {
  backend "s3" {
    bucket = "afee87ae65ab4365-terraform-remote-backend"
    key    = "terraform.tfstate"
    region = "eu-central-1"
  }
}
