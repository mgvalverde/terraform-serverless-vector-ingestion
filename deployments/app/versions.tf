terraform {
#   required_version = ">= 0.14.9"
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  backend "s3" {
    ## State Store
    ## Lock Store
    # DynamoDB table name: LOCKS. NOTE: Id = LockID
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.tags
  }

}

data "aws_caller_identity" "current" {}

locals {
  tags = merge({
    "owner" : var.owner,
    "project" : var.project,
    "env" : var.environment,
    "managed-by" : "terraform"
  }, var.tags)

  account_id = data.aws_caller_identity.current.account_id
  region     = var.aws_region
}

