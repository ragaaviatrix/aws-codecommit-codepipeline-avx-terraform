#create s3 backend for tfstate
module "tfstate_s3_backend" {
  source               = "./s3-backend"
  name_of_s3_bucket    = var.tfstate_s3_bucket_name
  dynamo_db_table_name = var.tfstate_dynamod_db_table_name
  s3_bucket_region     = var.tfstate_s3_bucket_region
}

#create codecommit repo
module "create_repo" {
  source = "./codecommit"
  iam_group_name = var.codecommit_iam_group_name
  iam_user_name = var.codecommit_iam_user_name
  repository_name = var.codecommit_repository_name
  repository_description = var.codecommit_repository_description
}

#create codebuild projects and codepipeline
module "codebuild_codepipeline" {
    source = "./codebuild_and_codepipeline"
    pipeline_s3_bucket = var.pipeline_s3_bucket
    codecommit_repo_name = var.codecommit_repository_name
    dockerhub_credentials = var.dockerhub_credentials
    email_id = var.sns_subscription_email_id
    topic_name = var.sns_topic_name
    depends_on = [
      module.create_repo
    ]
}

resource "local_file" "s3_backend" {
    content  = <<EOT
    terraform {

      backend "s3" {
        bucket         = "${var.tfstate_s3_bucket_name}"
        region         = "${var.tfstate_s3_bucket_region}"
        key            = "${var.tfstate_filename}"
        dynamodb_table = "${var.tfstate_dynamod_db_table_name}"
      }
    }
    EOT
    filename = "${path.module}/use-for-tfstate/backend.tf"
}
