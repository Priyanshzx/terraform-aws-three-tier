variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "enable_nat_gateway" {
  description = "Required for private tasks to pull images and reach AWS APIs. Billed hourly, so destroy when finished."
  type        = bool
  default     = true
}

variable "container_image" {
  description = "Image to run. Starts as public nginx for a smoke test; later set to <ecr_repository_url>:<tag>."
  type        = string
  default     = "public.ecr.aws/docker/library/nginx:stable"
}

variable "container_port" {
  type    = number
  default = 80
}

variable "health_check_path" {
  type    = string
  default = "/"
}
