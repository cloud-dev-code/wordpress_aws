#######################################
## Security Groups for Load Balancer ##
#######################################
resource "aws_security_group" "wordpress-lb-sg" {
  name = "${var.prefix_name}-lb-sg"

  description = "Allow HTTP connection from everywhere"
  vpc_id      = var.vpc_id

  # Accept traffic from everywhere
  ingress {
    from_port        = var.http_port
    to_port          = var.http_port
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
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
    Name        = "${var.prefix_name}-lb-sg"
    Terraform   = "true"
    Environment = var.target_environment
  }
}

###############################
## Application Load Balancer ##
###############################
resource "aws_lb" "wordpress-loadbalancer" {
  name               = "${var.prefix_name}-loadbalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.wordpress-lb-sg.id]
  subnets            = var.public_subnets
  
  tags = {
    Terraform   = "true"
    Environment = var.target_environment
  }
}

resource "aws_lb_listener" "wordpress-lb-listener" {
  load_balancer_arn = aws_lb.wordpress-loadbalancer.arn
  port              = var.http_port
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wordpress-lb-target-group.arn
  }
}

resource "aws_lb_target_group" "wordpress-lb-target-group" {
  name     = "${var.prefix_name}-target-group"
  port     = var.http_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  
  health_check {    
    healthy_threshold   = 3
    unhealthy_threshold = 8
    timeout             = 5
    interval            = 10
    port                = 80
  }
  
  tags = {
    Terraform   = "true"
    Environment = var.target_environment
  }
}
