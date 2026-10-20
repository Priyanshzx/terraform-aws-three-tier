output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "alb_url" {
  value = "http://${module.alb.dns_name}"
}

output "ecr_repository_url" {
  value = module.app.ecr_repository_url
}

output "dynamodb_table" {
  value = aws_dynamodb_table.tasks.name
}
