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