terraform {
  required_version = ">= 1.5"

  # Remote state: stored in S3, encrypted, with native state locking.
  # NOTE: backend blocks CANNOT use variables — values must be literals.
  backend "s3" {
    bucket       = "photoshare-tfstate-977237814508"
    key          = "photoshare/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # Applied to every resource this provider creates.
  # Resource-level `tags` merge on top; the merged result shows up in `tags_all`.
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
