provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Project     = "depi-aws-security-mini-project-1"
      Owner       = "depi-sec-admin"
      Environment = "lab"
      ManagedBy   = "terraform"
    }
  }
}