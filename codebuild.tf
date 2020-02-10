resource "aws_s3_bucket" "book-build" {
   bucket = "${var.AWS_S3_BUCKET_NAME}"
  acl = "private"

  lifecycle_rule {
    enabled = true

    transition {
      days = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days = 60
      storage_class = "GLACIER"
    }
  }

}

resource "aws_iam_role" "code-build-book" {
  name = "book-codebuild"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "s3-policy" {
  role = "${aws_iam_role.code-build-book.name}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "${aws_s3_bucket.book-build.arn}",
        "${aws_s3_bucket.book-build.arn}/*"
      ]
    }
  ]
}
EOF 
}


resource "aws_iam_role_policy" "ecr-policy" {
  role   = "${aws_iam_role.code-build-book.name}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:GetRepositoryPolicy",
                "ecr:DescribeRepositories",
                "ecr:ListImages",
                "ecr:DescribeImages",
                "ecr:BatchGetImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:PutImage"
            ],
            "Resource": "*"
        }
    ]
}
EOF 
}


resource "aws_codebuild_project" "book-build" {
  name = "book-build"
  description = "Easy build to generate docker image for Golang Applications"
  build_timeout = "5"
  service_role = "${aws_iam_role.code-build-book.arn}"

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type = "S3"
    location = "${aws_s3_bucket.book-build.bucket}"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image = "aws/codebuild/standard:2.0"
    type = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
privileged_mode = true

   environment_variable {
      name = "AWS_DEFAULT_REGION"
      value = "${var.AWS_REGION}"
    }
   environment_variable {
      name = "AWS_ACCOUNT_ID"
      value = "${var.AWS_ACCOUNT_ID}"
    }

    environment_variable {
      name = "IMAGE_REPO_NAME"
      value = "${var.IMAGE_REPO_NAME}"
    }

  }

  logs_config {
    cloudwatch_logs {
      group_name = "log-group"
      stream_name = "log-stream"
    }

    s3_logs {
      status = "ENABLED"
      location = "${aws_s3_bucket.book-build.id}/build-log"
    }
  }

  source {
    type = "GITHUB"
    location = "${var.URL_REPO}"
    git_clone_depth = 1
    buildspec = "${file("buildspec.yml")}"
  }
 
}


resource "aws_codebuild_webhook" "book-webhook" {
  project_name = "${aws_codebuild_project.book-build.name}"

  filter_group {
    filter {
      type = "EVENT"
      pattern = "PUSH"
    } 


  }
}



resource "aws_ecr_repository" "book-ecr" {
  name = "${var.IMAGE_REPO_NAME}"
}
