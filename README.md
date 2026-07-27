# Onboarding task 3 - ECS (image build)

This repository builds the custom Docker images used by the ECS infrastructure.
Build and push the images before running the infrastructure pipeline.

## Implementation Features

* Grafana image with provisioned dashboards, data sources and alerting rules
* Prometheus image with configuration and container alerting rules
* Alertmanager image with Gmail SMTP configuration
* Ollama image with the TinyLlama model included using a multi-stage build
* TinyLlama model is downloaded from S3 during the Jenkins build
* Jenkins tags all custom images as `<VERSION_PREFIX>.<BUILD_NUMBER>`
* Amazon ECR Credential Helper is used instead of `docker login`

## External dependencies

The following items must already exist:

1. **AWS credentials in Jenkins**

   * `aws-access-key-id`
   * `aws-secret-access-key`

2. **Amazon ECR Credential Helper**

   Configured for:

   ```json
   {
     "credHelpers": {
       "583955898731.dkr.ecr.eu-central-1.amazonaws.com": "ecr-login",
       "public.ecr.aws": "ecr-login"
     }
   }
   ```

3. **S3 object with the TinyLlama model**

   ```text
   s3://tinyllama-llm/ollama/tinyllama-models.tar.gz
   ```

4. **ECR repositories**

   ```text
   583955898731.dkr.ecr.eu-central-1.amazonaws.com/grafana

   public.ecr.aws/l8p0g0w4/prometheus
   public.ecr.aws/l8p0g0w4/alertmanager
   public.ecr.aws/l8p0g0w4/ollama-tinyllama
   ```

The `ollama/models/` directory is excluded from Git.

## Manual build

```bash
export IMAGE_TAG="1.0.1"
export PRIVATE_ECR="583955898731.dkr.ecr.eu-central-1.amazonaws.com"
export PUBLIC_ECR="public.ecr.aws/l8p0g0w4"

mkdir -p ollama/models/models

aws s3 cp \
  s3://tinyllama-llm/ollama/tinyllama-models.tar.gz \
  /tmp/tinyllama-models.tar.gz \
  --region eu-central-1

tar -xzf /tmp/tinyllama-models.tar.gz \
  -C ollama/models/models

docker build -t "$PRIVATE_ECR/grafana:$IMAGE_TAG" ./grafana
docker build -t "$PUBLIC_ECR/prometheus:$IMAGE_TAG" ./prometheus
docker build -t "$PUBLIC_ECR/alertmanager:$IMAGE_TAG" ./alertmanager
docker build -t "$PUBLIC_ECR/ollama-tinyllama:$IMAGE_TAG" ./ollama
```

## Push images

```bash
docker push "$PRIVATE_ECR/grafana:$IMAGE_TAG"
docker push "$PUBLIC_ECR/prometheus:$IMAGE_TAG"
docker push "$PUBLIC_ECR/alertmanager:$IMAGE_TAG"
docker push "$PUBLIC_ECR/ollama-tinyllama:$IMAGE_TAG"
```

No manual `docker login` is required when the ECR Credential Helper is configured.

## Jenkins build

Run the `build-images` pipeline with:

```text
VERSION_PREFIX = 1.0
```

For example, Jenkins build number `3` creates the common image tag:

```text
1.0.3
```

Pass this tag to the Terraform pipeline as `IMAGE_TAG`.
