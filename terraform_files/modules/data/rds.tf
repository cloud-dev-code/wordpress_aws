#############################
## Security Groups for RDS ##
#############################
resource "aws_security_group" "wordpress-db-client-sg" {
  name = "${var.prefix_name}-client-sg"

  description = "Allows WordPress servers to contact Aurora DB on 3306"
  vpc_id = var.vpc_id

  egress {
    from_port = var.rds_port
    to_port   = var.rds_port
    protocol  = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.prefix_name}-rds-client-sg"
    Terraform   = "true"
    Environment = var.target_environment
  }
}

resource "aws_security_group" "wordpress-db-sg" {
  name = "${var.prefix_name}-sg"

  description = "Allow TCP connection on 3306 for Aurora DB"
  vpc_id      = var.vpc_id

  # Only MySQL in
  ingress {
    from_port = var.rds_port
    to_port   = var.rds_port
    protocol  = "tcp"
    security_groups = [aws_security_group.wordpress-db-client-sg.id]
  }

  egress {
    from_port = var.rds_port
    to_port   = var.rds_port
    protocol  = "tcp"
    security_groups = [aws_security_group.wordpress-db-client-sg.id]

  }

  tags = {
    Name        = "${var.prefix_name}-rds-sg"
    Terraform   = "true"
    Environment = var.target_environment
  }
}

##################
## Subnet Group ##
##################
resource "aws_db_subnet_group" "wordpress-aurora" {
  name        = "${var.prefix_name}-subnets"
  subnet_ids  = var.intra_subnets
  description = "Subnet Group used for Aurora database"

  tags = {
    Terraform   = "true"
    Environment = var.target_environment
  }
}

##################
## RDS database ##
##################
resource "aws_rds_cluster" "wordpress-rds-cluster" {
  cluster_identifier     = "${var.prefix_name}-rds-cluster"
  engine                 = "aurora-mysql"
  engine_version         = "8.0.mysql_aurora.3.04.0"
  #availability_zones     = ["us-east-1a", "us-east-1b"] # Enable it only to destroy and rebuild the RDS cluster
  database_name          = var.cluster_dbname
  db_subnet_group_name   = aws_db_subnet_group.wordpress-aurora.name
  master_username        = var.cluster_username
  master_password        = var.cluster_password
  vpc_security_group_ids = [aws_security_group.wordpress-db-sg.id]
  skip_final_snapshot    = true
  #backup_retention_period = 7
  #preferred_backup_window = "02:00-06:00"
  
  tags = {
    Terraform   = "true"
    Environment = var.target_environment
  }
}

##########################
## RDS Cluster Instance ##
##########################
resource "aws_rds_cluster_instance" "wordpress-rds-instances" {
  count                = var.rds_instance_count
  identifier           = "${var.prefix_name}-rds-instance-${count.index}"
  db_subnet_group_name = aws_db_subnet_group.wordpress-aurora.name
  cluster_identifier   = aws_rds_cluster.wordpress-rds-cluster.id
  instance_class       = var.rds_instance_class
  engine               = aws_rds_cluster.wordpress-rds-cluster.engine
  engine_version       = aws_rds_cluster.wordpress-rds-cluster.engine_version
  
  tags = {
    Terraform   = "true"
    Environment = var.target_environment
  }
}
