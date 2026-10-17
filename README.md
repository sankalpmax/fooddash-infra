# FoodDash Infrastructure

Production-grade AWS cloud infrastructure for a microservices-based food delivery application, managed with Terraform Infrastructure as Code.

## 🏗️ Architecture Overview

Multi-tier, highly available architecture deployed across 2 availability zones in AWS ap-south-1 (Mumbai) region.

### Key Components

- **VPC**: Custom Virtual Private Cloud with public and private subnet isolation
- **Load Balancing**: Application Load Balancer with path-based routing for microservices
- **Compute**: Auto Scaling Groups with Launch Templates for automatic scaling and self-healing
- **Database**: RDS PostgreSQL in private subnet with Multi-AZ capability
- **Security**: Security group chaining, IAM roles, AWS Secrets Manager integration
- **Infrastructure as Code**: Terraform with remote state management (S3 + DynamoDB locking)

## 📊 Architecture Diagram

```
Internet
   ↓
[Internet Gateway]
   ↓
┌─────────────────────────────────────────────────────┐
│ VPC (10.0.0.0/16)                                   │
│                                                     │
│  Public Subnets (AZ-1a, AZ-1b)                     │
│  ┌──────────────────────────────────────┐          │
│  │  Application Load Balancer           │          │
│  │  - Path-based routing                │          │
│  │  - Health checks                     │          │
│  └──────────────────────────────────────┘          │
│           ↓                                         │
│  Private Subnets (AZ-1a, AZ-1b)                    │
│  ┌──────────────────────────────────────┐          │
│  │  Auto Scaling Group                  │          │
│  │  ┌────────────────────────────────┐  │          │
│  │  │ EC2 Instances                  │  │          │
│  │  │ - Frontend (3000)              │  │          │
│  │  │ - User Service (3001)          │  │          │
│  │  │ - Restaurant Service (3002)    │  │          │
│  │  │ - Order Service (3003)         │  │          │
│  │  └────────────────────────────────┘  │          │
│  └──────────────────────────────────────┘          │
│           ↓                                         │
│  ┌──────────────────────────────────────┐          │
│  │  RDS PostgreSQL (Private Subnet)     │          │
│  │  - Multi-AZ ready                    │          │
│  │  - Automated backups                 │          │
│  └──────────────────────────────────────┘          │
│                                                     │
│  [NAT Gateway] → Internet (for updates)            │
└─────────────────────────────────────────────────────┘
```

## 🛠️ Technology Stack

- **Cloud Provider**: AWS (Amazon Web Services)
- **IaC Tool**: Terraform v1.x
- **Services Used**:
  - VPC, Subnets, Internet Gateway, NAT Gateway
  - Application Load Balancer (ALB)
  - Auto Scaling Groups (ASG)
  - EC2 (t3.micro instances)
  - RDS PostgreSQL
  - IAM Roles & Policies
  - AWS Secrets Manager
  - S3 (Terraform state)
  - DynamoDB (State locking)

## 📁 Project Structure

```
fooddash-infra/
├── prod-terraform/          # Production environment
│   ├── main.tf             # Main infrastructure resources
│   ├── variables.tf        # Input variables
│   ├── output.tf           # Output values
│   ├── provider.tf         # AWS provider configuration
│   └── backend.tf          # Remote state configuration
└── terraform/              # Legacy/test configurations
    ├── vpc/
    ├── alb/
    ├── ec2/
    └── rds/
```

## 🚀 Deployment

### Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform v1.x installed
- AWS account with necessary permissions

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/sankalpmax/fooddash-infra.git
   cd fooddash-infra/prod-terraform
   ```

2. **Initialize Terraform**
   ```bash
   terraform init
   ```

3. **Create terraform.tfvars**
   ```hcl
   region      = "ap-south-1"
   ami_id      = "ami-0fa52f1a01deb1658"  # Ubuntu 22.04
   db_password = "your-secure-password"
   ```

4. **Preview changes**
   ```bash
   terraform plan
   ```

5. **Apply infrastructure**
   ```bash
   terraform apply
   ```

6. **Access application**
   ```bash
   # Get ALB DNS from output
   terraform output alb_dns_name
   # Open in browser: http://<alb-dns-name>
   ```

### Destroy Infrastructure

```bash
terraform destroy
```

## 🔐 Security Features

- **Network Isolation**: Public/private subnet segregation
- **Security Groups**: Layered security with group chaining (ALB → EC2 → RDS)
- **IAM Roles**: No hardcoded credentials, role-based access
- **Secrets Management**: Database credentials in AWS Secrets Manager
- **Private Database**: RDS in private subnet, no internet access
- **Least Privilege**: Minimal required permissions per resource

## 💰 Cost Optimization

- **Right-sizing**: t3.micro instances for development
- **Auto Scaling**: Scale to zero when not in use
- **Single NAT Gateway**: Shared across private subnets
- **GP2 Storage**: Cost-effective EBS volumes

**Estimated Monthly Cost**: ~$67 USD (if running 24/7)
- NAT Gateway: ~$32
- RDS: ~$12
- EC2: ~$7.5
- ALB: ~$16

## 📈 High Availability Design

- **Multi-AZ Deployment**: Resources across 2 availability zones
- **Auto Scaling**: Automatic instance replacement on failure
- **Health Checks**: ALB removes unhealthy instances from rotation
- **RDS Multi-AZ**: (Optional) Automatic database failover

## 🔄 State Management

- **Backend**: S3 bucket with versioning enabled
- **Locking**: DynamoDB table prevents concurrent modifications
- **Encryption**: State encrypted at rest
- **Team Collaboration**: Shared state accessible to team members

## 📝 Key Design Decisions

### Why Multi-AZ?
Ensures high availability and fault tolerance. If one AZ fails, resources in the other AZ continue serving traffic.

### Why Private Subnets for Application?
Security best practice. Application servers don't need direct internet access, reducing attack surface. ALB acts as gateway.

### Why Path-Based Routing?
Allows single ALB to route traffic to multiple microservices based on URL path, reducing infrastructure complexity and cost.

### Why Auto Scaling?
Provides self-healing capability and ability to scale based on demand without manual intervention.

## 🐛 Troubleshooting

### Issue: Terraform state locked
```bash
# Force unlock (use with caution)
terraform force-unlock <lock-id>
```

### Issue: RDS connection timeout
- Verify security group allows traffic from EC2 SG
- Check RDS is in correct private subnet
- Confirm RDS endpoint in Secrets Manager

### Issue: ALB returns 502/503
- Check target group health status
- Verify EC2 instances are running
- Check application logs on EC2
- Increase health check grace period

## 🎯 Future Enhancements

- [ ] CI/CD pipeline with GitHub Actions
- [ ] Docker containerization for services
- [ ] CloudWatch alarms and monitoring
- [ ] WAF (Web Application Firewall) integration
- [ ] Second NAT Gateway for redundancy
- [ ] CloudFront CDN for frontend
- [ ] Terraform modules for reusability
- [ ] Multi-region deployment

## 📚 Documentation

- [AWS VPC Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-best-practices.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)

## 👨‍💻 Author

**Sankalp**
- GitHub: [@sankalpmax](https://github.com/sankalpmax)
- LinkedIn: [Your LinkedIn Profile]

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

---

**Note**: This is a learning/portfolio project demonstrating production-grade infrastructure design patterns. For actual production deployments, additional considerations like compliance requirements, disaster recovery planning, and security hardening would be necessary.
