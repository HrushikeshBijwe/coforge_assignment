provider "aws" {
  region = "us-east-1"
}

resource "aws_ecr_repository" "app_repo" {
  name = "my-app"
}

# IAM Role for App Runner to pull from ECR privately
resource "aws_iam_role" "apprunner_role" {
  name = "AppRunnerECRAccessRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = {
        Service = "build.apprunner.amazonaws.com"
      },
      Effect = "Allow",
    }]
  })
}

resource "aws_iam_policy_attachment" "ecr_access" {
  name       = "AppRunnerECRAccess"
  roles      = [aws_iam_role.apprunner_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_apprunner_service" "app" {
  service_name = "my-app-service"

  source_configuration {
    image_repository {
      image_repository_type = "ECR"
      image_identifier      = "${aws_ecr_repository.app_repo.repository_url}:latest"

      image_configuration {
        port = "8080"
      }
    }

    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_role.arn
    }

    auto_deployments_enabled = true
  }
}
