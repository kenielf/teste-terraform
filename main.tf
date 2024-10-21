# -- Provider Settins --
provider "aws" {
  region = "us-east-1"
}

# -- Common variables --
module "variables" {
    source = "./modules/variables"
}

# -- Networking --
module "networking" {
    source  = "./modules/networking"
    projeto = module.variables.projeto
    candidato = module.variables.candidato
}

# -- Keys --
module "keys" {
    source  = "./modules/keys"
    projeto = module.variables.projeto
    candidato = module.variables.candidato
}

# -- Security Group --
resource "aws_security_group" "main_sg" {
  name        = "${module.variables.projeto}-${module.variables.candidato}-sg"
  description = "Permitir SSH somente de endereços autorizados"
  vpc_id      = module.networking.main_vpc.id

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
  subnet_id       = module.networking.main_subnet.id
  key_name        = module.keys.ec2_key_pair.key_name
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
  value       = module.keys.ec2_key.private_key_pem
  sensitive   = true
}

output "ec2_public_ip" {
  description = "Endereço IP público da instância EC2"
  value       = aws_instance.debian_ec2.public_ip
}
