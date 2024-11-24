pipeline {
    agent any

    environment {
        AWS_REGION = "us-east-1"
        S3_BUCKET = "wordpress-terraform-deployment"
        TERRAFORM_FOLDER = "terraform_files"
    }

    parameters {
        string(name: 'REPO_URL', defaultValue: 'git@github.com:cloud-dev-code/test_for_jenkins.git', description: 'Git repository URL')
        string(name: 'BRANCH', defaultValue: 'main', description: 'Git branch to checkout')
        string(name: 'WORDPRESS_VERSION', defaultValue: 'latest', description: "WordPress version to install")
        choice(name: 'ACTION', choices: ['plan', 'apply', 'destroy'], description: 'Terraform action to perform')
    }

    stages {
        stage('Clone Repository') {
            steps {
                script {
                    git url: params.REPO_URL, branch: params.BRANCH, credentialsId: 'cloud-dev-code'
                }
            }
        }

        stage('Pipeline Setup') {
            steps {
                script {
                    dir("${env.JOB_NAME}") {
                        withEnv([
                            "TERRAFORM_ACTION=${params.ACTION}",
                            "WORDPRESS_VERSION=${params.WORDPRESS_VERSION}"
                        ]) {
                            echo "Running pipeline ${env.JOB_NAME}..."
                            
                            sh '''
                                aws --version
                                echo "Terraform action: $TERRAFORM_ACTION"
                                echo "WordPress version: $WORDPRESS_VERSION"
                            '''
                        }
                    }
                }
            }
        }

        stage('Terraform init') {
            steps {
                script {
                    dir("${env.JOB_NAME}/${TERRAFORM_FOLDER}") {
                        sh '''
                            echo "Terraform files for deployment:"
                            ls -R
                            terraform init
                            ls
                        '''
                    }
                }
            }
        }

        stage('Terraform plan') {
            when {
                expression {
                    params.ACTION == 'plan'
                }
            }
            steps {
                script {
                    dir("${env.JOB_NAME}/${TERRAFORM_FOLDER}") {
                        withEnv([
                            "WORDPRESS_VERSION=${params.WORDPRESS_VERSION}"
                        ]) {
                            sh '''
                                echo "Running Terraform plan only"
                                terraform plan -var "wordpress_version=$WORDPRESS_VERSION" -out tfplan
                                terraform show -no-color tfplan > tfplan.txt
                            '''
                        }
                    }
                }
            }
        }
        
        stage('Terraform apply') {
            when {
                expression {
                    params.ACTION == 'apply'
                }
            }
            steps {
                script {
                    dir("${env.JOB_NAME}/${TERRAFORM_FOLDER}") {
                        withEnv([
                            "WORDPRESS_VERSION=${params.WORDPRESS_VERSION}"
                        ]) {
                            sh '''
                                echo "Running Terraform apply"
                                terraform apply -var "wordpress_version=$WORDPRESS_VERSION" --auto-approve
                            '''
                        }
                    }
                }
            }
        }

        stage('Terraform destroy') {
            when {
                expression {
                    params.ACTION == 'destroy'
                }
            }
            steps {
                script {
                    dir("${env.JOB_NAME}/${TERRAFORM_FOLDER}") {
                        sh '''
                            echo "Running Terraform destroy"
                            terraform destroy --auto-approve
                        '''
                    }
                }
            }
        }

        stage('Upload Terraform files to S3') {
            steps {
                script {
                    dir("${env.JOB_NAME}/${TERRAFORM_FOLDER}") {
                        withEnv([
                            "TERRAFORM_ACTION=${params.ACTION}"
                        ]) {
                            sh '''
                                if [ "${TERRAFORM_ACTION}" = "apply" ]; then
                                    echo "Apply complete, uploading Terraform files to S3:"
                                    ls -R
                                    aws s3 cp . s3://${S3_BUCKET}/ --recursive --region ${AWS_REGION} \
                                      --exclude "*" \
                                      --include "*.tf" \
                                      --include "*.tfvars" \
                                      --include "*.tfstate" \
                                      --include "*.tfstate.backup" \
                                      --include "*.tfplan"
                                elif [ "${TERRAFORM_ACTION}" = "destroy" ]; then
                                    echo "Destroy complete, deleting Terraform files from S3"
                                    aws s3 rm s3://${S3_BUCKET} --recursive --region ${AWS_REGION}
                                fi
                            '''
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            // Perform cleanup as post action if needed
            echo 'Cleaning up after the build...'
        }

        success {
            echo 'Build completed successfully!'
        }

        failure {
            echo 'Build failed!'
        }
    }
}
