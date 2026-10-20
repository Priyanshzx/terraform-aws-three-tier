variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "target_port" {
  description = "Port the containers listen on"
  type        = number
}

variable "health_check_path" {
  type    = string
  default = "/"
}
