# ---------------------------------------------------------------------------
# Compute tier: ALB (public) -> ASG of web servers.
# Web servers sit in PUBLIC subnets (no NAT to save cost), but the web SG
# only allows the ALB — so they are protected at the SG layer, not by subnet.
# In production: private subnets + NAT gateway.
# ---------------------------------------------------------------------------

# Latest Amazon Linux 2023 AMI, looked up at plan time (never hardcode AMI ids).
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# The EC2 blueprint: what every web server launched by the ASG looks like.
resource "aws_launch_template" "web" {
  name_prefix   = "${var.project_name}-web-"
  image_id      = data.aws_ami.al2023.id
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.web.id]

  # Runs on first boot: install and start a simple web page.
  user_data = base64encode(<<-EOF
    #!/bin/bash
    dnf install -y httpd
    systemctl enable --now httpd
    echo "<h1>PhotoShare — served from $(hostname)</h1>" > /var/www/html/index.html
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.project_name}-web" }
  }
}

# The load balancer itself — internet-facing, in the public subnets.
resource "aws_lb" "web" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = values(aws_subnet.public)[*].id

  tags = { Name = "${var.project_name}-alb" }
}



resource "aws_lb_target_group" "web" {
  name     = "${var.project_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.photoshare.id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}


resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

resource "aws_autoscaling_group" "web" {
  name                = "${var.project_name}-asg"
  vpc_zone_identifier = values(aws_subnet.public)[*].id
  target_group_arns   = [aws_lb_target_group.web.arn]
  health_check_type   = "ELB"

  min_size         = 2
  max_size         = 4
  desired_capacity = 2

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-web"
    propagate_at_launch = true
  }
}
