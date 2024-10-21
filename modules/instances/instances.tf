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
  subnet_id       = var.main_subnet.id
  key_name        = var.ec2_key_pair.key_name
  security_groups = [var.main_sg.name]

  associate_public_ip_address = true

  root_block_device {
    volume_size           = 20
    volume_type           = "gp2"
    delete_on_termination = true
  }

  user_data = file("./scripts/ec2-setup.sh")

  tags = {
    Name = "${var.projeto}-${var.candidato}-ec2"
  }
}
