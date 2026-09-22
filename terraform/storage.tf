resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "app_bucket" {
  bucket = "depi-sec-app-${random_id.suffix.hex}"
}