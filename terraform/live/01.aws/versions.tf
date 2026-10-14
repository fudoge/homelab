terraform {
  required_version = "~> 1.12.5"

  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "2.8.1"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "6.57.1"
    }
  }
}
