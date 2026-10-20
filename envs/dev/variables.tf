variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "enable_nat_gateway" {
  description = "Set true only while you need private subnets to reach the internet. Billed hourly."
  type        = bool
  default     = false
}
