terraform {
  backend "s3" {
    bucket       = "priyansh-tfstate-554739428679"
    key          = "three-tier/dev/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true # S3 native state locking (Terraform 1.10+)
  }
}
