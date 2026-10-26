# Onboarding Task 3 — Docker Images

This repository builds and publishes custom Docker images used by the ECS infrastructure in [`task-3-infra`](https://github.com/onboarding-trainee-tasks/task-3-infra).

## Images

| Image | Contents | Registry |
| --- | --- | --- |
| `grafana` | Grafana with provisioned dashboards, data sources and alerting rules | Private Amazon ECR |
| `prometheus` | Prometheus configuration, recording/alert rules and an entrypoint selecting EFS storage by Availability Zone | Amazon ECR Public |
| `alertmanager` | Alertmanager configuration and an entrypoint writing the SMTP password from a container secret | Amazon ECR Public |
| `ollama-tinyllama` | Ollama with a packaged TinyLlama model built using a multi-stage Dockerfile | Amazon ECR Public |

Open WebUI and Node Exporter use separately versioned existing images; they are not built by this repository.

## Requirements

- Docker, AWS CLI and an AWS account with permissions to push to the relevant ECR repositories.
- Amazon ECR Credential Helper with Docker configuration, for example:

  ```json
  {
    "credHelpers": {
      "583955898731.dkr.ecr.eu-central-1.amazonaws.com": "ecr-login",
      "public.ecr.aws": "ecr-login"
    }
  }
  ```

- For the Ollama image, the prebuilt TinyLlama model archive at `s3://tinyllama-llm/ollama/tinyllama-models.tar.gz`.
- For Jenkins, AWS credentials stored under IDs `aws-access-key-id` and `aws-secret-access-key`, Docker access for the Jenkins agent, and the credential-helper config at `/var/lib/jenkins/.docker/config.json`.

## Build and push via Jenkins

The repository's `Jenkinsfile` builds **one selected image per run**, rather than rebuilding all four images.

Use **Build with Parameters**:

- `IMAGE_NAME`: `grafana`, `prometheus`, `alertmanager` or `ollama-tinyllama`.
- `IMAGE_TAG`: an explicit Docker tag, for example `1.0.5` or `review-1`.

The pipeline validates the tag, checks the environment, downloads and extracts the TinyLlama archive if needed, builds the image, pushes it to the appropriate ECR registry and reports the resulting image name. The ECR Credential Helper is used instead of an explicit `docker login`.

After publishing, manually update the corresponding tag in `task-3-infra/image-tags.auto.tfvars` and review the resulting Terraform plan. **Image push does not automatically trigger Terraform deployment.**

## Manual build

From the repository root, set a tag and registry locations:

```bash
export IMAGE_TAG="1.0.5"
export PRIVATE_ECR="583955898731.dkr.ecr.eu-central-1.amazonaws.com"
export PUBLIC_ECR="public.ecr.aws/l8p0g0w4"
```

Build and push an individual image, for example Grafana:

```bash
docker build -t "$PRIVATE_ECR/grafana:$IMAGE_TAG" ./grafana
docker push "$PRIVATE_ECR/grafana:$IMAGE_TAG"
```

For the Ollama image, prepare the model files before running `docker build`:

```bash
mkdir -p ollama/models/models
aws s3 cp \
  s3://tinyllama-llm/ollama/tinyllama-models.tar.gz \
  /tmp/tinyllama-models.tar.gz \
  --region eu-central-1

tar -xzf /tmp/tinyllama-models.tar.gz -C ollama/models/models

docker build -t "$PUBLIC_ECR/ollama-tinyllama:$IMAGE_TAG" ./ollama
docker push "$PUBLIC_ECR/ollama-tinyllama:$IMAGE_TAG"
```

The `ollama/models/` directory is excluded from Git to avoid committing model artifacts.

## Registry references

```text
583955898731.dkr.ecr.eu-central-1.amazonaws.com/grafana
public.ecr.aws/l8p0g0w4/prometheus
public.ecr.aws/l8p0g0w4/alertmanager
public.ecr.aws/l8p0g0w4/ollama-tinyllama
```

Each image has its own tag in the Terraform repository, allowing independent image updates without rebuilding or deploying all services.
