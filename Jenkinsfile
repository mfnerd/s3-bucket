pipeline {
    agent any
    environment {
        ARTIFACTORY_URL = "https://trial7hlkhb.jfrog.io/artifactory"
        ARTIFACTORY_REPO = "jfrog-leaper"
        NAMESPACE = "duckets-dev"
        MODULE_NAME = "bucketmaker"
        VERSION = "your-version"
    }
    stages {
        stage('Install JFrog CLI') {
            steps {
                sh '''
                    if ! command -v jfrog &> /dev/null; then
                      echo "JFrog CLI not found. Installing..."
                      curl -fL https://getcli.jfrog.io | sh
                      chmod +x jfrog
                      sudo mv jfrog /usr/local/bin/ || echo "Running with local binary"
                    else
                      echo "JFrog CLI already installed."
                    fi
                '''
            }
        }
        stage('Build Artifact') {
            steps {
                sh 'echo "Building artifact..."'
             
                sh 'mkdir -p dist && echo "dummy content" > dist/test.zip'
            }
        }
        stage('Upload Artifact') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'artifactory-creds', 
                                                  usernameVariable: 'ARTIFACTORY_USER', 
                                                  passwordVariable: 'ARTIFACTORY_API_KEY')]) {
                    sh '''
                        jfrog rt upload "dist/*.zip" "${ARTIFACTORY_REPO}/${NAMESPACE}/${MODULE_NAME}/${VERSION}/" \
                          --url="${ARTIFACTORY_URL}" --user="${ARTIFACTORY_USER}" --apikey="${ARTIFACTORY_API_KEY}"
                    '''
                }
            }
        }
    
    agent any
    parameters {
        choice(name: 'TERRAFORM_ACTION', choices: ['plan', 'apply', 'destroy'], description: 'Choose Terraform action')
    }
    environment {
        AWS_REGION = 'us-east-2' 
    }
    stages {
        stage('Set AWS Credentials') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'jenkins4shep' 
                ]]) {
                    sh '''
                    echo "AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID"
                    aws sts get-caller-identity
                    '''
                }
            }
        }
        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/mfnerd/s3-bucket' 
            }
        }
        stage('Initialize Terraform') {
            steps {
                sh 'terraform init'
            }
        }
        stage('Run Terraform') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'jenkins4shep'
                ]]) {
                    script {
                        if (params.TERRAFORM_ACTION == 'plan') {
                            sh '''
                            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                            terraform plan -out=tfplan
                            '''
                        } else if (params.TERRAFORM_ACTION == 'apply') {
                            input message: "Approve Terraform Apply?", ok: "Deploy"
                            sh '''
                            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                            terraform apply -auto-approve tfplan
                            '''
                        } else if (params.TERRAFORM_ACTION == 'destroy') {
                            input message: "Are you sure you want to destroy all resources?", ok: "Destroy"
                            sh '''
                            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                            terraform destroy -auto-approve
                            '''
                        }
                    }
                }
            }
        }
    }
    post {
        success {
            echo 'Terraform process completed successfully!'
        }
        failure {
            echo 'Terraform process failed!'
        }
    }
}
}
