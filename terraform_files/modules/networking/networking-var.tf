variable "vpc_name" {
  type         = string
  default      = "wordpress-vpc"
  description  = "VPC name"
}

variable "vpc_cidr" {
  type        = string
  default     = "192.168.0.0/16"
  description = "CIDR for VPC"
}

variable "availability_zones" {
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
  description = "Availability Zones in which the infrastructure is deployed"
}

variable "private_subnets" {
  type        = list(string)
  default     = ["192.168.2.0/24", "192.168.3.0/24"]
  description = "Private subnets CIDR (one per Availability Zone), where the application servers are deployed"
}

variable "public_subnets" {
  type        = list(string)
  default     = ["192.168.0.0/24", "192.168.1.0/24"]
  description = "Public subnets CIDR (one per Availability Zone), where the load balancer is deployed"
}

variable "intra_subnets" {
  type        = list(string)
  default     = ["192.168.4.0/24", "192.168.5.0/24"]
  description = "Intra subnets CIDR (one per Availability Zone), where the databases is deployed"
}

variable "target_environment" {
  type        = string
  default     = "dev"
  description = "Target environment for deployment"
}
