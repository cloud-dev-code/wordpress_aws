################################################################################
## Security Groups for Elastic File System (shared across Availability Zones) ##
################################################################################
resource "aws_security_group" "wordpress-fs-client-sg" {
  name = "${var.prefix_name}-fs-client-sg"

  description = "Allow WordPress servers to connect to EFS on 2049"
  vpc_id = var.vpc_id

  egress {
    from_port = var.efs_port
    to_port   = var.efs_port
    protocol  = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.prefix_name}-fs-client-sg"
    Terraform   = "true"
    Environment = var.target_environment
  }
}

resource "aws_security_group" "wordpress-fs-sg" {
  name = "${var.prefix_name}-fs-sg"

  description = "Allow TCP connection on 2049 for Elastic File System"
  vpc_id      = var.vpc_id

  # Only EFS in
  ingress {
    from_port       = var.efs_port
    to_port         = var.efs_port
    protocol        = "tcp"
    security_groups = [aws_security_group.wordpress-fs-client-sg.id]
  }

  egress {
    from_port = var.efs_port
    to_port   = var.efs_port
    protocol  = "tcp"
    security_groups = [aws_security_group.wordpress-fs-client-sg.id]
  }

  tags = {
    Name        = "${var.prefix_name}-fs-sg"
    Terraform   = "true"
    Environment = var.target_environment
  }
}

#########################
## Elastic File System ##
#########################
resource "aws_efs_file_system" "wordpress-fs" {
  creation_token = "wordpress-fs"

  tags = {
    Name        = "${var.prefix_name}-fs"
    Terraform   = "true"
    Environment = var.target_environment
  }
}

resource "aws_efs_mount_target" "wordpress-mount-targets" {
  count           = length(var.private_subnets)
  file_system_id  = aws_efs_file_system.wordpress-fs.id
  subnet_id       = var.private_subnets[count.index]
  security_groups = [aws_security_group.wordpress-fs-sg.id]
}
