##########################################
## Security Groups for WordPress Server ##
##########################################
resource "aws_security_group" "wordpress-servers-sg" {
  name = "${var.prefix_name}-servers-sg"

  description = "Allow HTTP, HTTPS and SSH connection from Load Balancer & Bastion"
  vpc_id      = var.vpc_id

  # Only Load Balancer in (HTTP & HTTPS)
  ingress {
    from_port        = var.http_port
    to_port          = var.http_port
    protocol         = "tcp"
    security_groups = [aws_security_group.wordpress-lb-sg.id]
  }
  ingress {
    from_port        = var.https_port
    to_port          = var.https_port
    protocol         = "tcp"
    security_groups = [aws_security_group.wordpress-lb-sg.id]
  }
  ingress {
    from_port        = var.ssh_port
    to_port          = var.ssh_port
    protocol         = "tcp"
    security_groups = [module.bastion.security_group_id]
  }

  egress {
    from_port = var.http_port
    to_port   = var.http_port
    protocol  = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = var.https_port
    to_port   = var.https_port
    protocol  = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.prefix_name}-servers-sg"
    Terraform   = "true"
    Environment = var.target_environment
  }
}

#####################
## Launch Template ##
#####################
data "template_file" "user_data" {
  template = file("${path.module}/install_wordpress.sh")
  vars = {
    EFS_MOUNT         = var.efs_dns_name
    DB_NAME           = var.db_name
    DB_HOSTNAME       = var.db_hostname
    DB_USERNAME       = var.db_username
    DB_PASSWORD       = var.db_password
    LB_HOSTNAME       = aws_lb.wordpress-loadbalancer.dns_name
    WORDPRESS_VERSION = var.wordpress_version
  }
}

resource "aws_launch_template" "launch-template" {
  # Launch Templates cannot be updated after creation with the AWS API.
  # To update a Launch Template, Terraform will destroy the existing resource and create a new one.
  name_prefix     = "${var.prefix_name}-worker"
  image_id        = var.ami
  instance_type   = var.vm_instance_type

  key_name = var.key_name
  user_data = base64encode(data.template_file.user_data.rendered)

  network_interfaces {
    security_groups = concat(var.clients_sg, [aws_security_group.wordpress-servers-sg.id])
  }

  lifecycle {
    create_before_destroy = true
  }
}

########################
## Auto Scaling Group ##
########################
resource "aws_autoscaling_group" "wordpress-autoscaling-group" {
  # Note: Force a redeployment when Launch Template changes.
  # This resets the desired capacity if it was changed due to Auto Scaling events.
  name                 = "${aws_launch_template.launch-template.name}-asg"
  max_size             = var.asg_max_size
  min_size             = var.asg_min_size
  vpc_zone_identifier  = var.private_subnets
  target_group_arns    = [aws_lb_target_group.wordpress-lb-target-group.arn]

  launch_template {
    id      = "${aws_launch_template.launch-template.id}"
    version = "$Latest"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_attachment" "wordpress-asg-attachment" {
  autoscaling_group_name = aws_autoscaling_group.wordpress-autoscaling-group.id
  lb_target_group_arn    = aws_lb_target_group.wordpress-lb-target-group.arn
}

#######################
## CloudWatch Alarms ##
#######################
# Scale-out Alarm: Triggered when CPU > 80% for 1 minute
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60 # Evaluate every 60 seconds
  statistic           = "Average"
  threshold           = 80 # CPU utilization > 80%
  alarm_description   = "Scale out when CPU utilization > 80%"

  dimensions = {
    autoscaling_group_name = aws_autoscaling_group.wordpress-autoscaling-group.id
  }

  alarm_actions = [aws_appautoscaling_policy.scale-out.arn]
}

# Scale-in Alarm: Triggered when CPU < 20% for 1 minute
resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60 # Evaluate every 60 seconds
  statistic           = "Average"
  threshold           = 20 # CPU utilization < 20%
  alarm_description   = "Scale in when CPU utilization < 20%"

  dimensions = {
    autoscaling_group_name = aws_autoscaling_group.wordpress-autoscaling-group.id
  }

  alarm_actions = [aws_appautoscaling_policy.scale-in.arn]
}

######################
## Scaling Policies ##
######################
# Scale-out Policy: Triggered when the CPU utilization exceeds 80%
resource "aws_appautoscaling_policy" "scale-out" {
  name                   = "scale-out-policy"
  policy_type            = "StepScaling"
  resource_id            = "autoScalingGroup/${aws_autoscaling_group.wordpress-autoscaling-group.name}"
  scalable_dimension     = "autoscaling:asg:DesiredCapacity"
  service_namespace      = "autoscaling"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 300
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 80 # Scale out when CPU utilization exceeds 80%
      scaling_adjustment          = 2 # Increase by 2 instances
    }
  }
}

# Scale-in Policy: Triggered when the CPU utilization drops below 20%
resource "aws_appautoscaling_policy" "scale-in" {
  name                   = "scale-in-policy"
  policy_type            = "StepScaling"
  resource_id            = "autoScalingGroup/${aws_autoscaling_group.wordpress-autoscaling-group.name}"
  scalable_dimension     = "autoscaling:asg:DesiredCapacity"
  service_namespace      = "autoscaling"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 300
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 20 # Scale in when CPU utilization is below 20%
      scaling_adjustment          = -1 # Decrease by 1 instance
    }
  }
}

##################
## Bastion Host ##
##################
module "bastion" {
  source = "umotif-public/bastion/aws"
  version = "~> 2.1.0"

  name_prefix    = "${var.prefix_name}"
  ami_id         = var.ami
  vpc_id         = var.vpc_id
  public_subnets = var.public_subnets

  ssh_key_name   = var.key_name

  bastion_instance_types = [var.vm_instance_type]

  tags = {
    Terraform   = "true"
    Environment = var.target_environment
  }
}
