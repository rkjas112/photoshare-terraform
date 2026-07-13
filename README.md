# PhotoShare — Secure 3-Tier AWS Architecture (Terraform)

A production-style, secure **3-tier web application** on AWS, built entirely as
Infrastructure as Code with Terraform. Internet-facing load balancer, an
auto-scaling web tier across two availability zones, and a private, encrypted
database — with remote state, drift correction, and monitoring.

Live during a session, the load balancer serves traffic across two web servers
in separate AZs; the database has no public endpoint and accepts connections
only from the web tier.

## Architecture

```
                    Internet
                       │  HTTP :80
                 ┌─────▼─────┐
                 │    ALB     │  public subnets · 2 AZs
                 └─────┬─────┘  alb SG (80/443 from internet)
              ┌────────┴────────┐
        ┌─────▼─────┐     ┌─────▼─────┐
        │ web · AZ-a │     │ web · AZ-b │  public subnets · web SG (ALB only)
        └─────┬─────┘     └─────┬─────┘  auto-scaling group (2–4)
              └────────┬────────┘
                  :3306 │
              ┌─────────▼─────────┐
              │   RDS MySQL        │  private subnets · no public IP
              │  (encrypted, KMS)  │  db SG (web tier only)
              └───────────────────┘

  Supporting: S3 (KMS-encrypted images) · KMS CMK · Secrets Manager (DB creds)
              CloudWatch alarms → SNS · remote state in S3 (locked, encrypted)
```

## What this demonstrates

- **Networking** — VPC, public/private subnets across 2 AZs, IGW, explicit route tables, all parameterised with `for_each` and an AZ data source
- **Layered security** — three chained security groups (ALB → web → DB) using SG-to-SG references, not IP ranges
- **Data protection** — RDS in private subnets, encrypted at rest with a customer-managed KMS key; credentials generated and stored in Secrets Manager, never hardcoded
- **High availability** — ALB + auto-scaling group across two availability zones, ELB health checks, self-healing
- **Observability** — CloudWatch alarms (symptom + cause) publishing to an SNS alert channel
- **State management** — remote state in S3 with native locking and encryption
- **Drift correction** — out-of-band changes are detected by `plan` and reverted by `apply`

## Tech stack

**Terraform** (`for_each`, `moved` blocks, data sources, remote backend) ·
**AWS** — VPC, EC2, ALB, Auto Scaling, RDS (MySQL), S3, KMS, Secrets Manager,
IAM, CloudWatch, SNS

## Repository layout

| File | Contents |
|------|----------|
| `providers.tf` | provider config, `default_tags`, S3 remote backend |
| `variables.tf` | input variables (region, CIDRs, AZ count, …) |
| `main.tf` | VPC, subnets, IGW, route tables |
| `security.tf` | the three-tier security-group chain |
| `storage.tf` | hardened S3 bucket (versioning, encryption, public-access block) |
| `kms.tf` | customer-managed KMS key + alias |
| `secrets.tf` | generated DB password in Secrets Manager |
| `database.tf` | private, encrypted RDS MySQL |
| `compute.tf` | launch template, ALB, target group, listener, ASG |
| `observability.tf` | CloudWatch alarms + SNS topic |
| `outputs.tf` | app URL, DB endpoint, bucket, etc. |

## Key design decisions

- **Web tier in public subnets, protected by its security group.** To avoid the
  cost of a NAT gateway, the web servers sit in public subnets but their security
  group only allows the ALB — so they are not reachable from the internet.
  Protection is at the security-group layer, not the subnet. *In production:
  private subnets behind a NAT gateway.*
- **Database is private and defense-in-depth.** RDS is in private subnets (no
  route to the internet) **and** locked to the web tier's security group — so a
  misconfigured SG alone can't expose it.
- **No hardcoded secrets.** The DB password is generated with `random_password`,
  stored in Secrets Manager (KMS-encrypted), and read at runtime.
- **HTTP only.** No domain, so no TLS certificate. To add HTTPS: an ACM
  certificate, a 443 listener, and an 80→443 redirect. TLS would terminate at
  the ALB; the target group stays HTTP.

## Running it

Requires Terraform ≥ 1.5 and AWS credentials. The remote state backend expects
an S3 bucket (see `providers.tf`); create your own and update the `backend`
block, or switch to local state.

```bash
export AWS_PROFILE=<your-profile>
terraform init
terraform plan
terraform apply
terraform output app_url    # the live load-balancer URL

terraform destroy           # tear everything down
```

## Cost

Runs largely on the AWS free tier. The only always-on charges are the ALB
(~\$0.02/hr) and the RDS instance; there is **no NAT gateway** by design (the
biggest cost trap). Apply-and-destroy within a session costs cents.

## Possible enhancements

- Refactor into reusable **modules** (network / security / data / compute)
- **HTTPS** via ACM + a 443 listener
- **CI**: `terraform plan` + `tfsec`/`Checkov` on every pull request
- Target-tracking **auto-scaling** policy
- Move the web tier to **private subnets** behind a NAT gateway

---

Built by **Rohit Kumar Jaiswal** — cloud / DevOps engineer (AWS · Terraform · IAM · Python).
