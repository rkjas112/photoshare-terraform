# PhotoShare — Secure 3-Tier AWS Architecture (Terraform)

A production-style, secure 3-tier web application infrastructure on AWS, built entirely as Terraform (Infrastructure as Code).

> ⚠️ Work in progress — building this incrementally as a portfolio project.

## Architecture

<!-- TODO: add architecture diagram (draw.io / excalidraw export) -->

**Public tier:** Application Load Balancer + EC2 web server (public subnets)
**Private tier:** RDS MySQL (private subnets, no internet access)
**Supporting:** S3 (image storage), Lambda (metadata processing), Secrets Manager + KMS (credentials), CloudWatch (monitoring)

## Tech Stack

- **Terraform** — infrastructure as code
- **AWS** — VPC, subnets, IGW, route tables, security groups, EC2, RDS, S3, Lambda, IAM, KMS, Secrets Manager, ALB, CloudWatch

## Key Design Decisions

<!-- Fill these in as you build — great interview talking points -->
- The database lives in **private subnets** with no route to the internet — isolation by routing, not just a label.
- **Security group chaining** — the DB only accepts traffic from the web server's SG, not an IP range.
- Credentials are stored in **Secrets Manager** (KMS-encrypted) and fetched at runtime via an **IAM role** — never hardcoded.

## How to Run

```bash
export AWS_PROFILE=terraform-learning   # your AWS profile
terraform init
terraform plan
terraform apply
# ... when done:
terraform destroy
```

## Cost

Runs almost entirely on AWS free tier. Applied-and-destroyed in a session costs ~₹20 / <$0.25.
No NAT Gateway in the design (the biggest cost trap is avoided).

---

Built by Rohit Kumar Jaiswal · [GitHub](https://github.com/) · rebuilt from a hands-on lab into full IaC.
