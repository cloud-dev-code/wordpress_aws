variable "vpc_id" {
  description = "VPC ID"
}

variable "public_subnets" {
  description = "Public subnets IDs"
}

variable "intra_subnets" {
  description = "Intra subnets IDs"
}

variable "private_subnets" {
  description = "Private subnets IDs"
}

variable "efs_dns_name" {
  description = "DNS name for EFS"
}

variable "db_name" {
  description = "Name for RDS database"
}

variable "db_hostname" {
  description = "DNS name for RDS"
}

variable "db_username" {
  description = "Database username"
}

variable "db_password" {
  description = "Database password"
}

variable "wordpress_version" {
  description = "The version of WordPress to install"
  type        = string
}

variable "clients_sg" {
  description = "Security group IDs for data layer clients"
}

variable "prefix_name" {
  type         = string
  default      = "wordpress-app"
  description  = "Prefix name for application layer"
}

variable "http_port" {
  type         = number
  default      = 80
  description  = "HTTP port"
}

variable "https_port" {
  type         = number
  default      = 443
  description  = "HTTPS port"
}

variable "ssh_port" {
  type         = number
  default      = 22
  description  = "SSH port"
}

variable "key_name" {
  type         = string
  default      = "wordpress-ec2-key"
  description  = "Name for private key to access VMs through SSH"
}

variable "vm_instance_type" {
  type         = string
  default      = "t2.micro"
  description  = "Type of VMs within the Auto Scaling group"
}

variable "asg_min_size" {
  type         = number
  default      = 2
  description  = "Minimum number of VMs within the Auto Scaling group"
}

variable "asg_max_size" {
  type         = number
  default      = 10
  description  = "Maximum number of VMs within the Auto Scaling group"
}

variable "ami" {
  type         = string
  default      = "ami-0453ec754f44f9a4a"
  description  = "AMI to build up the VMs, default is Amazon Linux 2023 AMI"
}

variable "target_environment" {
  type        = string
  default     = "dev"
  description = "Target environment for deployment"
}
