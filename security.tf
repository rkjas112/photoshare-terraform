# ---------------------------------------------------------------------------
# Security groups — three-tier chain.
# Internet -> ALB SG (80/443) -> web SG (80) -> db SG (3306)
# SGs are STATEFUL: allowing inbound auto-allows the matching return traffic.
# ---------------------------------------------------------------------------

# Tier 1: the load balancer. The only tier open to the internet.
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "ALB: allow HTTP/HTTPS from the internet"
  vpc_id      = aws_vpc.photoshare.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-alb-sg" }
}



# Tier 2: the app/web servers. Only reachable from the ALB.
resource "aws_security_group" "web" {
  name        = "${var.project_name}-web-sg"
  description = "Web: allow HTTP only from the ALB"
  vpc_id      = aws_vpc.photoshare.id

  ingress {
    description     = "HTTP from the ALB only"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-web-sg" }
}

# Tier 3: the db servers. Only reachable from the app.
resource "aws_security_group" "db" {
  name        = "${var.project_name}-db-sg"
  description = "DB: allow MySQL only from the web tier"
  vpc_id      = aws_vpc.photoshare.id

  ingress {
    description     = "MySQL from the web tier only"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  tags = { Name = "${var.project_name}-db-sg" }
}
