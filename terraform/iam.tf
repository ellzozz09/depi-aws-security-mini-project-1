# Admin IAM User
data "aws_iam_user" "admin" {
  user_name = "depi-sec-admin"
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
resource "aws_iam_group" "sec_group" {
  name = "depi-sec-group"
}

## Groups Membership
resource "aws_iam_group_membership" "sec_group_membership" {
  name  = "depi-sec-group-membership"
  group = aws_iam_group.sec_group.name

  users = [
    data.aws_iam_user.admin.user_name
  ]
}