locals {
  name = "three-tier-dev"
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = "three-tier"
      Env       = "dev"
      ManagedBy = "terraform"
    }
  }
}

# ---------- Network tier ----------
module "vpc" {
  source = "../../modules/vpc"

  name   = local.name
  region = var.region

  vpc_cidr             = "10.0.0.0/16"
  azs                  = ["ap-south-1a", "ap-south-1b"]
  public_subnet_cidrs  = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]

  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = true
}

# ---------- Data tier ----------
resource "aws_dynamodb_table" "tasks" {
  name         = "${local.name}-tasks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "task_id"

  attribute {
    name = "task_id"
    type = "S"
  }
}

# ---------- Public entry point ----------
module "alb" {
  source = "../../modules/alb"

  name              = local.name
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  target_port       = var.container_port
  health_check_path = var.health_check_path
}

# ---------- Application tier ----------
module "app" {
  source = "../../modules/ecs-service"

  name   = local.name
  region = var.region

  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  alb_security_group_id = module.alb.security_group_id
  target_group_arn      = module.alb.target_group_arn

  container_image = var.container_image
  container_port  = var.container_port

  enable_dynamodb_access = true
  dynamodb_table_arn     = aws_dynamodb_table.tasks.arn
  environment = {
    TABLE_NAME = aws_dynamodb_table.tasks.name
    AWS_REGION = var.region
  }

  depends_on = [module.alb]
}
