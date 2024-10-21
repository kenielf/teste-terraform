output "ec2_key" {
    value = tls_private_key.ec2_key
}

output "ec2_key_pair" {
   value = aws_key_pair.ec2_key_pair
}
