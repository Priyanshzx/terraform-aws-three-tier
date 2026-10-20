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

module "vpc" {
  source = "../../modules/vpc"

  name   = "three-tier-dev"
  region = var.region

  vpc_cidr             = "10.0.0.0/16"
  azs                  = ["ap-south-1a", "ap-south-1b"]
  public_subnet_cidrs  = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]

  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = true
}
