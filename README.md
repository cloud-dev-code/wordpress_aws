# WordPress on AWS - Scalable Infrastructure with Terraform and Jenkins

## Overview
This project provides a scalable **WordPress** infrastructure on **AWS**, designed to automatically scale based on traffic, using EC2 with Auto Scaling Groups, Load Balancer, Aurora, Memcached and EFS. The infrastructure provisioning and management are automated using **Terraform**, and the deployment process is handled via a **Jenkins** pipeline for continuous integration and continuous deployment (CI/CD).

### Quick view of Key Components:
- **EC2 Instances**: to host the WordPress application.
- **Auto Scaling Group**: to automatically scale EC2 instances based on traffic.
- **Amazon Aurora**: to have a scalable and high-performance relational database.
- **Elastic File System (EFS)**: to have shared storage across all EC2 instances.
- **Application Load Balancer (ALB)**: to route traffic to EC2 instances, perform application-level health checks, and manage resources scaling.
- **Jenkins pipeline**: To automate the WordPress application deployment in AWS with Terraform as IaC tool.

## Architecture Diagram
![architecture](./wordpress_aws_architecture.jpg)

### Architecture Components and Flow:

1. **User requests**: HTTP requests from users are routed through an **Application Load Balancer (ALB)** to the EC2 instances hosting WordPress.
2. **Auto Scaling Group**: EC2 instances are dynamically scaled in/out based on the traffic load.
3. **EFS**: All EC2 instances share a common file system to store WordPress content (media, plugins, themes) by using **Amazon Elastic File System (EFS)**.
4. **Aurora**: The WordPress instances connect to the database managed by **Amazon Aurora**.
5. **Memcached**: Memcached is used to cache database queries, objects, and sessions, in order to improve WordPress performance.
6. **Terraform**: Used as IaC tool to automate the provisioning of all infrastructure components (EC2, ALB, Aurora, EFS, etc.).
7. **Jenkins pipeline**: Automates the execution of `terraform plan`, `terraform apply` and `terraform destroy` to manage the WordPress application's deployment, getting code from GitHub and storing Terraform output in S3.

## Requirements

- **AWS account** with permissions to create EC2, EFS, Aurora, Memcached, ALB, Auto Scaling group, IAM, and S3 resources.
- **Terraform** installed locally or on the Jenkins server.
- **AWS CLI** installed and configured on Jenkins for interaction with AWS services.
- **Jenkins server** set up with AWS credentials required for the deployment.
- **Jenkins pipeline** configured on Jenkins to orchestrate the deployment process (to be created with the Jenkinsfile in the repository).
- **Git repository** containing the Terraform IaC for WordPress and Jenkins pipeline definition.

## AWS Infrastructure Setup

The entire infrastructure is created by using Terraform, below the main resources deployment steps.
### 1. **Create EC2 Instances**
   - Create a **Launch Template** for EC2 instances.
   - Configure instances with required software (Apache, WordPress, etc.).
   - Configure **Amazon EFS** to store WordPress files so they can be accessed by all instances.

### 2. **Set up Amazon Aurora**
   - Create a **MySQL-compatible Aurora DB instance** (MariaDB).
   - Configure security groups to allow EC2 instances to connect to database.
   - Ensure WordPress can connect to the database by modifying the `wp-config.php` file during the deployment process.

### 3. **Set up EFS for Shared Storage**
   - Create an **EFS file system** to set up shared storage for WordPress.
   - Mount the EFS filesystem on all EC2 instances to store WordPress content.

### 4. **Auto Scaling Group and Application Load Balancer**
   - Create an **Auto Scaling Group (ASG)** to handle scaling of EC2 instances based on traffic load.
   - Use **CloudWatch** metrics (like CPU utilization) to trigger scaling policies.
   - Attach your EC2 instances to an **Application Load Balancer (ALB)** to distribute traffic across instances.

## Jenkins Pipeline Setup

### 1. **Install required Plugins and set up Git**
   Ensure that the following Jenkins plugins are installed:
   - AWS CLI plugin
   - Terraform plugin
   - Git credentials configured to pull code

### 2. **Create Jenkins pipeline**

Create a Jenkins pipeline from **Jenkinsfile** in the Git repository, below an overview of the stages:

1. **Checkout code**: Clone the repository.
2. **Terraform init**: Run terraform init in the Terraform deployment folder.
3. **Terraform plan**: Create a plan for the WordPress application's deployment.
4. **Terraform apply**: Deploy the WordPress application in AWS.
5. **Terraform destroy**: Destroy the WordPress application in AWS.
6. **Store output in S3**: Store Terraform output files in a S3 bucket.
7. **Clean up**: Any post-deployment steps like clean-up or logging.

### 3. **Run Jenkins pipeline**
Run the Jenkins pipeline running the Terraform deployment by selecting an action. Below a summary of the Jenkins pipeline's parameters:
- REPO_URL
- BRANCH
- WORDPRESS_VERSION (default value: "latest")
- ACTION (plan, apply, destroy)

## Directory structure
```bash
├── Jenkinsfile
├── README.md
├── README_ITA.md
├── wordpress_aws_architecture.jpg
└── terraform_files
    ├── modules
    │   ├── application
    │   |   ├── alb.tf
    │   |   ├── application-out.tf
    │   |   ├── application-var.tf
    │   |   ├── asg.tf
    │   |   └── install_wordpress.sh
    │   ├── data
    │   |   ├── data-out.tf
    │   |   ├── data-var.tf
    │   |   ├── efs.tf
    │   |   ├── memcached.tf
    │   |   └── rds.tf
    │   └── networking
    │       ├── networking-out.tf
    │       ├── networking-var.tf
    │       └── vpc.tf
    ├── main.tf
    └── variables.tf
```
