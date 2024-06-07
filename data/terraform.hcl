terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 3.0"
        }
    }
}

provider "aws" {
    region = "us-east-1"
}

resource "aws_codecommit_repository" "CodeCommitRepository" {
    repository_name = "my-nodejs-app"
}

resource "aws_codepipeline" "CodePipelinePipeline" {
    name = "MyFirstPipeline"
    role_arn = "${aws_iam_role.IAMRole4.arn}"
    artifact_store {
        location = "${aws_s3_bucket.S3Bucket.id}"
        type = "S3"
    }
    stages {
        name = "Source"
        action = [
            {
                name = "Source"
                category = "Source"
                owner = "AWS"
                configuration {
                    BranchName = "master"
                    OutputArtifactFormat = "CODE_ZIP"
                    PollForSourceChanges = "false"
                    RepositoryName = "my-nodejs-app"
                }
                provider = "CodeCommit"
                version = "1"
                output_artifacts = [
                    "SourceArtifact"
                ]
                run_order = 1
            }
        ]
    }
    stages {
        name = "BuildAndTest"
        action = [
            {
                name = "TestForCongratulations"
                category = "Build"
                owner = "AWS"
                configuration {
                    ProjectName = "MyBuildProjet"
                }
                input_artifacts = [
                    "SourceArtifact"
                ]
                provider = "CodeBuild"
                version = "1"
                output_artifacts = [
                    "OutputOfTest"
                ]
                run_order = 1
            }
        ]
    }
    stages {
        name = "Deploy"
        action = [
            {
                name = "Deploy"
                category = "Deploy"
                owner = "AWS"
                configuration {
                    ApplicationName = "my-first-webapp-beanstalk"
                    EnvironmentName = "My-first-webapp-beanstalk-dev"
                }
                input_artifacts = [
                    "SourceArtifact"
                ]
                provider = "ElasticBeanstalk"
                version = "1"
                run_order = 1
            }
        ]
    }
    stages {
        name = "DeployToProd"
        action = [
            {
                name = "ManualApprocal"
                category = "Approval"
                owner = "AWS"
                configuration {
                    NotificationArn = "arn:aws:sns:us-east-1:471112830639:codecommit-lab"
                }
                provider = "Manual"
                version = "1"
                run_order = 1
            },
            {
                name = "DeployToProdBeanstalk"
                category = "Deploy"
                owner = "AWS"
                configuration {
                    ApplicationName = "my-first-webapp-beanstalk"
                    EnvironmentName = "My-first-webapp-beanstalk-prod"
                }
                input_artifacts = [
                    "SourceArtifact"
                ]
                provider = "ElasticBeanstalk"
                version = "1"
                run_order = 1
            }
        ]
    }
}

resource "aws_opsworks_user_profile" "OpsWorksUserProfile" {
    allow_self_management = false
    user_arn = "arn:aws:iam::471112830639:user/Former2"
    ssh_username = "former2"
}

