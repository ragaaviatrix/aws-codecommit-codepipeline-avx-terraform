# What does this do?

This will create a end to end AWS pipeline deployment. The code will create the following:

- S3 backend for aviatrix resources
- CodeCommit repo to store aviatrix terraform code. The will also output the username, password and https git clone url to clone the repo to your local machine
- Creation of a SG, private subnet, route table for codebuild. EIP for NAT gw.
- CodeBuild projects for terraform plan and apply, creation and deletion of NAT gateway during deployment
- CodePipeline (with manual approval to prevent auto-apply) to deploy avaitrix resources


# Prerequisites

- Docker hub account https://hub.docker.com/ (A docker image with terraform preinstalled will be used in the codebuild phase)
- AWS secrets
- Aviatrix controller deployed and accounts onboarded

>For docker credentials and aviatrix controller credentials

- Once you create an account in docker hub, create a secret in AWS secrets manager with the username and password you used on docker hub

### Secret for Docker
<img src="https://github.com/ragaaviatrix/aws-codecommit-codepipeline-avx-terraform/blob/main/img/aws_secrets.png?raw=true">

- Obtain the arn of the secret you just created

- Create a secret key AVIATRIX_CONTROLLER_IP with the name controller_ip. The value is the private IP of the controller.
>These will be used as environment variables to login to the controller later during the build stage

### Secret for controller_ip
<img src="https://github.com/ragaaviatrix/aws-codecommit-codepipeline-avx-terraform/blob/main/img/ctrl_ip.png?raw=true">

- Create a secret key AVIATRIX_PASSWORD with the name controller_password

### Secret for controller_password
<img src="https://github.com/ragaaviatrix/aws-codecommit-codepipeline-avx-terraform/blob/main/img/ctrl_pass.png?raw=true">

### Variables
The following variables are required:

key | value
:---|:---
tfstate_s3_bucket_name    |       
tfstate_dynamod_db_table_name     |
tfstate_s3_bucket_region          |
codecommit_iam_group_name         |
codecommit_iam_user_name          |
codecommit_repository_name        |
codecommit_repository_description |
pipeline_s3_bucket                |
dockerhub_credentials             | ARN of the secret created initially
sns_subscription_email_id         |
sns_topic_name                    |
tfstate_filename |
codebuild_az                      | "eu-west-1a"
avtx_ctrl_vpc_id                  | "vpc-082f55ce6f7636247"
codebuild_cidr_block              | "10.41.245.32/28"
subnet_id_for_NATgw               | Public subnet to deploy NAT gw
AviatrixSecurityGroupID           | "sg-0093029b7aabb3ca8"


# How to use

## Step 1
- Download the code, fill out the variable values in terraform.tfvars and then do:
```shell
terraform init
terraform plan
terraform apply
```

Successful completion of the above step would also create a file called backend.tf under the directory **use-for-tfstate**

## Step 2
```shell
git clone <output of repo_clone_url>
```
Use the username and password from the output values

## Step 3
Copy the backend.tf file from the directory **use-for-tfstate** to the cloned repo. This will be used as the S3 backend for aviatrix resources

## Step 4
Add code to the repo

Sample main.tf

```hcl
module "aws_transit" {
  source  = "terraform-aviatrix-modules/mc-transit/aviatrix"
  version = "2.1.3"

  cloud         = "aws"
  region        = "eu-west-3"
  cidr          = "10.1.0.0/23"
  account       = "aws-acc"
}
```

## Step 5

Push the code to the repo and the pipeline will automatically trigger in a few minutes. If everything is OK, the pipeline would stop just before the last stage (terraform apply -auto-approve) and would send an email to the user to manually approve the change

## Step 6

After manual approval, the pipeline would proceed to deploy the resources and finish successfully

A completed pipeline would look like this:
### Pipeline execution 
<img src="https://github.com/ragaaviatrix/aws-codecommit-codepipeline-avx-terraform/blob/main/img/pipeline.png?raw=true">

PS: I reused the base code related to codebuild/pipeline from https://github.com/davoclock/aws-cicd-pipeline and modified it to use AWS codecommit as the source and use AWS secret manager to set environmental vars in the buildspec yml files. I added an approval stage to use SNS notifications to alert the user. I also added additional codebuild projects to create and delete NAT gateway and corresponding codepipeline stages during the workflow. 
