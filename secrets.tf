# ---------------------------------------------------------------------------
# DB credentials: a generated password stored in Secrets Manager, encrypted
# with our CMK. RDS (next step) will read this instead of a hardcoded password.
# ---------------------------------------------------------------------------

# Generate a strong random password. Lives in state (plaintext) — that's why
# the state backend must be locked down, and why rotation matters in prod.
resource "random_password" "db" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+"
}

resource "aws_secretsmanager_secret" "db" {
  name        = "${var.project_name}-db-credentials"
  description = "RDS master credentials for ${var.project_name}"
  kms_key_id  = aws_kms_key.main.arn # encrypt the secret with our CMK

  # Learning project: destroy immediately instead of the 7-30 day recovery
  # window, so repeated destroy/apply cycles don't hit "already scheduled
  # for deletion". In production you would NOT set this to 0.
  recovery_window_in_days = 0

  tags = { Name = "${var.project_name}-db-credentials" }
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = "photoadmin"
    password = random_password.db.result
  })
}
