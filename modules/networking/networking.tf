# VPC
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.projeto}-${var.candidato}-vpc"
  }
}

# VPC: Logs
resource "aws_s3_bucket" "vpc_logs_bucket" {
  bucket = "vpc_logs_bucket"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "VPC Flow Logs Bucket"
  }
}

resource "aws_s3_bucket_versioning" "vpc_logs_versioning" {
  bucket = aws_s3_bucket.vpc_logs_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_iam_role" "vpc_logs_role" {
  name = "vpc_logs_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Effect    = "Allow"
        Sid       = ""
      }
    ]
  })
}

resource "aws_iam_policy" "vpc_logs_policy" {
  name        = "vpc_logs_policy"
  description = "Policy to allow VPC Flow Logs to write to S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = "${aws_s3_bucket.vpc_logs_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.vpc_logs_role.name
  policy_arn = aws_iam_policy.vpc_logs_policy.arn
}

resource "aws_flow_log" "vpc_logs" {
  vpc_id                  = aws_vpc.main_vpc.id
  traffic_type            = "ALL"
  log_destination         = aws_s3_bucket.vpc_logs_bucket.arn
  log_destination_type    = "s3"
  iam_role_arn            = aws_iam_role.vpc_logs_role.arn
}

# Subnet
resource "aws_subnet" "main_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "${var.projeto}-${var.candidato}-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.projeto}-${var.candidato}-igw"
  }
}

# Route Table
resource "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "${var.projeto}-${var.candidato}-route_table"
  }
}

resource "aws_route_table_association" "main_association" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.main_route_table.id
}
