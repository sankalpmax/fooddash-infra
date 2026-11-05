# FoodDash Infrastructure

Terraform examples for the FoodDash portfolio application. This repository is for learning and review; it is not a production deployment guide or a commercial service. Do not apply these configurations to a live account without first reviewing the code, state ownership, permissions, and expected changes.

## Project status

- The repository contains two independent Terraform roots for different AWS regions.
- `prod-terraform/` is the Mumbai root (`ap-south-1`). Its directory name is historical and does not mean the configuration is production-ready.
- `terraform/vpc/` is the Hyderabad root (`ap-south-2`).
- The roots do not use reusable Terraform modules.
- The Mumbai root configures an S3 backend with S3 native lockfiles. The Hyderabad root has no remote backend configuration and uses local state by default.
- The configurations demonstrate VPC networking, load balancing, EC2/Auto Scaling, IAM, and RDS. RDS is configured as single-AZ; the ALBs use HTTP; and each VPC design uses one NAT gateway. These examples should not be described as highly available or production-hardened.
- A prior infrastructure audit found unresolved resource ownership and state-to-AWS discrepancies. That audit did not authorize infrastructure changes.

## Terraform roots

The repository contains two independent Terraform roots. They share no state, no modules, and no backend configuration.

```text
  prod-terraform/                      terraform/vpc/
  Mumbai — ap-south-1                  Hyderabad — ap-south-2
  ┌───────────────────────┐            ┌───────────────────────┐
  │ S3 remote backend      │            │ Local state            │
  │ use_lockfile = true    │            │ (no remote backend)    │
  │                        │            │                        │
  │ VPC, 2 AZ              │            │ VPC, 2 AZ              │
  │ Public/private subnets │            │ Public/private subnets │
  │ IGW + NAT gateway      │            │ IGW + NAT gateway      │
  │ ALB + 4 target groups  │            │ ALB + 4 target groups  │
  │ ASG + launch template  │            │ ASG + launch template  │
  │ RDS PostgreSQL         │            │ RDS PostgreSQL         │
  │ IAM role + policy      │            │ IAM role + policy      │
  └───────────────────────┘            └───────────────────────┘
        │                                      │
        ▼                                      ▼
  S3 bucket (state)                    terraform.tfstate (local)
  S3 lockfile (locking)                No locking
```

Terraform source describes intended configuration. It does not establish that a resource currently exists in AWS or that a particular state file owns it. A prior audit found that not all source declarations appear in state, and not all state entries could be confirmed in AWS.

## Repository layout

```text
.
├── prod-terraform/       # Mumbai Terraform root
├── terraform/vpc/        # Hyderabad Terraform root
└── scripts/
    ├── startup.sh        # Operational AWS script; changes resources
    └── shutdown.sh       # Operational AWS script; changes resources
```

The startup and shutdown scripts issue AWS resource modification operations. Review their targets and effects before using them. They are not read-only audit tools.

## Resources represented in the Terraform code

Depending on the root, the code declares VPCs, public and private subnets, internet and NAT gateways, route tables, security groups, IAM roles and policies, target groups, an Application Load Balancer, a launch template, an Auto Scaling group, and an RDS PostgreSQL instance.

Terraform source describes intended configuration. It does not establish that a resource currently exists in AWS or that a particular state file owns it.

## Backend and sensitive data

The Mumbai backend settings are declared in `prod-terraform/provider.tf`; the bucket name and key are intentionally not repeated here. The backend uses S3 native lockfiles. The Hyderabad root does not configure a remote backend.

Do not commit Terraform state, plan files, `.tfvars` files containing secrets, or credentials. Supply sensitive inputs through a secure local mechanism. Keep the provider lock file committed for reproducible provider selection.

## Review before deployment

No Terraform command is required to read these source files. Before considering a deployment, establish the correct AWS account, review the plan, confirm state ownership and resource impact, and separately authorize that operation. The presence of a directory named `prod-terraform` is not evidence that deployment is safe.

## Implemented and still in progress

**Implemented:**

- Two independent Terraform roots covering Mumbai and Hyderabad regions
- VPC with public/private subnet isolation across 2 AZs per root
- ALB with path-based routing to 4 microservice target groups
- Auto Scaling Group with Launch Template
- RDS PostgreSQL in private subnet (single-AZ)
- IAM roles and policies for EC2 (Secrets Manager, ECR, SSM access)
- S3 remote backend with native lockfiles (Mumbai root)
- Startup/shutdown scripts for sandbox cost management
- Read-only infrastructure audit: source-to-state-to-AWS reconciliation

**Still in progress:**

- No Terraform modules — both roots use direct resource declarations
- Hyderabad root uses local state with no remote backend or locking
- RDS is single-AZ with no automated failover
- ALB uses HTTP only — no HTTPS listener or certificate
- No Terraform CI/CD pipeline (plan/apply workflow)
- Audit found 10 source-only declarations not in state and 6 state entries not confirmed in AWS
- IAM resource verification was limited by access-denied responses during the audit

## Related project

The [`fooddash`](https://github.com/sankalpmax/fooddash) repository contains the application prototype and its experimental sandbox workflow.
