terraform {
  required_providers {
    #setting the AWS provider and version
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region     = "us-east-1"

  assume_role {
    #The role ARN within Account <you account number> to AssumeRole into.
    role_arn    = "arn:aws:iam::<you account number>:role/test_user_role"
  }
}