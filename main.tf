# -- Provider Settins --
provider "aws" {
  region = "us-east-1"
}

# -- Common variables --
module "variables" {
    source = "./modules/variables"
}

# -- Networking --
# VPC
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${module.variables.projeto}-${module.variables.candidato}-vpc"
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
    Name = "${module.variables.projeto}-${module.variables.candidato}-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${module.variables.projeto}-${module.variables.candidato}-igw"
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
    Name = "${module.variables.projeto}-${module.variables.candidato}-route_table"
  }
}

resource "aws_route_table_association" "main_association" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.main_route_table.id
}

# -- Keys --
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "${module.variables.projeto}-${module.variables.candidato}-key"
  public_key = tls_private_key.ec2_key.public_key_openssh
}

# -- Security Group --
resource "aws_security_group" "main_sg" {
  name        = "${module.variables.projeto}-${module.variables.candidato}-sg"
  description = "Permitir SSH somente de endereços autorizados"
  vpc_id      = aws_vpc.main_vpc.id

  # Regras de entrada
  ingress {
    description      = "Allow SSH from anywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["8.8.8.8/32"] # IP da Google como exemplo somente.
    ipv6_cidr_blocks = []
  }

  ingress {
    description      = "Allow HTTP from anywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "Allow HTTPS traffic"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # Regras de saída
  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${module.variables.projeto}-${module.variables.candidato}-sg"
  }
}

# -- AMI --
data "aws_ami" "debian12" {
  most_recent = true

  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["679593333241"]
}

# -- EC2 --
resource "aws_instance" "debian_ec2" {
  ami             = data.aws_ami.debian12.id
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.main_subnet.id
  key_name        = aws_key_pair.ec2_key_pair.key_name
  security_groups = [aws_security_group.main_sg.name]

  associate_public_ip_address = true

  root_block_device {
    volume_size           = 20
    volume_type           = "gp2"
    delete_on_termination = true
  }

  user_data = file("./scripts/ec2-setup.sh")

  tags = {
    Name = "${module.variables.projeto}-${module.variables.candidato}-ec2"
  }
}

# --- Outputs ---
output "private_key" {
  description = "Chave privada para acessar a instância EC2"
  value       = tls_private_key.ec2_key.private_key_pem
  sensitive   = true
}

output "ec2_public_ip" {
  description = "Endereço IP público da instância EC2"
  value       = aws_instance.debian_ec2.public_ip
}
