variable "projeto" {
  description = "Nome do projeto"
  type        = string
}

variable "candidato" {
  description = "Nome do candidato"
  type        = string
}

variable "main_subnet" {
  description = "A sub-rede principal"
}

variable "main_sg" {
  description = "O grupo de segurança principal"
}

variable "ec2_key_pair" {
  description = "O par de chaves para o EC2"
}

