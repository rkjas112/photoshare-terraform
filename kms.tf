# ---------------------------------------------------------------------------
# Customer-managed KMS key (CMK) for encrypting S3 objects and the DB secret.
# ---------------------------------------------------------------------------

resource "aws_kms_key" "main" {
  description             = "${var.project_name} CMK for S3 and Secrets Manager"
  deletion_window_in_days = 7    # grace period before the key is really deleted
  enable_key_rotation     = true # AWS rotates the key material yearly, transparently

  tags = { Name = "${var.project_name}-kms" }
}

# A friendly alias so you reference alias/photoshare instead of a random key id.
resource "aws_kms_alias" "main" {
  name          = "alias/${var.project_name}"
  target_key_id = aws_kms_key.main.key_id
}
