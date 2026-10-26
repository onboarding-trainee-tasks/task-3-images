pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    parameters {
        choice(
            name: 'IMAGE_NAME',
            choices: [
                'grafana',
                'prometheus',
                'alertmanager',
                'ollama-tinyllama'
            ],
            description: 'Docker image to build and push'
        )

        string(
            name: 'IMAGE_TAG',
            defaultValue: '',
            description: 'Image tag, for example 1.0.4 or 13.1.1-llm9'
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
        MODEL_BUCKET = 'tinyllama-llm'
        MODEL_OBJECT_KEY = (
            'ollama/tinyllama-models.tar.gz'
        )
    }

    stages {
        stage('Prepare build') {
            steps {
                script {
                    if (!params.IMAGE_TAG?.trim()) {
                        error('IMAGE_TAG cannot be empty.')
                    }

                    if (!(params.IMAGE_TAG.trim() ==~ /^[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}$/)) {
                        error('IMAGE_TAG is not a valid Docker image tag.')
                    }

                    env.IMAGE_TAG = params.IMAGE_TAG.trim()

                    switch (params.IMAGE_NAME) {
                        case 'grafana':
                            env.IMAGE_CONTEXT = './grafana'
                            env.FULL_IMAGE_NAME = (
                                "${env.PRIVATE_ECR_REGISTRY}/" +
                                "grafana:${env.IMAGE_TAG}"
                            )
                            env.TF_TAG_VARIABLE = (
                                'grafana_image_tag'
                            )
                            break

                        case 'prometheus':
                            env.IMAGE_CONTEXT = './prometheus'
                            env.FULL_IMAGE_NAME = (
                                "${env.PUBLIC_ECR_REGISTRY}/" +
                                "prometheus:${env.IMAGE_TAG}"
                            )
                            env.TF_TAG_VARIABLE = (
                                'prometheus_image_tag'
                            )
                            break

                        case 'alertmanager':
                            env.IMAGE_CONTEXT = './alertmanager'
                            env.FULL_IMAGE_NAME = (
                                "${env.PUBLIC_ECR_REGISTRY}/" +
                                "alertmanager:${env.IMAGE_TAG}"
                            )
                            env.TF_TAG_VARIABLE = (
                                'alertmanager_image_tag'
                            )
                            break

                        case 'ollama-tinyllama':
                            env.IMAGE_CONTEXT = './ollama'
                            env.FULL_IMAGE_NAME = (
                                "${env.PUBLIC_ECR_REGISTRY}/" +
                                "ollama-tinyllama:${env.IMAGE_TAG}"
                            )
                            env.TF_TAG_VARIABLE = (
                                'ollama_image_tag'
                            )
                            break

                        default:
                            error(
                                "Unsupported image: " +
                                params.IMAGE_NAME
                            )
                    }

                    currentBuild.description = (
                        "${params.IMAGE_NAME}:${env.IMAGE_TAG}"
                    )
                }

                echo "Selected image: ${params.IMAGE_NAME}"
                echo "Image tag: ${env.IMAGE_TAG}"
                echo "Full image name: ${env.FULL_IMAGE_NAME}"
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

                    git --version
                    docker --version
                    aws --version

                    echo "ECR Credential Helper:"
                    command -v docker-credential-ecr-login

                    echo "AWS identity:"
                    aws sts get-caller-identity

                    echo "Docker configuration:"
                    cat "$DOCKER_CONFIG/config.json"
                '''
            }
        }

        stage('Download TinyLlama model') {
            when {
                expression {
                    params.IMAGE_NAME == 'ollama-tinyllama'
                }
            }

            steps {
                sh '''
                    set -eu

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

                    test -d ollama/models/models/blobs
                    test -d ollama/models/models/manifests

                    echo "Model size:"
                    du -sh ollama/models/models

                    rm -f \
                        .jenkins-downloads/tinyllama-models.tar.gz
                '''
            }
        }

        stage('Build image') {
            steps {
                sh '''
                    set -eu

                    echo "Building $FULL_IMAGE_NAME"

                    docker build \
                        --tag "$FULL_IMAGE_NAME" \
                        "$IMAGE_CONTEXT"
                '''
            }
        }

        stage('Push image') {
            steps {
                sh '''
                    set -eu

                    echo "Pushing $FULL_IMAGE_NAME"

                    docker push "$FULL_IMAGE_NAME"
                '''
            }
        }
    }

    post {
        success {
            echo 'Image was built and pushed successfully.'
            echo "Image: ${env.FULL_IMAGE_NAME}"

            echo 'Update this value in image-tags.auto.tfvars:'
            echo (
                "${env.TF_TAG_VARIABLE} = " +
                "\"${env.IMAGE_TAG}\""
            )
        }

        failure {
            echo 'Image Pipeline failed. Check the error above.'
        }

        cleanup {
            script {
                if (getContext(hudson.FilePath)) {
                    sh '''
                        set +e

                        if [ -n "${FULL_IMAGE_NAME:-}" ]; then
                            docker image rm \
                                "$FULL_IMAGE_NAME" \
                                || true
                        fi

                        docker image prune --force || true
                    '''

                    cleanWs(
                        deleteDirs: true,
                        disableDeferredWipeout: true
                    )
                } else {
                    echo 'Workspace was not allocated. Cleanup skipped.'
                }
            }
        }
    }
}