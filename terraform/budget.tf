# Budget limit
resource "aws_budgets_budget" "monthly_cost_budget" {
  name         = "depi-sec-monthly-budget"
  budget_type  = "COST"
  limit_amount = "10"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  time_period_start = "2026-09-01_00:00"

  ## Actual Budget
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.alert_emails
  }

  ## Forecast Budget
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.alert_emails
  }
}

# Budget Action Policy
resource "aws_iam_role_policy" "budgets_action_permissions" {
  name = "depi-sec-budgets-action-permissions"
  role = aws_iam_role.budgets_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowBudgetsAttachDetachGroupPolicy"
        Effect = "Allow"
        Action = [
          "iam:AttachGroupPolicy",
          "iam:DetachGroupPolicy"
        ]
        Resource = "*"
      }
    ]
  })
}

# Budget Action
resource "aws_budgets_budget_action" "deny_expensive_action" {
  budget_name        = aws_budgets_budget.monthly_cost_budget.name
  action_type        = "APPLY_IAM_POLICY"
  approval_model     = "AUTOMATIC"
  notification_type  = "ACTUAL"
  execution_role_arn = aws_iam_role.budgets_role.arn # trust policy

  action_threshold {
    action_threshold_type  = "PERCENTAGE"
    action_threshold_value = 90
  }

  definition {
    iam_action_definition {
      policy_arn = aws_iam_policy.deny_expensive.arn
      groups     = [aws_iam_group.sec_group.name]
    }
  }

  dynamic "subscriber" {
    for_each = var.alert_emails
    content {
      subscription_type = "EMAIL"
      address           = subscriber.value
    }
  }
}