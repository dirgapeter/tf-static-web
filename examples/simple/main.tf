
terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  region = var.region
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

locals {
  environment = lower("${var.environment}-${random_string.suffix.result}")

  tags = {
    example = "true"
  }
}

module "static_website" {
  source = "../../"

  project     = var.project
  environment = local.environment

  tags = local.tags
}
