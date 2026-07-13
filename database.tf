# ---------------------------------------------------------------------------
# RDS MySQL — the private data tier. Ties together everything above:
#   - lives in the PRIVATE subnets (via a db subnet group)
#   - reachable only through the DB security group (web tier only)
#   - encrypted at rest with our KMS CMK
#   - credentials read from the Secrets Manager secret (never hardcoded)
# ---------------------------------------------------------------------------

# RDS needs a "subnet group" telling it which subnets it may live in.
# We give it the two PRIVATE subnets, so the DB has no public exposure.
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = values(aws_subnet.private)[*].id

  tags = { Name = "${var.project_name}-db-subnet-group" }
}

# Decode the JSON secret we stored, so we can feed username/password to RDS
# without ever hardcoding them.
locals {
  db_creds = jsondecode(aws_secretsmanager_secret_version.db.secret_string)
}

resource "aws_db_instance" "main" {
  identifier     = "${var.project_name}-db"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro" # free-tier-eligible

  allocated_storage = 20
  storage_type      = "gp2"
  storage_encrypted = true                 # encryption at rest...
  kms_key_id        = aws_kms_key.main.arn # ...with OUR customer-managed key

  db_name  = "photoshare"
  username = local.db_creds.username # from the secret, not hardcoded
  password = local.db_creds.password # from the secret, not hardcoded

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id] # web tier only
  publicly_accessible    = false                      # no public endpoint
  multi_az               = false                      # single-AZ to save cost (prod: true)

  # Learning project: allow a clean destroy. In production you'd flip both.
  skip_final_snapshot = true
  deletion_protection = false

  tags = { Name = "${var.project_name}-db" }
}