resource "aws_instance" "EC2Instance" {
    ami = "ami-0db3991f7809da6c3"
    instance_type = "t3.micro"
    availability_zone = "us-east-1b"
    tenancy = "default"
    ebs_optimized = false
    user_data = "Q29udGVudC1UeXBlOiBtdWx0aXBhcnQvbWl4ZWQ7IGJvdW5kYXJ5PSI9PT09PT09PT09PT09PT01MTg5MDY1Mzc3MjIyODk4NDA3PT0iCk1JTUUtVmVyc2lvbjogMS4wCgotLT09PT09PT09PT09PT09PTUxODkwNjUzNzcyMjI4OTg0MDc9PQpDb250ZW50LVR5cGU6IHRleHQvY2xvdWQtY29uZmlnOyBjaGFyc2V0PSJ1cy1hc2NpaSIKTUlNRS1WZXJzaW9uOiAxLjAKQ29udGVudC1UcmFuc2Zlci1FbmNvZGluZzogN2JpdApDb250ZW50LURpc3Bvc2l0aW9uOiBhdHRhY2htZW50OyBmaWxlbmFtZT0iY2xvdWQtY29uZmlnLnR4dCIKCiNjbG91ZC1jb25maWcKcmVwb191cGdyYWRlOiBub25lCnJlcG9fcmVsZWFzZXZlcjogMjAyMy40CmNsb3VkX2ZpbmFsX21vZHVsZXM6CiAtIFtzY3JpcHRzLXVzZXIsIGFsd2F5c10KCi0tPT09PT09PT09PT09PT09NTE4OTA2NTM3NzIyMjg5ODQwNz09CkNvbnRlbnQtVHlwZTogdGV4dC94LXNoZWxsc2NyaXB0OyBjaGFyc2V0PSJ1cy1hc2NpaSIKTUlNRS1WZXJzaW9uOiAxLjAKQ29udGVudC1UcmFuc2Zlci1FbmNvZGluZzogN2JpdApDb250ZW50LURpc3Bvc2l0aW9uOiBhdHRhY2htZW50OyBmaWxlbmFtZT0idXNlci1kYXRhLnR4dCIKCiMhL2Jpbi9iYXNoCmV4ZWMgPiA+KHRlZSAtYSAvdmFyL2xvZy9lYi1jZm4taW5pdC5sb2d8bG9nZ2VyIC10IFtlYi1jZm4taW5pdF0gLXMgMj4vZGV2L2NvbnNvbGUpIDI+JjEKZWNobyBbYGRhdGUgLXUgKyIlWS0lbS0lZFQlSDolTTolU1oiYF0gU3RhcnRlZCBFQiBVc2VyIERhdGEKc2V0IC14CgoKZnVuY3Rpb24gc2xlZXBfZGVsYXkgCnsKICBpZiAoKCAkU0xFRVBfVElNRSA8ICRTTEVFUF9USU1FX01BWCApKTsgdGhlbiAKICAgIGVjaG8gU2xlZXBpbmcgJFNMRUVQX1RJTUUKICAgIHNsZWVwICRTTEVFUF9USU1FICAKICAgIFNMRUVQX1RJTUU9JCgoJFNMRUVQX1RJTUUgKiAyKSkgCiAgZWxzZSAKICAgIGVjaG8gU2xlZXBpbmcgJFNMRUVQX1RJTUVfTUFYICAKICAgIHNsZWVwICRTTEVFUF9USU1FX01BWCAgCiAgZmkKfQoKIyBFeGVjdXRpbmcgYm9vdHN0cmFwIHNjcmlwdApTTEVFUF9USU1FPTIKU0xFRVBfVElNRV9NQVg9MzYwMAp3aGlsZSB0cnVlOyBkbyAKICBjdXJsIGh0dHBzOi8vZWxhc3RpY2JlYW5zdGFsay1wbGF0Zm9ybS1hc3NldHMtdXMtZWFzdC0xLnMzLmFtYXpvbmF3cy5jb20vc3RhbGtzL2ViX25vZGVqczIwX2FtYXpvbl9saW51eF8yMDIzXzEuMC41NDMuMF8yMDI0MDUxMzE5MzAyNS9saWIvVXNlckRhdGFTY3JpcHQuc2ggPiAvdG1wL2ViYm9vdHN0cmFwLnNoIAogIFJFU1VMVD0kPwogIGlmIFtbICIkUkVTVUxUIiAtbmUgMCBdXTsgdGhlbiAKICAgIHNsZWVwX2RlbGF5IAogIGVsc2UKICAgIC9iaW4vYmFzaCAvdG1wL2ViYm9vdHN0cmFwLnNoICAgICAnaHR0cHM6Ly9jbG91ZGZvcm1hdGlvbi13YWl0Y29uZGl0aW9uLXVzLWVhc3QtMS5zMy5hbWF6b25hd3MuY29tL2FybiUzQWF3cyUzQWNsb3VkZm9ybWF0aW9uJTNBdXMtZWFzdC0xJTNBNDcxMTEyODMwNjM5JTNBc3RhY2svYXdzZWItZS1zMmZtcDM0emtrLXN0YWNrL2ExYWYzYTIwLTIzODYtMTFlZi1hYzU2LTBhZmZjZjI4Y2FmNS9hMWIxNWQwMC0yMzg2LTExZWYtYWM1Ni0wYWZmY2YyOGNhZjUvQVdTRUJJbnN0YW5jZUxhdW5jaFdhaXRIYW5kbGU/WC1BbXotQWxnb3JpdGhtPUFXUzQtSE1BQy1TSEEyNTYmWC1BbXotRGF0ZT0yMDI0MDYwNVQyMTU3NDRaJlgtQW16LVNpZ25lZEhlYWRlcnM9aG9zdCZYLUFtei1FeHBpcmVzPTg2Mzk5JlgtQW16LUNyZWRlbnRpYWw9QUtJQTZMN1E0T1dUM0pSWFUzQlolMkYyMDI0MDYwNSUyRnVzLWVhc3QtMSUyRnMzJTJGYXdzNF9yZXF1ZXN0JlgtQW16LVNpZ25hdHVyZT0wOTFhZjVkYTA5NzBmMjc2YzUxMTk3NGIyMzA0MzJkNGI2ZjE4NmY1NTE4NWI4ODI2NjU3NmY0YjY1NGMyMmYzJyAgICAnYXJuOmF3czpjbG91ZGZvcm1hdGlvbjp1cy1lYXN0LTE6NDcxMTEyODMwNjM5OnN0YWNrL2F3c2ViLWUtczJmbXAzNHpray1zdGFjay9hMWFmM2EyMC0yMzg2LTExZWYtYWM1Ni0wYWZmY2YyOGNhZjUnICAgICc5ZmE4MmM5NS1hNGI3LTQ4YmEtOTY1Mi0zNWI5MDYxZTExNzknICAgICdodHRwczovL2VsYXN0aWNiZWFuc3RhbGstaGVhbHRoLnVzLWVhc3QtMS5hbWF6b25hd3MuY29tJyAgICAnJyAgICAnaHR0cHM6Ly9lbGFzdGljYmVhbnN0YWxrLXBsYXRmb3JtLWFzc2V0cy11cy1lYXN0LTEuczMuYW1hem9uYXdzLmNvbS9zdGFsa3MvZWJfbm9kZWpzMjBfYW1hem9uX2xpbnV4XzIwMjNfMS4wLjU0My4wXzIwMjQwNTEzMTkzMDI1JyAgICAndXMtZWFzdC0xJwogICAgUkVTVUxUPSQ/CiAgICBpZiBbWyAiJFJFU1VMVCIgLW5lIDAgXV07IHRoZW4gCiAgICAgIHNsZWVwX2RlbGF5IAogICAgZWxzZSAKICAgICAgZXhpdCAwICAKICAgIGZpIAogIGZpIApkb25lCgotLT09PT09PT09PT09PT09PTUxODkwNjUzNzcyMjI4OTg0MDc9PS0tIA=="
    tags = {
        elasticbeanstalk:environment-id = "e-s2fmp34zkk"
        elasticbeanstalk:environment-name = "My-first-webapp-beanstalk-dev"
        Name = "My-first-webapp-beanstalk-dev"
    }
}

