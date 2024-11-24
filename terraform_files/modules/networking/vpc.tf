####################################
## VPC, Internet Gateway, Subnets ##
####################################
# VPC module provision a new Elastic IP each time the VPC is destroyed and re-allocated. 
# Note: Create an Elastic IP only once to have always the same.
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name
  cidr = var.vpc_cidr
  azs  = var.availability_zones

  # Subnets
  private_subnets = var.private_subnets
  intra_subnets   = var.intra_subnets
  public_subnets  = var.public_subnets

  enable_vpn_gateway = true

  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true

  # Enable DNS resolution support
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Terraform   = "true"
    Environment = var.target_environment
  }
}
