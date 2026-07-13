# ---------------------------------------------------------------------------
# Observability: CloudWatch alarms -> SNS topic (the alert channel).
# Alarm on SYMPTOMS (users affected) as well as causes.
# ---------------------------------------------------------------------------

# The alert channel. In prod you'd subscribe PagerDuty/email/Slack to this.
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"

  tags = { Name = "${var.project_name}-alerts" }
}

# SYMPTOM alarm: a web server is failing the ALB health check -> lost capacity.
resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  alarm_name        = "${var.project_name}-alb-unhealthy-hosts"
  alarm_description = "One or more web servers are failing ALB health checks"

  namespace   = "AWS/ApplicationELB"
  metric_name = "UnHealthyHostCount"
  statistic   = "Maximum"
  period      = 60 # seconds per data point
  dimensions = {
    LoadBalancer = aws_lb.web.arn_suffix
    TargetGroup  = aws_lb_target_group.web.arn_suffix
  }

  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  evaluation_periods  = 2              # must breach for 2 periods (2 min) to fire
  treat_missing_data  = "notBreaching" # no data != a problem

  alarm_actions = [aws_sns_topic.alerts.arn] # notify when it fires
  ok_actions    = [aws_sns_topic.alerts.arn] # notify when it recovers
}
resource "aws_cloudwatch_metric_alarm" "rds_high_cpu" {
  alarm_name        = "${var.project_name}-rds-high-cpu"
  alarm_description = "RDS CPU above 80% for 5 minutes"

  namespace   = "AWS/RDS"
  metric_name = "CPUUtilization"
  statistic   = "Average"
  period      = 60
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.identifier
  }

  comparison_operator = "GreaterThanThreshold"
  threshold           = 80
  evaluation_periods  = 5
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alerts.arn]
}