resource "aws_instance" "EC2Instance2" {
    ami = "ami-0db3991f7809da6c3"
    instance_type = "t3.micro"
    availability_zone = "us-east-1b"
    tenancy = "default"
    ebs_optimized = false
    user_data = "Q29udGVudC1UeXBlOiBtdWx0aXBhcnQvbWl4ZWQ7IGJvdW5kYXJ5PSI9PT09PT09PT09PT09PT01MTg5MDY1Mzc3MjIyODk4NDA3PT0iCk1JTUUtVmVyc2lvbjogMS4wCgotLT09PT09PT09PT09PT09PTUxODkwNjUzNzcyMjI4OTg0MDc9PQpDb250ZW50LVR5cGU6IHRleHQvY2xvdWQtY29uZmlnOyBjaGFyc2V0PSJ1cy1hc2NpaSIKTUlNRS1WZXJzaW9uOiAxLjAKQ29udGVudC1UcmFuc2Zlci1FbmNvZGluZzogN2JpdApDb250ZW50LURpc3Bvc2l0aW9uOiBhdHRhY2htZW50OyBmaWxlbmFtZT0iY2xvdWQtY29uZmlnLnR4dCIKCiNjbG91ZC1jb25maWcKcmVwb191cGdyYWRlOiBub25lCnJlcG9fcmVsZWFzZXZlcjogMjAyMy40CmNsb3VkX2ZpbmFsX21vZHVsZXM6CiAtIFtzY3JpcHRzLXVzZXIsIGFsd2F5c10KCi0tPT09PT09PT09PT09PT09NTE4OTA2NTM3NzIyMjg5ODQwNz09CkNvbnRlbnQtVHlwZTogdGV4dC94LXNoZWxsc2NyaXB0OyBjaGFyc2V0PSJ1cy1hc2NpaSIKTUlNRS1WZXJzaW9uOiAxLjAKQ29udGVudC1UcmFuc2Zlci1FbmNvZGluZzogN2JpdApDb250ZW50LURpc3Bvc2l0aW9uOiBhdHRhY2htZW50OyBmaWxlbmFtZT0idXNlci1kYXRhLnR4dCIKCiMhL2Jpbi9iYXNoCmV4ZWMgPiA+KHRlZSAtYSAvdmFyL2xvZy9lYi1jZm4taW5pdC5sb2d8bG9nZ2VyIC10IFtlYi1jZm4taW5pdF0gLXMgMj4vZGV2L2NvbnNvbGUpIDI+JjEKZWNobyBbYGRhdGUgLXUgKyIlWS0lbS0lZFQlSDolTTolU1oiYF0gU3RhcnRlZCBFQiBVc2VyIERhdGEKc2V0IC14CgoKZnVuY3Rpb24gc2xlZXBfZGVsYXkgCnsKICBpZiAoKCAkU0xFRVBfVElNRSA8ICRTTEVFUF9USU1FX01BWCApKTsgdGhlbiAKICAgIGVjaG8gU2xlZXBpbmcgJFNMRUVQX1RJTUUKICAgIHNsZWVwICRTTEVFUF9USU1FICAKICAgIFNMRUVQX1RJTUU9JCgoJFNMRUVQX1RJTUUgKiAyKSkgCiAgZWxzZSAKICAgIGVjaG8gU2xlZXBpbmcgJFNMRUVQX1RJTUVfTUFYICAKICAgIHNsZWVwICRTTEVFUF9USU1FX01BWCAgCiAgZmkKfQoKIyBFeGVjdXRpbmcgYm9vdHN0cmFwIHNjcmlwdApTTEVFUF9USU1FPTIKU0xFRVBfVElNRV9NQVg9MzYwMAp3aGlsZSB0cnVlOyBkbyAKICBjdXJsIGh0dHBzOi8vZWxhc3RpY2JlYW5zdGFsay1wbGF0Zm9ybS1hc3NldHMtdXMtZWFzdC0xLnMzLmFtYXpvbmF3cy5jb20vc3RhbGtzL2ViX25vZGVqczIwX2FtYXpvbl9saW51eF8yMDIzXzEuMC41NDMuMF8yMDI0MDUxMzE5MzAyNS9saWIvVXNlckRhdGFTY3JpcHQuc2ggPiAvdG1wL2ViYm9vdHN0cmFwLnNoIAogIFJFU1VMVD0kPwogIGlmIFtbICIkUkVTVUxUIiAtbmUgMCBdXTsgdGhlbiAKICAgIHNsZWVwX2RlbGF5IAogIGVsc2UKICAgIC9iaW4vYmFzaCAvdG1wL2ViYm9vdHN0cmFwLnNoICAgICAnaHR0cHM6Ly9jbG91ZGZvcm1hdGlvbi13YWl0Y29uZGl0aW9uLXVzLWVhc3QtMS5zMy5hbWF6b25hd3MuY29tL2FybiUzQWF3cyUzQWNsb3VkZm9ybWF0aW9uJTNBdXMtZWFzdC0xJTNBNDcxMTEyODMwNjM5JTNBc3RhY2svYXdzZWItZS1lNGNoMzNhNmliLXN0YWNrLzFkMzZjZGIwLTIzODgtMTFlZi1hMGQzLTBhZmZlYjhmNzg1MS8xZDM4YTI3MC0yMzg4LTExZWYtYTBkMy0wYWZmZWI4Zjc4NTEvQVdTRUJJbnN0YW5jZUxhdW5jaFdhaXRIYW5kbGU/WC1BbXotQWxnb3JpdGhtPUFXUzQtSE1BQy1TSEEyNTYmWC1BbXotRGF0ZT0yMDI0MDYwNVQyMjA4MjFaJlgtQW16LVNpZ25lZEhlYWRlcnM9aG9zdCZYLUFtei1FeHBpcmVzPTg2Mzk5JlgtQW16LUNyZWRlbnRpYWw9QUtJQTZMN1E0T1dUM0pSWFUzQlolMkYyMDI0MDYwNSUyRnVzLWVhc3QtMSUyRnMzJTJGYXdzNF9yZXF1ZXN0JlgtQW16LVNpZ25hdHVyZT01ZDA0ZmQzZDNiNWY1MTgyZDc0YThlOTI4N2Q3OWFlNjM5MGFjMzExYzU2YjJlMmUzMmEyNDBiZDQ3NjE5Mjg2JyAgICAnYXJuOmF3czpjbG91ZGZvcm1hdGlvbjp1cy1lYXN0LTE6NDcxMTEyODMwNjM5OnN0YWNrL2F3c2ViLWUtZTRjaDMzYTZpYi1zdGFjay8xZDM2Y2RiMC0yMzg4LTExZWYtYTBkMy0wYWZmZWI4Zjc4NTEnICAgICc2MzJlZWY1Yi1jOTQ4LTRjM2UtYjA2Zi0yN2E5ZGU1ZDIwMjknICAgICdodHRwczovL2VsYXN0aWNiZWFuc3RhbGstaGVhbHRoLnVzLWVhc3QtMS5hbWF6b25hd3MuY29tJyAgICAnJyAgICAnaHR0cHM6Ly9lbGFzdGljYmVhbnN0YWxrLXBsYXRmb3JtLWFzc2V0cy11cy1lYXN0LTEuczMuYW1hem9uYXdzLmNvbS9zdGFsa3MvZWJfbm9kZWpzMjBfYW1hem9uX2xpbnV4XzIwMjNfMS4wLjU0My4wXzIwMjQwNTEzMTkzMDI1JyAgICAndXMtZWFzdC0xJwogICAgUkVTVUxUPSQ/CiAgICBpZiBbWyAiJFJFU1VMVCIgLW5lIDAgXV07IHRoZW4gCiAgICAgIHNsZWVwX2RlbGF5IAogICAgZWxzZSAKICAgICAgZXhpdCAwICAKICAgIGZpIAogIGZpIApkb25lCgotLT09PT09PT09PT09PT09PTUxODkwNjUzNzcyMjI4OTg0MDc9PS0tIA=="
    tags = {
        Name = "My-first-webapp-beanstalk-prod"
        elasticbeanstalk:environment-id = "e-e4ch33a6ib"
        elasticbeanstalk:environment-name = "My-first-webapp-beanstalk-prod"
    }
}

