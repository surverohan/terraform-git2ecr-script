##Terraform to supprt CI using Codebuild and ECR 

1) configure aws details in terraform.tf as input params

2) run cmd - terraform init

3) run cmd - terraform apply

4) output: 7 resources created

    aws_iam_role.code-build-book
    aws_iam_role_policy.ecr-policy
    aws_iam_role_policy.s3-policy

    aws_s3_bucket.book-build
    aws_codebuild_project.book-build
    aws_codebuild_webhook.book-webhook
    aws_ecr_repository.book-ecr
   




