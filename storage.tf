# ---------------------------------------------------------------------------
# S3 bucket for image storage. Modern provider = bucket + separate config
# resources (public-access-block, versioning, encryption).
# ---------------------------------------------------------------------------

# Read the current account ID so the bucket name is globally unique.
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "images" {
  bucket = "${var.project_name}-images-${data.aws_caller_identity.current.account_id}"

  tags = { Name = "${var.project_name}-images" }
}

# Block ALL public access. Four independent switches — all on.
resource "aws_s3_bucket_public_access_block" "images" {
  bucket = aws_s3_bucket.images.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_versioning" "images" {
  bucket = aws_s3_bucket.images.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "images" {
  bucket = aws_s3_bucket.images.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}