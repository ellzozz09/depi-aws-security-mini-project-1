variable "alert_emails" {
  description = "List of email addresses to receive AWS Budgets notifications."
  type        = list(string)

  validation {
    condition = alltrue([
      for email in var.alert_emails : can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email))
    ])
    error_message = "All items in the alert_emails list must be valid email addresses (e.g., admin@example.com)."
  }
}