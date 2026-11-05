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

## Related project

The [`fooddash`](https://github.com/sankalpmax/fooddash) repository contains the application prototype and its experimental sandbox workflow.