resource "aws_organizations_organization" "OrganizationsOrganization" {
    aws_service_access_principals = [
        "sso.amazonaws.com"
    ]
    enabled_policy_types = [
        "SERVICE_CONTROL_POLICY"
    ]
    feature_set = "ALL"
}

resource "aws_s3_bucket" "S3Bucket" {
    bucket = "codepipeline-us-east-1-981692970578"
}

resource "aws_budgets_budget" "BudgetsBudget" {
    limit_amount = "1.0"
    limit_unit = "USD"
    time_unit = "MONTHLY"
    cost_filters {}
    name = "My Zero-Spend Budget"
    cost_types {
        include_support = true
        include_other_subscription = true
        include_tax = true
        include_subscription = true
        use_blended = false
        include_upfront = true
        include_discount = true
        include_credit = false
        include_recurring = true
        use_amortized = false
        include_refund = false
    }
    budget_type = "COST"
}

resource "aws_iam_policy" "IAMManagedPolicy" {
    name = "${aws_iam_role.IAMRole6.name}"
    path = "/service-role/"
    policy = <<EOF
{
    "Statement": [
        {
            "Action": [
                "iam:PassRole"
            ],
            "Resource": "*",
            "Effect": "Allow",
            "Condition": {
                "StringEqualsIfExists": {
                    "iam:PassedToService": [
                        "cloudformation.amazonaws.com",
                        "elasticbeanstalk.amazonaws.com",
                        "ec2.amazonaws.com",
                        "ecs-tasks.amazonaws.com"
                    ]
                }
            }
        },
        {
            "Action": [
                "codecommit:CancelUploadArchive",
                "codecommit:GetBranch",
                "codecommit:GetCommit",
                "codecommit:GetRepository",
                "codecommit:GetUploadArchiveStatus",
                "codecommit:UploadArchive"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "codedeploy:CreateDeployment",
                "codedeploy:GetApplication",
                "codedeploy:GetApplicationRevision",
                "codedeploy:GetDeployment",
                "codedeploy:GetDeploymentConfig",
                "codedeploy:RegisterApplicationRevision"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "codestar-connections:UseConnection"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "elasticbeanstalk:*",
                "ec2:*",
                "elasticloadbalancing:*",
                "autoscaling:*",
                "cloudwatch:*",
                "s3:*",
                "sns:*",
                "cloudformation:*",
                "rds:*",
                "sqs:*",
                "ecs:*"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "lambda:InvokeFunction",
                "lambda:ListFunctions"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "opsworks:CreateDeployment",
                "opsworks:DescribeApps",
                "opsworks:DescribeCommands",
                "opsworks:DescribeDeployments",
                "opsworks:DescribeInstances",
                "opsworks:DescribeStacks",
                "opsworks:UpdateApp",
                "opsworks:UpdateStack"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "cloudformation:CreateStack",
                "cloudformation:DeleteStack",
                "cloudformation:DescribeStacks",
                "cloudformation:UpdateStack",
                "cloudformation:CreateChangeSet",
                "cloudformation:DeleteChangeSet",
                "cloudformation:DescribeChangeSet",
                "cloudformation:ExecuteChangeSet",
                "cloudformation:SetStackPolicy",
                "cloudformation:ValidateTemplate"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "codebuild:BatchGetBuilds",
                "codebuild:StartBuild",
                "codebuild:BatchGetBuildBatches",
                "codebuild:StartBuildBatch"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Effect": "Allow",
            "Action": [
                "devicefarm:ListProjects",
                "devicefarm:ListDevicePools",
                "devicefarm:GetRun",
                "devicefarm:GetUpload",
                "devicefarm:CreateUpload",
                "devicefarm:ScheduleRun"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "servicecatalog:ListProvisioningArtifacts",
                "servicecatalog:CreateProvisioningArtifact",
                "servicecatalog:DescribeProvisioningArtifact",
                "servicecatalog:DeleteProvisioningArtifact",
                "servicecatalog:UpdateProduct"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "cloudformation:ValidateTemplate"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecr:DescribeImages"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "states:DescribeExecution",
                "states:DescribeStateMachine",
                "states:StartExecution"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "appconfig:StartDeployment",
                "appconfig:StopDeployment",
                "appconfig:GetDeployment"
            ],
            "Resource": "*"
        }
    ],
    "Version": "2012-10-17"
}
EOF
}

resource "aws_iam_policy" "IAMManagedPolicy2" {
    name = "CodeBuildBasePolicy-MyBuildProjet-us-east-1"
    path = "/service-role/"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Resource": [
                "arn:aws:logs:us-east-1:471112830639:log-group:/aws/codebuild/MyBuildProjet",
                "arn:aws:logs:us-east-1:471112830639:log-group:/aws/codebuild/MyBuildProjet:*"
            ],
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ]
        },
        {
            "Effect": "Allow",
            "Resource": [
                "arn:aws:s3:::codepipeline-us-east-1-*"
            ],
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:GetBucketAcl",
                "s3:GetBucketLocation"
            ]
        },
        {
            "Effect": "Allow",
            "Resource": [
                "arn:aws:codecommit:us-east-1:471112830639:my-nodejs-app"
            ],
            "Action": [
                "codecommit:GitPull"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "codebuild:CreateReportGroup",
                "codebuild:CreateReport",
                "codebuild:UpdateReport",
                "codebuild:BatchPutTestCases",
                "codebuild:BatchPutCodeCoverages"
            ],
            "Resource": [
                "arn:aws:codebuild:us-east-1:471112830639:report-group/MyBuildProjet-*"
            ]
        }
    ]
}
EOF
}

