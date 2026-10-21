#IAM Users
data "aws_iam_user" "admin" {
  user_name = "depi-sec-admin"
}
resource "aws_iam_user" "dev_1" {
  name = "depi-dev-1"
}

# Password Policy
resource "aws_iam_account_password_policy" "password_policy" {
  minimum_password_length        = 14
  require_uppercase_characters   = true
  require_lowercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  max_password_age               = 90
  password_reuse_prevention      = 5
  allow_users_to_change_password = true
  hard_expiry                    = false
}

# Permission Policies
## Deny EC2 and RDS
resource "aws_iam_policy" "deny_expensive" {
  name        = "depi-sec-deny-expensive"
  description = "Denies launching EC2 instances and creating RDS instances to enforce cost governance"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyExpensiveActions"
        Effect = "Deny"
        Action = [
          "ec2:RunInstances",
          "rds:CreateDBInstance"
        ]
        Resource = "*"
      }
    ]
  })
}

# Trust Policies
## Budgets Assume Role
resource "aws_iam_role" "budgets_role" {
  name = "depi-sec-budgets-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowBudgetsAssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "budgets.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# IAM Groups
## My Group
resource "aws_iam_group" "sec_group" {
  name = "depi-sec-group"
}
resource "aws_iam_group_membership" "sec_group_membership" {
  name  = "depi-sec-group-membership"
  group = aws_iam_group.sec_group.name

  users = [
    data.aws_iam_user.admin.user_name
  ]
}
## Devs Group
resource "aws_iam_group" "devs_group" {
  name = "depi-sec-developers"
}
resource "aws_iam_group_policy_attachment" "developers_readonly" {
  group      = aws_iam_group.devs_group.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}
resource "aws_iam_user_group_membership" "dev_1_membership" {
  user = aws_iam_user.dev_1.name

  groups = [
    aws_iam_group.devs_group.name
  ]
}
resource "aws_iam_user_login_profile" "dev_1_login" {
  user = aws_iam_user.dev_1.name
}
output "depi_dev_1_initial_password" {
  value     = aws_iam_user_login_profile.dev_1_login.password
  sensitive = true # hide password from output
}

# S3 Bucket Policy
resource "aws_iam_policy" "s3_app_read" {
  name        = "depi-sec-s3-app-read"
  description = "Allows read-only access to objects in the depi-sec-app bucket only"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowS3AppBucketReadOnly"
        Effect   = "Allow"
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.app_bucket.arn}/*"
      }
    ]
  })
}

# EC2 Role
resource "aws_iam_role" "ec2_role" {
  name = "depi-sec-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEC2AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_ssm_core" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ec2_s3_app_read" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_app_read.arn
}
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "depi-sec-ec2-profile"
  role = aws_iam_role.ec2_role.name
}