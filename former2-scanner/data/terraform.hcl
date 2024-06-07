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

resource "aws_s3_bucket" "S3Bucket" {
    bucket = "codepipeline-us-east-1-981692970578"
}

resource "aws_opsworks_user_profile" "OpsWorksUserProfile" {
    allow_self_management = false
    user_arn = "arn:aws:iam::471112830639:user/Former2"
    ssh_username = "former2"
}

resource "aws_s3_bucket" "S3Bucket2" {
    bucket = "elasticbeanstalk-us-east-1-471112830639"
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

resource "aws_s3_bucket_policy" "S3BucketPolicy" {
    bucket = "${aws_s3_bucket.S3Bucket.id}"
    policy = "{\"Version\":\"2012-10-17\",\"Id\":\"SSEAndSSLPolicy\",\"Statement\":[{\"Sid\":\"DenyUnEncryptedObjectUploads\",\"Effect\":\"Deny\",\"Principal\":\"*\",\"Action\":\"s3:PutObject\",\"Resource\":\"arn:aws:s3:::codepipeline-us-east-1-981692970578/*\",\"Condition\":{\"StringNotEquals\":{\"s3:x-amz-server-side-encryption\":\"aws:kms\"}}},{\"Sid\":\"DenyInsecureConnections\",\"Effect\":\"Deny\",\"Principal\":\"*\",\"Action\":\"s3:*\",\"Resource\":\"arn:aws:s3:::codepipeline-us-east-1-981692970578/*\",\"Condition\":{\"Bool\":{\"aws:SecureTransport\":\"false\"}}}]}"
}

resource "aws_s3_bucket" "S3Bucket3" {
    bucket = "codepipeline-us-east-2-411623594793"
}

resource "aws_iam_policy" "IAMManagedPolicy" {
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

resource "aws_iam_policy" "IAMManagedPolicy2" {
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

resource "aws_iam_policy" "IAMManagedPolicy3" {
    name = "${aws_iam_role.IAMRole3.name}"
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

resource "aws_s3_bucket_policy" "S3BucketPolicy2" {
    bucket = "${aws_s3_bucket.S3Bucket2.id}"
    policy = "{\"Version\":\"2008-10-17\",\"Statement\":[{\"Sid\":\"eb-ad78f54a-f239-4c90-adda-49e5f56cb51e\",\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::471112830639:role/aws-elasticbeanstalk-ec2-role\"},\"Action\":\"s3:PutObject\",\"Resource\":\"arn:aws:s3:::elasticbeanstalk-us-east-1-471112830639/resources/environments/logs/*\"},{\"Sid\":\"eb-af163bf3-d27b-4712-b795-d1e33e331ca4\",\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::471112830639:role/aws-elasticbeanstalk-ec2-role\"},\"Action\":[\"s3:ListBucket\",\"s3:ListBucketVersions\",\"s3:GetObject\",\"s3:GetObjectVersion\"],\"Resource\":[\"arn:aws:s3:::elasticbeanstalk-us-east-1-471112830639\",\"arn:aws:s3:::elasticbeanstalk-us-east-1-471112830639/resources/environments/*\"]},{\"Sid\":\"eb-58950a8c-feb6-11e2-89e0-0800277d041b\",\"Effect\":\"Deny\",\"Principal\":{\"AWS\":\"*\"},\"Action\":\"s3:DeleteBucket\",\"Resource\":\"arn:aws:s3:::elasticbeanstalk-us-east-1-471112830639\"}]}"
}

resource "aws_s3_bucket" "S3Bucket4" {
    bucket = "darcy-liu-sunlife0524-python-aws-bucket"
}

resource "aws_s3_bucket" "S3Bucket5" {
    bucket = "elasticbeanstalk-us-east-2-471112830639"
}

resource "aws_sns_topic" "SNSTopic" {
    display_name = ""
    name = "codecommit-lab"
}

resource "aws_sns_topic_policy" "SNSTopicPolicy" {
    policy = "{\"Version\":\"2008-10-17\",\"Statement\":[{\"Sid\":\"CodeNotification_publish\",\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"codestar-notifications.amazonaws.com\"},\"Action\":\"SNS:Publish\",\"Resource\":\"arn:aws:sns:us-east-1:471112830639:codecommit-lab\"}]}"
    arn = "arn:aws:sns:us-east-1:471112830639:codecommit-lab"
}

resource "aws_sns_topic_subscription" "SNSSubscription" {
    topic_arn = "arn:aws:sns:us-east-1:471112830639:codecommit-lab"
    endpoint = "awesomefalcon1@gmail.com"
    protocol = "email"
}

resource "aws_sns_topic" "SNSTopic2" {
    display_name = ""
    name = "codestar-notifications-"
}

resource "aws_sns_topic_policy" "SNSTopicPolicy2" {
    policy = "{\"Version\":\"2008-10-17\",\"Statement\":[{\"Sid\":\"CodeNotification_publish\",\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"codestar-notifications.amazonaws.com\"},\"Action\":\"SNS:Publish\",\"Resource\":\"arn:aws:sns:us-east-1:471112830639:codestar-notifications-\"}]}"
    arn = "arn:aws:sns:us-east-1:471112830639:codestar-notifications-"
}

resource "aws_s3_bucket_policy" "S3BucketPolicy3" {
    bucket = "${aws_s3_bucket.S3Bucket3.id}"
    policy = "{\"Version\":\"2012-10-17\",\"Id\":\"SSEAndSSLPolicy\",\"Statement\":[{\"Sid\":\"DenyUnEncryptedObjectUploads\",\"Effect\":\"Deny\",\"Principal\":\"*\",\"Action\":\"s3:PutObject\",\"Resource\":\"arn:aws:s3:::codepipeline-us-east-2-411623594793/*\",\"Condition\":{\"StringNotEquals\":{\"s3:x-amz-server-side-encryption\":\"aws:kms\"}}},{\"Sid\":\"DenyInsecureConnections\",\"Effect\":\"Deny\",\"Principal\":\"*\",\"Action\":\"s3:*\",\"Resource\":\"arn:aws:s3:::codepipeline-us-east-2-411623594793/*\",\"Condition\":{\"Bool\":{\"aws:SecureTransport\":\"false\"}}}]}"
}

resource "aws_codeartifact_repository" "CodeArtifactRepository" {
    repository = "DemoRepository"
    domain = "my-company"
    domain_owner = "471112830639"
    upstream {
        repository_name = "pypi-store"
    }
}

resource "aws_s3_bucket_policy" "S3BucketPolicy4" {
    bucket = "${aws_s3_bucket.S3Bucket5.id}"
    policy = "{\"Version\":\"2008-10-17\",\"Statement\":[{\"Sid\":\"eb-ad78f54a-f239-4c90-adda-49e5f56cb51e\",\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::471112830639:role/aws-elasticbeanstalk-ec2-role\"},\"Action\":\"s3:PutObject\",\"Resource\":\"arn:aws:s3:::elasticbeanstalk-us-east-2-471112830639/resources/environments/logs/*\"},{\"Sid\":\"eb-af163bf3-d27b-4712-b795-d1e33e331ca4\",\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::471112830639:role/aws-elasticbeanstalk-ec2-role\"},\"Action\":[\"s3:ListBucket\",\"s3:ListBucketVersions\",\"s3:GetObject\",\"s3:GetObjectVersion\"],\"Resource\":[\"arn:aws:s3:::elasticbeanstalk-us-east-2-471112830639\",\"arn:aws:s3:::elasticbeanstalk-us-east-2-471112830639/resources/environments/*\"]},{\"Sid\":\"eb-58950a8c-feb6-11e2-89e0-0800277d041b\",\"Effect\":\"Deny\",\"Principal\":{\"AWS\":\"*\"},\"Action\":\"s3:DeleteBucket\",\"Resource\":\"arn:aws:s3:::elasticbeanstalk-us-east-2-471112830639\"}]}"
}

resource "aws_codeartifact_repository" "CodeArtifactRepository2" {
    repository = "pypi-store"
    domain = "my-company"
    domain_owner = "471112830639"
    description = "Provides PyPI artifacts from PyPI."
}

resource "aws_cloudwatch_log_group" "LogsLogGroup" {
    name = "/aws/codebuild/MyBuildProjet"
}

resource "aws_iam_service_linked_role" "IAMServiceLinkedRole" {
    aws_service_name = "codestar-notifications.amazonaws.com"
    description = "Allows AWS CodeStar Notifications to access Amazon CloudWatch Events on your behalf"
}

resource "aws_iam_service_linked_role" "IAMServiceLinkedRole2" {
    aws_service_name = "autoscaling.amazonaws.com"
    description = "Default Service-Linked Role enables access to AWS Services and Resources used or managed by Auto Scaling"
}

resource "aws_iam_service_linked_role" "IAMServiceLinkedRole3" {
    aws_service_name = "organizations.amazonaws.com"
    description = "Service-linked role used by AWS Organizations to enable integration of other AWS services with Organizations."
}

resource "aws_iam_service_linked_role" "IAMServiceLinkedRole4" {
    aws_service_name = "spot.amazonaws.com"
    description = "Default EC2 Spot Service Linked Role"
}

resource "aws_iam_service_linked_role" "IAMServiceLinkedRole5" {
    aws_service_name = "elasticbeanstalk.amazonaws.com"
    description = "Allows Elastic Beanstalk to create and manage AWS resources on your behalf."
}

resource "aws_iam_service_linked_role" "IAMServiceLinkedRole6" {
    aws_service_name = "sso.amazonaws.com"
    description = "Service-linked role used by AWS SSO to manage AWS resources, including IAM roles, policies and SAML IdP on your behalf."
}

resource "aws_iam_group" "IAMGroup" {
    path = "/"
    name = "s3-group"
}

resource "aws_iam_role" "IAMRole" {
    path = "/service-role/"
    name = "aws-elasticbeanstalk-service-role"
    assume_role_policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"elasticbeanstalk.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}"
    max_session_duration = 3600
    tags = {}
}

resource "aws_iam_role" "IAMRole2" {
    path = "/"
    name = "aws-elasticbeanstalk-ec2-role"
    assume_role_policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"ec2.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}"
    max_session_duration = 3600
    tags = {}
}

resource "aws_iam_role" "IAMRole3" {
    path = "/service-role/"
    name = "AWSCodePipelineServiceRole-us-east-2-my-first-pipeline"
    assume_role_policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"codepipeline.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}"
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
    name = "codebuild-MyBuildProjet-service-role"
    assume_role_policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"codebuild.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}"
    max_session_duration = 3600
    tags = {}
}

resource "aws_iam_role" "IAMRole7" {
    path = "/service-role/"
    name = "cwe-role-us-east-1-MyFirstPipeline"
    assume_role_policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"events.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}"
    max_session_duration = 3600
    tags = {}
}

resource "aws_organizations_account" "OrganizationsAccount" {
    name = "darcy.liu.sunlife0524@gmail.com"
    email = "darcy.liu.sunlife0524@gmail.com"
}

resource "aws_iam_user" "IAMUser" {
    path = "/"
    name = "devops-prof"
    tags = {}
}

resource "aws_iam_user" "IAMUser2" {
    path = "/"
    name = "devops-prof-codecommit"
    tags = {}
}

resource "aws_iam_user" "IAMUser3" {
    path = "/"
    name = "Former2"
    tags = {
        AKIAW3MEDJ2XRMS3BZHS = "Former-2-Access-Key"
        AKIAW3MEDJ2XYBRHIGPB = "Vostro-Access-Key"
        AKIAW3MEDJ2XZ6DDNSFE = "FORMER2-ACCOUNT"
    }
}

resource "aws_iam_user" "IAMUser4" {
    path = "/"
    name = "Darcy.Liu"
    tags = {
        AKIAW3MEDJ2XSJPOI6G6 = "Darcy.Liu Access Key"
    }
}

resource "aws_iam_access_key" "IAMAccessKey" {
    status = "Active"
    user = "Darcy.Liu"
}

resource "aws_iam_access_key" "IAMAccessKey2" {
    status = "Active"
    user = "Former2"
}

resource "aws_iam_instance_profile" "IAMInstanceProfile" {
    path = "/"
    name = "${aws_iam_role.IAMRole2.name}"
    roles = [
        "${aws_iam_role.IAMRole2.name}"
    ]
}