resource "aws_cloudwatch_event_rule" "EventsRule" {
    name = "awscodestarnotifications-rule"
    description = "This rule is used to route CodeBuild, CodeCommit, CodeDeploy, CodePipeline, and other Code Suite notifications to CodeStar Notifications"
    event_pattern = "{\"source\":[\"aws.codebuild\",\"aws.codecommit\",\"aws.codedeploy\",\"aws.codepipeline\"]}"
}

resource "aws_cloudwatch_event_target" "CloudWatchEventTarget" {
    rule = "awscodestarnotifications-rule"
    arn = "arn:aws:events:us-east-1:471112830639:rule/awscodestarnotifications-rule"
}

resource "aws_cloudwatch_event_rule" "EventsRule2" {
    name = "codepipeline-mynode-master-173517-rule"
    description = "Amazon CloudWatch Events rule to automatically start your pipeline when a change occurs in the AWS CodeCommit source repository and branch. Deleting this may prevent changes from being detected in that pipeline. Read more: http://docs.aws.amazon.com/codepipeline/latest/userguide/pipelines-about-starting.html"
    event_pattern = "{\"source\":[\"aws.codecommit\"],\"detail-type\":[\"CodeCommit Repository State Change\"],\"resources\":[\"arn:aws:codecommit:us-east-1:471112830639:my-nodejs-app\"],\"detail\":{\"event\":[\"referenceCreated\",\"referenceUpdated\"],\"referenceType\":[\"branch\"],\"referenceName\":[\"master\"]}}"
}

resource "aws_cloudwatch_event_target" "CloudWatchEventTarget2" {
    rule = "codepipeline-mynode-master-173517-rule"
    arn = "arn:aws:events:us-east-1:471112830639:rule/codepipeline-mynode-master-173517-rule"
}

