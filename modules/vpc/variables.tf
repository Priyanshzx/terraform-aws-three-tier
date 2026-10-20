variable "name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "region" {
  description = "AWS region (used for VPC endpoint service names)"
  type        = string
}

variable "vpc_cidr" {
  type = string
}

variable "azs" {
  description = "Availability zones, one subnet pair per AZ"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "One CIDR per AZ, same order as azs"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "One CIDR per AZ, same order as azs"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "NAT gateways bill hourly. Keep false unless private subnets need internet access."
  type        = bool
  default     = false
}

variable "single_nat_gateway" {
  description = "true = one shared NAT (cheaper), false = one per AZ (highly available)"
  type        = bool
  default     = true
}
