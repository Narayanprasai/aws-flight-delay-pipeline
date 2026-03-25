terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket  = "flight-pipeline-tfstate-013849273657"
    key     = "terraform.tfstate"
    region  = "ap-northeast-1"
  }
}

provider "aws" {
  region = var.aws_region
}