resource "aws_iam_policy" "IAMManagedPolicy3" {
    name = "${aws_iam_role.IAMRole4.name}"
    path = "/service-role/"
    policy = <<EOF
{
    "Statement": [
        {
            "Action": [
                "iam:PassRole"
            ],
            "Resource": "*",
            "Effect": "Allow",
            "Condition": {
                "StringEqualsIfExists": {
                    "iam:PassedToService": [
                        "cloudformation.amazonaws.com",
                        "elasticbeanstalk.amazonaws.com",
                        "ec2.amazonaws.com",
                        "ecs-tasks.amazonaws.com"
                    ]
                }
            }
        },
        {
            "Action": [
                "codecommit:CancelUploadArchive",
                "codecommit:GetBranch",
                "codecommit:GetCommit",
                "codecommit:GetRepository",
                "codecommit:GetUploadArchiveStatus",
                "codecommit:UploadArchive"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "codedeploy:CreateDeployment",
                "codedeploy:GetApplication",
                "codedeploy:GetApplicationRevision",
                "codedeploy:GetDeployment",
                "codedeploy:GetDeploymentConfig",
                "codedeploy:RegisterApplicationRevision"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "codestar-connections:UseConnection"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "elasticbeanstalk:*",
                "ec2:*",
                "elasticloadbalancing:*",
                "autoscaling:*",
                "cloudwatch:*",
                "s3:*",
                "sns:*",
                "cloudformation:*",
                "rds:*",
                "sqs:*",
                "ecs:*"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "lambda:InvokeFunction",
                "lambda:ListFunctions"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "opsworks:CreateDeployment",
                "opsworks:DescribeApps",
                "opsworks:DescribeCommands",
                "opsworks:DescribeDeployments",
                "opsworks:DescribeInstances",
                "opsworks:DescribeStacks",
                "opsworks:UpdateApp",
                "opsworks:UpdateStack"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "cloudformation:CreateStack",
                "cloudformation:DeleteStack",
                "cloudformation:DescribeStacks",
                "cloudformation:UpdateStack",
                "cloudformation:CreateChangeSet",
                "cloudformation:DeleteChangeSet",
                "cloudformation:DescribeChangeSet",
                "cloudformation:ExecuteChangeSet",
                "cloudformation:SetStackPolicy",
                "cloudformation:ValidateTemplate"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "codebuild:BatchGetBuilds",
                "codebuild:StartBuild",
                "codebuild:BatchGetBuildBatches",
                "codebuild:StartBuildBatch"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Effect": "Allow",
            "Action": [
                "devicefarm:ListProjects",
                "devicefarm:ListDevicePools",
                "devicefarm:GetRun",
                "devicefarm:GetUpload",
                "devicefarm:CreateUpload",
                "devicefarm:ScheduleRun"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "servicecatalog:ListProvisioningArtifacts",
                "servicecatalog:CreateProvisioningArtifact",
                "servicecatalog:DescribeProvisioningArtifact",
                "servicecatalog:DeleteProvisioningArtifact",
                "servicecatalog:UpdateProduct"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "cloudformation:ValidateTemplate"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecr:DescribeImages"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "states:DescribeExecution",
                "states:DescribeStateMachine",
                "states:StartExecution"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "appconfig:StartDeployment",
                "appconfig:StopDeployment",
                "appconfig:GetDeployment"
            ],
            "Resource": "*"
        }
    ],
    "Version": "2012-10-17"
}
EOF
}

resource "aws_iam_policy" "IAMManagedPolicy4" {
    name = "start-pipeline-execution-us-east-2-my-first-pipeline"
    path = "/service-role/"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "codepipeline:StartPipelineExecution"
            ],
            "Resource": [
                "arn:aws:codepipeline:us-east-2:471112830639:my-first-pipeline"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_policy" "IAMManagedPolicy5" {
    name = "start-pipeline-execution-us-east-1-MyFirstPipeline"
    path = "/service-role/"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "codepipeline:StartPipelineExecution"
            ],
            "Resource": [
                "arn:aws:codepipeline:us-east-1:471112830639:MyFirstPipeline"
            ]
        }
    ]
}
EOF
}

resource "aws_s3_bucket" "S3Bucket2" {
    bucket = "elasticbeanstalk-us-east-1-471112830639"
}

resource "aws_s3_bucket_policy" "S3BucketPolicy" {
    bucket = "${aws_s3_bucket.S3Bucket.id}"
    policy = "{\"Version\":\"2012-10-17\",\"Id\":\"SSEAndSSLPolicy\",\"Statement\":[{\"Sid\":\"DenyUnEncryptedObjectUploads\",\"Effect\":\"Deny\",\"Principal\":\"*\",\"Action\":\"s3:PutObject\",\"Resource\":\"arn:aws:s3:::codepipeline-us-east-1-981692970578/*\",\"Condition\":{\"StringNotEquals\":{\"s3:x-amz-server-side-encryption\":\"aws:kms\"}}},{\"Sid\":\"DenyInsecureConnections\",\"Effect\":\"Deny\",\"Principal\":\"*\",\"Action\":\"s3:*\",\"Resource\":\"arn:aws:s3:::codepipeline-us-east-1-981692970578/*\",\"Condition\":{\"Bool\":{\"aws:SecureTransport\":\"false\"}}}]}"
}

resource "aws_s3_bucket" "S3Bucket3" {
    bucket = "codepipeline-us-east-2-411623594793"
}

resource "aws_s3_bucket" "S3Bucket4" {
    bucket = "darcy-liu-sunlife0524-python-aws-bucket"
}

resource "aws_elastic_beanstalk_environment" "ElasticBeanstalkEnvironment" {
    name = "My-first-webapp-beanstalk-prod"
    application = "my-first-webapp-beanstalk"
    solution_stack_name = "64bit Amazon Linux 2023 v6.1.5 running Node.js 20"
    platform_arn = "arn:aws:elasticbeanstalk:us-east-1::platform/Node.js 20 running on 64bit Amazon Linux 2023/6.1.5"
    tier {
        Name = "WebServer"
        Type = "Standard"
        Version = "1.0"
    }
    cname_prefix = "My-first-webapp-beanstalk-prod"
}

resource "aws_elastic_beanstalk_environment" "ElasticBeanstalkEnvironment2" {
    name = "My-first-webapp-beanstalk-dev"
    application = "my-first-webapp-beanstalk"
    version_label = "code-pipeline-1717625352257-02321a84a80721718cc3195f38cb942a61cf920b"
    solution_stack_name = "64bit Amazon Linux 2023 v6.1.5 running Node.js 20"
    platform_arn = "arn:aws:elasticbeanstalk:us-east-1::platform/Node.js 20 running on 64bit Amazon Linux 2023/6.1.5"
    tier {
        Name = "WebServer"
        Type = "Standard"
        Version = "1.0"
    }
    cname_prefix = "My-first-webapp-beanstalk-dev"
}

