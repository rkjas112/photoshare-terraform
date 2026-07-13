# ---------------------------------------------------------------------------
# Outputs — the useful values, surfaced after apply.
# ---------------------------------------------------------------------------

output "app_url" {
  description = "Public URL of the load-balanced web app"
  value       = "http://${aws_lb.web.dns_name}"
}

output "vpc_id" {
  description = "The VPC id"
  value       = aws_vpc.photoshare.id
}

output "public_subnet_ids" {
  description = "Public subnet ids"
  value       = values(aws_subnet.public)[*].id
}

output "private_subnet_ids" {
  description = "Private subnet ids"
  value       = values(aws_subnet.private)[*].id
}

output "db_endpoint" {
  description = "RDS endpoint (private, resolvable inside the VPC only)"
  value       = aws_db_instance.main.endpoint
}

output "images_bucket" {
  description = "S3 bucket for image storage"
  value       = aws_s3_bucket.images.bucket
}

output "alerts_topic_arn" {
  description = "SNS topic that alarms publish to"
  value       = aws_sns_topic.alerts.arn
}
