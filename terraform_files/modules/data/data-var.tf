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

variable "rds_port" {
  type         = number
  default      = 3306
  description  = "RDS database port"
}

variable "prefix_name" {
  type         = string
  default      = "wordpress-data"
  description  = "Prefix name for data layer"
}

variable "rds_instance_class" {
  type         = string
  default      = "db.r5.large"
  description  = "Instance class for RDS instances"
}

variable "cluster_dbname" {
  type         = string
  default      = "wordpress"
  description  = "RDS cluster database name"
}

variable "cluster_username" {
  type         = string
  default      = "username"
  description  = "RDS cluster username"
}

variable "cluster_password" {
  type         = string
  default      = "password"
  description  = "RDS cluster password"
}

variable "rds_instance_count" {
  type         = number
  default      = 2
  description  = "Number of RDS instances to launch (ideally one for Availability Zone)"
}

variable "memcached_port" {
  type         = number
  default      = 11211
  description  = "Memcached database port"
}

variable "memcached_node_type" {
  type         = string
  default      = "cache.t2.small"
  description  = "Node type for ElastiCache cluster"
}

variable "memcached_nodes_count" {
  type         = number
  default      = 1
  description  = "Number of cache nodes"
}

variable "efs_port" {
  type         = number
  default      = 2049
  description  = "Elastic File System port"
}

variable "target_environment" {
  type        = string
  default     = "dev"
  description = "Target environment for deployment"
}