resource "aws_sns_topic" "SNSTopic" {
    display_name = ""
    name = "codestar-notifications-"
}

resource "aws_sns_topic_policy" "SNSTopicPolicy" {
    policy = "{\"Version\":\"2008-10-17\",\"Statement\":[{\"Sid\":\"CodeNotification_publish\",\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"codestar-notifications.amazonaws.com\"},\"Action\":\"SNS:Publish\",\"Resource\":\"arn:aws:sns:us-east-1:471112830639:codestar-notifications-\"}]}"
    arn = "arn:aws:sns:us-east-1:471112830639:codestar-notifications-"
}

resource "aws_sns_topic" "SNSTopic2" {
    display_name = ""
    name = "codecommit-lab"
}

resource "aws_sns_topic_policy" "SNSTopicPolicy2" {
    policy = "{\"Version\":\"2008-10-17\",\"Statement\":[{\"Sid\":\"CodeNotification_publish\",\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"codestar-notifications.amazonaws.com\"},\"Action\":\"SNS:Publish\",\"Resource\":\"arn:aws:sns:us-east-1:471112830639:codecommit-lab\"}]}"
    arn = "arn:aws:sns:us-east-1:471112830639:codecommit-lab"
}

resource "aws_sns_topic_subscription" "SNSSubscription" {
    topic_arn = "arn:aws:sns:us-east-1:471112830639:codecommit-lab"
    endpoint = "awesomefalcon1@gmail.com"
    protocol = "email"
}

resource "aws_s3_bucket_policy" "S3BucketPolicy2" {
    bucket = "${aws_s3_bucket.S3Bucket2.id}"
    policy = "{\"Version\":\"2008-10-17\",\"Statement\":[{\"Sid\":\"eb-ad78f54a-f239-4c90-adda-49e5f56cb51e\",\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::471112830639:role/aws-elasticbeanstalk-ec2-role\"},\"Action\":\"s3:PutObject\",\"Resource\":\"arn:aws:s3:::elasticbeanstalk-us-east-1-471112830639/resources/environments/logs/*\"},{\"Sid\":\"eb-af163bf3-d27b-4712-b795-d1e33e331ca4\",\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::471112830639:role/aws-elasticbeanstalk-ec2-role\"},\"Action\":[\"s3:ListBucket\",\"s3:ListBucketVersions\",\"s3:GetObject\",\"s3:GetObjectVersion\"],\"Resource\":[\"arn:aws:s3:::elasticbeanstalk-us-east-1-471112830639\",\"arn:aws:s3:::elasticbeanstalk-us-east-1-471112830639/resources/environments/*\"]},{\"Sid\":\"eb-58950a8c-feb6-11e2-89e0-0800277d041b\",\"Effect\":\"Deny\",\"Principal\":{\"AWS\":\"*\"},\"Action\":\"s3:DeleteBucket\",\"Resource\":\"arn:aws:s3:::elasticbeanstalk-us-east-1-471112830639\"}]}"
}

resource "aws_s3_bucket" "S3Bucket5" {
    bucket = "elasticbeanstalk-us-east-2-471112830639"
}

resource "aws_codeartifact_repository" "CodeArtifactRepository" {
    repository = "pypi-store"
    domain = "my-company"
    domain_owner = "471112830639"
    description = "Provides PyPI artifacts from PyPI."
}

resource "aws_s3_bucket_policy" "S3BucketPolicy3" {
    bucket = "${aws_s3_bucket.S3Bucket3.id}"
    policy = "{\"Version\":\"2012-10-17\",\"Id\":\"SSEAndSSLPolicy\",\"Statement\":[{\"Sid\":\"DenyUnEncryptedObjectUploads\",\"Effect\":\"Deny\",\"Principal\":\"*\",\"Action\":\"s3:PutObject\",\"Resource\":\"arn:aws:s3:::codepipeline-us-east-2-411623594793/*\",\"Condition\":{\"StringNotEquals\":{\"s3:x-amz-server-side-encryption\":\"aws:kms\"}}},{\"Sid\":\"DenyInsecureConnections\",\"Effect\":\"Deny\",\"Principal\":\"*\",\"Action\":\"s3:*\",\"Resource\":\"arn:aws:s3:::codepipeline-us-east-2-411623594793/*\",\"Condition\":{\"Bool\":{\"aws:SecureTransport\":\"false\"}}}]}"
}

resource "aws_codeartifact_repository" "CodeArtifactRepository2" {
    repository = "DemoRepository"
    domain = "my-company"
    domain_owner = "471112830639"
    upstream {
        repository_name = "pypi-store"
    }
}

resource "aws_iam_service_linked_role" "IAMServiceLinkedRole" {
    aws_service_name = "elasticbeanstalk.amazonaws.com"
    description = "Allows Elastic Beanstalk to create and manage AWS resources on your behalf."
}

resource "aws_iam_service_linked_role" "IAMServiceLinkedRole2" {
    aws_service_name = "organizations.amazonaws.com"
    description = "Service-linked role used by AWS Organizations to enable integration of other AWS services with Organizations."
}

resource "aws_iam_service_linked_role" "IAMServiceLinkedRole3" {
    aws_service_name = "spot.amazonaws.com"
    description = "Default EC2 Spot Service Linked Role"
}

