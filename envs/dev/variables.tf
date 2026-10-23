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
  description = "Full image URI. Leave empty to run <ecr_repository_url>:latest, which the App workflow builds and pushes."
  type        = string
  default     = ""
}

variable "container_port" {
  type    = number
  default = 8000
}

variable "health_check_path" {
  type    = string
  default = "/health"
}
