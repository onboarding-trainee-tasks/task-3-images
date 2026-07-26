pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    parameters {
        string(
            name: 'VERSION_PREFIX',
            defaultValue: '1.0',
            description: 'Version prefix. Jenkins adds BUILD_NUMBER.'
        )
    }

    environment {
        AWS_ACCESS_KEY_ID = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')

        AWS_REGION = 'eu-central-1'
        AWS_DEFAULT_REGION = 'eu-central-1'

        DOCKER_CONFIG = '/var/lib/jenkins/.docker'
        AWS_ECR_DISABLE_CACHE = 'true'

        PRIVATE_ECR_REGISTRY = (
            '583955898731.dkr.ecr.eu-central-1.amazonaws.com'
        )

        PUBLIC_ECR_REGISTRY = (
            'public.ecr.aws/l8p0g0w4'
        )

        MODEL_REGION = 'eu-central-1'
        MODEL_BUCKET = (
            'llm-models-583955898731-eu-central-1'
        )
        MODEL_OBJECT_KEY = (
            'ollama/tinyllama-models.tar.gz'
        )
    }

    stages {
        stage('Prepare version') {
            steps {
                script {
                    env.IMAGE_TAG = (
                        "${params.VERSION_PREFIX}.${env.BUILD_NUMBER}"
                    )

                    currentBuild.description = env.IMAGE_TAG
                }

                echo "Image tag: ${env.IMAGE_TAG}"
            }
        }

        stage('Check environment') {
            steps {
                sh '''
                    set -eu

                    echo "Current user:"
                    whoami

                    echo "Current workspace:"
                    pwd

                    echo "Docker config:"
                    echo "$DOCKER_CONFIG"

                    git --version
                    docker --version
                    aws --version

                    echo "ECR Credential Helper:"
                    command -v docker-credential-ecr-login

                    echo "AWS identity:"
                    aws sts get-caller-identity

                    echo "Jenkins Docker configuration:"
                    cat "$DOCKER_CONFIG/config.json"
                '''
            }
        }

        stage('Download TinyLlama model') {
            steps {
                sh '''
                    set -eu

                    echo "Removing previous temporary model files"

                    rm -rf ollama/models
                    rm -rf .jenkins-downloads

                    mkdir -p ollama/models/models
                    mkdir -p .jenkins-downloads

                    echo "Downloading TinyLlama from S3"

                    aws s3 cp \
                        "s3://$MODEL_BUCKET/$MODEL_OBJECT_KEY" \
                        ".jenkins-downloads/tinyllama-models.tar.gz" \
                        --region "$MODEL_REGION" \
                        --no-progress

                    echo "Extracting TinyLlama"

                    tar \
                        -xzf \
                        .jenkins-downloads/tinyllama-models.tar.gz \
                        -C ollama/models/models

                    echo "Checking Ollama model structure"

                    test -d ollama/models/models/blobs
                    test -d ollama/models/models/manifests

                    echo "Model size:"
                    du -sh ollama/models/models

                    rm -f \
                        .jenkins-downloads/tinyllama-models.tar.gz
                '''
            }
        }

        stage('Build Grafana') {
            steps {
                sh '''
                    set -eu

                    docker build \
                        --tag \
                        "$PRIVATE_ECR_REGISTRY/grafana:$IMAGE_TAG" \
                        ./grafana
                '''
            }
        }

        stage('Build Prometheus') {
            steps {
                sh '''
                    set -eu

                    docker build \
                        --tag \
                        "$PUBLIC_ECR_REGISTRY/prometheus:$IMAGE_TAG" \
                        ./prometheus
                '''
            }
        }

        stage('Build Alertmanager') {
            steps {
                sh '''
                    set -eu

                    docker build \
                        --tag \
                        "$PUBLIC_ECR_REGISTRY/alertmanager:$IMAGE_TAG" \
                        ./alertmanager
                '''
            }
        }

        stage('Build Ollama') {
            steps {
                sh '''
                    set -eu

                    docker build \
                        --tag \
                        "$PUBLIC_ECR_REGISTRY/ollama-tinyllama:$IMAGE_TAG" \
                        ./ollama
                '''
            }
        }

        stage('Push Grafana') {
            steps {
                sh '''
                    set -eu

                    echo "Pushing Grafana to private ECR"

                    docker push \
                        "$PRIVATE_ECR_REGISTRY/grafana:$IMAGE_TAG"
                '''
            }
        }

        stage('Push public images') {
            steps {
                sh '''
                    set -eu

                    echo "Pushing Prometheus to public ECR"

                    docker push \
                        "$PUBLIC_ECR_REGISTRY/prometheus:$IMAGE_TAG"

                    echo "Pushing Alertmanager to public ECR"

                    docker push \
                        "$PUBLIC_ECR_REGISTRY/alertmanager:$IMAGE_TAG"

                    echo "Pushing Ollama to public ECR"

                    docker push \
                        "$PUBLIC_ECR_REGISTRY/ollama-tinyllama:$IMAGE_TAG"
                '''
            }
        }
    }

    post {
        success {
            echo 'All images were built and pushed successfully.'
            echo "Use IMAGE_TAG=${env.IMAGE_TAG} in Terraform."
        }

        always {
            sh '''
                set +e

                if [ -n "${IMAGE_TAG:-}" ]; then
                    docker image rm \
                        "$PRIVATE_ECR_REGISTRY/grafana:$IMAGE_TAG" \
                        "$PUBLIC_ECR_REGISTRY/prometheus:$IMAGE_TAG" \
                        "$PUBLIC_ECR_REGISTRY/alertmanager:$IMAGE_TAG" \
                        "$PUBLIC_ECR_REGISTRY/ollama-tinyllama:$IMAGE_TAG" \
                        || true
                fi

                docker image prune --force || true
            '''

            cleanWs(
                deleteDirs: true,
                disableDeferredWipeout: true
            )
        }
    }
}