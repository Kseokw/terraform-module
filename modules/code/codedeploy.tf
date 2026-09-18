# ==========================================
# 1. IAM Roles & Instance Profile
# ==========================================

# (1) EC2 Instance Role (ASG Nodes)
resource "aws_iam_role" "asg_node_role" {
  name = "${local.tag_header}AmazonASGNodeEC2-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.asg_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "s3_read" {
  role       = aws_iam_role.asg_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.asg_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "asg_node_profile" {
  name = "${local.tag_header}-ASG-Node-EC2-Instance-Profile"
  role = aws_iam_role.asg_node_role.name
}

# (2) CodeDeploy Service Role
resource "aws_iam_role" "codedeploy_role" {
  name = "${local.tag_header}AmazonCodeDeployService-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "codedeploy.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy_policy" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

# ==========================================
# 2. Launch Template & UserData
# ==========================================

# Amazon Linux 2023 최신 AMI 조회
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_launch_template" "asg_lt" {
  name_prefix            = "${local.tag_header}asg-launch-template-"
  image_id               = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [local.external_alb_sg_id] # ssh, web (external-alb)
  iam_instance_profile {
    name = aws_iam_instance_profile.asg_node_profile.name
  }

  # Docker 및 CodeDeploy Agent 자동 설치 스크립트 (base64 자동 인코딩)
  user_data = base64encode(<<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y ruby wget docker

              systemctl start docker
              systemctl enable docker
              usermod -aG docker ec2-user

              cd /tmp
              wget https://aws-codedeploy-ap-southeast-1.s3.ap-southeast-1.amazonaws.com/latest/install
              chmod +x ./install
              ./install auto

              systemctl start codedeploy-agent
              systemctl enable codedeploy-agent
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${local.tag_header}asg-node-instance"
    }
  }
}

# ==========================================
# 3. Auto Scaling Group
# ==========================================

# 타겟 서브넷 조회 (필요 시 태그 조건 수정)
# data "aws_subnets" "target_subnets" {
#   filter {
#     name   = "tag:Type"
#     values = ["cluster"]
#   }
# }

resource "aws_autoscaling_group" "asg" {
  name             = "${local.tag_header}codedeploy-asg"
  min_size         = 1
  max_size         = 3
  desired_capacity = 2
  # vpc_zone_identifier = data.aws_subnets.target_subnets.ids
  vpc_zone_identifier = local.subnet_ids

  launch_template {
    id      = aws_launch_template.asg_lt.id
    version = "$Default"
  }
}

# ==========================================
# 4. CodeDeploy Application & Deployment Group
# ==========================================

# CodeDeploy Application 생성
resource "aws_codedeploy_app" "app" {
  compute_platform = "Server"
  name             = "${local.tag_header}asg-codedeploy-app"
}

# CodeDeploy Deployment Group 생성 (ASG 연동)
resource "aws_codedeploy_deployment_group" "dg" {
  app_name              = aws_codedeploy_app.app.name
  deployment_group_name = "${local.tag_header}asg-deployment-group"
  service_role_arn      = aws_iam_role.codedeploy_role.arn
  autoscaling_groups    = [aws_autoscaling_group.asg.name]

  deployment_config_name = "CodeDeployDefault.AllAtOnce"
}

# ======================================================================
# 5. CodePipeline 서비스 IAM Role
# ======================================================================

resource "aws_iam_role" "codepipeline_role" {
  name = "${local.tag_header}AmazonCodePipelineService-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "codepipeline.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# CodePipeline 실행 권한 (S3, CodeBuild, CodeDeploy 액세스)
resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "${local.tag_header}CodePipelineServicePolicy"
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:GetObjectVersion", "s3:GetBucketVersioning", "s3:PutObjectAcl", "s3:PutObject"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["codebuild:BatchGetBuilds", "codebuild:StartBuild"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "codedeploy:CreateDeployment",
          "codedeploy:GetApplication",
          "codedeploy:GetApplicationRevision",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:RegisterApplicationRevision",
          "codestar-connections:UseConnection"
        ]
        Resource = "*"
      }
    ]
  })
}

# ======================================================================
# 6. Pipeline Artifacts 저장용 S3 Bucket
# ======================================================================

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "pipeline_bucket" {
  bucket        = "${local.tag_header}-pipeline-artifacts-${random_id.bucket_suffix.hex}"
  force_destroy = true
}

# ######################################################################
# ######################################################################
# 연결 작업
# ======================================================================
# 연결 객체 생성
# AWS - GitHub 간 CodeStar Connection 생성
resource "aws_codestarconnections_connection" "github" {
  name          = "${local.tag_header}-github-connection"
  provider_type = "GitHub"
}


# =======================================================================
# 7. AWS CodePipeline 생성
# =======================================================================

resource "aws_codepipeline" "codepipeline" {
  name     = "${local.tag_header}-asg-cicd-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.pipeline_bucket.bucket
    type     = "S3"
  }

  # Stage 1: Source (GitHub / CodeStar Connection 기준)
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      # 연결객체의 ARN 및 GitHub Repository 정보 기재
      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github.arn # 본인 연결 ARN으로 수정
        FullRepositoryId = "Kseokw/aws-cicd-pipeline"                    # 본인 GitHub 레포지토리로 수정
        BranchName       = "main"
      }
    }
  }

  # Stage 2: Deploy (CodeDeploy ASG 배포)
  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
        ApplicationName     = aws_codedeploy_app.app.name
        DeploymentGroupName = aws_codedeploy_deployment_group.dg.deployment_group_name
      }
    }
  }
}
