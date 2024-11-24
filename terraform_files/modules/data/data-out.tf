output "efs_dns_name" {
  description = "DNS name for EFS"
  value       = aws_efs_mount_target.wordpress-mount-targets[0].dns_name
}

output "db_name" {
  description = "Name of RDS database"
  value       = aws_rds_cluster.wordpress-rds-cluster.database_name
}

output "db_hostname" {
  description = "DNS name for RDS"
  value       = aws_rds_cluster.wordpress-rds-cluster.endpoint
}

output "db_username" {
  description = "Database username"
  value       = aws_rds_cluster.wordpress-rds-cluster.master_username
}

output "db_password" {
  description = "Database password"
  value       = aws_rds_cluster.wordpress-rds-cluster.master_password
}

output "clients_sg" {
  description = "Security group IDs for data layer clients"
  value = [
    aws_security_group.wordpress-db-client-sg.id, 
    aws_security_group.wordpress-cache-client-sg.id,
    aws_security_group.wordpress-fs-client-sg.id
  ]
}
