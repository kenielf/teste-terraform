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
module "security" {
    source    = "./modules/security"
    projeto   = module.variables.projeto
    candidato = module.variables.candidato
    main_vpc  = module.networking.main_vpc
}

# -- Instances --
module "instances" {
    source  = "./modules/instances"
    projeto = module.variables.projeto
    candidato = module.variables.candidato
    main_subnet  = module.networking.main_subnet
    main_sg      = module.security.main_sg
    ec2_key_pair = module.keys.ec2_key_pair
}

# --- Outputs ---
output "private_key" {
  description = "Chave privada para acessar a instância EC2"
  value       = module.keys.ec2_key.private_key_pem
  sensitive   = true
}

output "ec2_public_ip" {
  description = "Endereço IP público da instância EC2"
  value       = module.instances.debian_ec2.public_ip
}