resource "aws_iam_service_linked_role" "IAMServiceLinkedRole4" {
    aws_service_name = "sso.amazonaws.com"
    description = "Service-linked role used by AWS SSO to manage AWS resources, including IAM roles, policies and SAML IdP on your behalf."
}

resource "aws_s3_bucket_policy" "S3BucketPolicy4" {
    bucket = "${aws_s3_bucket.S3Bucket5.id}"
    policy = "{\"Version\":\"2008-10-17\",\"Statement\":[{\"Sid\":\"eb-ad78f54a-f239-4c90-adda-49e5f56cb51e\",\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::471112830639:role/aws-elasticbeanstalk-ec2-role\"},\"Action\":\"s3:PutObject\",\"Resource\":\"arn:aws:s3:::elasticbeanstalk-us-east-2-471112830639/resources/environments/logs/*\"},{\"Sid\":\"eb-af163bf3-d27b-4712-b795-d1e33e331ca4\",\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::471112830639:role/aws-elasticbeanstalk-ec2-role\"},\"Action\":[\"s3:ListBucket\",\"s3:ListBucketVersions\",\"s3:GetObject\",\"s3:GetObjectVersion\"],\"Resource\":[\"arn:aws:s3:::elasticbeanstalk-us-east-2-471112830639\",\"arn:aws:s3:::elasticbeanstalk-us-east-2-471112830639/resources/environments/*\"]},{\"Sid\":\"eb-58950a8c-feb6-11e2-89e0-0800277d041b\",\"Effect\":\"Deny\",\"Principal\":{\"AWS\":\"*\"},\"Action\":\"s3:DeleteBucket\",\"Resource\":\"arn:aws:s3:::elasticbeanstalk-us-east-2-471112830639\"}]}"
}

resource "aws_iam_service_linked_role" "IAMServiceLinkedRole5" {
    aws_service_name = "codestar-notifications.amazonaws.com"
    description = "Allows AWS CodeStar Notifications to access Amazon CloudWatch Events on your behalf"
}

resource "aws_cloudwatch_log_group" "LogsLogGroup" {
    name = "/aws/codebuild/MyBuildProjet"
}

resource "aws_iam_group" "IAMGroup" {
    path = "/"
    name = "s3-group"
}

resource "aws_iam_service_linked_role" "IAMServiceLinkedRole6" {
    aws_service_name = "autoscaling.amazonaws.com"
    description = "Default Service-Linked Role enables access to AWS Services and Resources used or managed by Auto Scaling"
}

resource "aws_iam_role" "IAMRole" {
    path = "/"
    name = "aws-elasticbeanstalk-ec2-role"
    assume_role_policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"ec2.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}"
    max_session_duration = 3600
    tags = {}
}

resource "aws_iam_role" "IAMRole2" {
    path = "/service-role/"
    name = "aws-elasticbeanstalk-service-role"
    assume_role_policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"elasticbeanstalk.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}"
    max_session_duration = 3600
    tags = {}
}

resource "aws_iam_role" "IAMRole3" {
    path = "/service-role/"
    name = "cwe-role-us-east-1-MyFirstPipeline"
    assume_role_policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"events.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}"
    max_session_duration = 3600
    tags = {}
}

resource "aws_iam_role" "IAMRole4" {
    path = "/service-role/"
    name = "AWSCodePipelineServiceRole-us-east-1-MyFirstPipeline"
    assume_role_policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"codepipeline.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}"
    max_session_duration = 3600
    tags = {}
}

resource "aws_iam_role" "IAMRole5" {
    path = "/service-role/"
    name = "cwe-role-us-east-2-my-first-pipeline"
    assume_role_policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"events.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}"
    max_session_duration = 3600
    tags = {}
}

resource "aws_iam_role" "IAMRole6" {
    path = "/service-role/"
    name = "AWSCodePipelineServiceRole-us-east-2-my-first-pipeline"
    assume_role_policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"codepipeline.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}"
    max_session_duration = 3600
    tags = {}
}

resource "aws_iam_role" "IAMRole7" {
    path = "/service-role/"
    name = "codebuild-MyBuildProjet-service-role"
    assume_role_policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"codebuild.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}"
    max_session_duration = 3600
    tags = {}
}

resource "aws_organizations_account" "OrganizationsAccount" {
    name = "darcy.liu.sunlife0524@gmail.com"
    email = "darcy.liu.sunlife0524@gmail.com"
}

resource "aws_iam_user" "IAMUser" {
    path = "/"
    name = "devops-prof-codecommit"
    tags = {}
}

resource "aws_iam_user" "IAMUser2" {
    path = "/"
    name = "devops-prof"
    tags = {}
}

resource "aws_iam_user" "IAMUser3" {
    path = "/"
    name = "Darcy.Liu"
    tags = {
        AKIAW3MEDJ2XSJPOI6G6 = "Darcy.Liu Access Key"
    }
}

resource "aws_iam_user" "IAMUser4" {
    path = "/"
    name = "Former2"
    tags = {
        AKIAW3MEDJ2XYBRHIGPB = "Vostro-Access-Key"
        AKIAW3MEDJ2XZ6DDNSFE = "FORMER2-ACCOUNT"
    }
}

resource "aws_iam_access_key" "IAMAccessKey" {
    status = "Active"
    user = "Former2"
}

resource "aws_iam_access_key" "IAMAccessKey2" {
    status = "Active"
    user = "Darcy.Liu"
}

resource "aws_iam_instance_profile" "IAMInstanceProfile" {
    path = "/"
    name = "${aws_iam_role.IAMRole.name}"
    roles = [
        "${aws_iam_role.IAMRole.name}"
    ]
}
