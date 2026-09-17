provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
    Project     = "depi-mini-project-1"
    Owner       = "security-team"
    Environment = "lab"
    ManagedBy   = "terraform"
    }     
  }
}