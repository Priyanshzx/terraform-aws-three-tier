# Terraform AWS Three-Tier Architecture

A three-tier AWS architecture defined entirely as code with Terraform. Built in phases, starting with the network layer. Region: `ap-south-1` (Mumbai).

**Status:** Phase 1 (VPC) complete. Phase 2 (ALB + ECS Fargate) in progress.

## Phase 1: VPC

![VPC resource map](docs/vpc-resource-map.png)

- VPC `10.0.0.0/16` across two Availability Zones
- Two public and two private subnets, each with its own route table setup
- Internet gateway for the public subnets
- Free gateway endpoints for S3 and DynamoDB, so private workloads reach them without NAT
- NAT gateway is optional and off by default, because it bills hourly
- Remote state in S3 with native state locking, bootstrapped separately

## Structure

```
bootstrap/     creates the S3 bucket that stores Terraform state
modules/vpc/   reusable VPC module
envs/dev/      dev environment that uses the module
```

## Usage

```bash
cd bootstrap && terraform init && terraform apply   # once
cd ../envs/dev
terraform init
terraform plan
terraform apply
terraform destroy   # when finished, to avoid charges
```

Requires Terraform 1.10 or newer and AWS credentials configured locally.

## Roadmap

- [x] Phase 1: VPC, subnets, routing, gateway endpoints
- [ ] Phase 2: security groups, ALB, ECS Fargate service in private subnets
- [ ] Phase 3: GitHub Actions pipeline (`plan` on pull requests, `apply` on merge) using OIDC
- [ ] Phase 4: security scan with checkov, architecture diagram, cost notes
