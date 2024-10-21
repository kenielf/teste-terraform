# Teste Terraform
## Método de Uso
primeiramente, clone o repositório e navegue até sua pasta com:
```bash
git clone https://github.com/kenielf/teste-terraform.git
cd teste-terraform
```

Então, inicialize o terraform e aplique as suas mudanças:
```bash
terraform init
terraform apply
```

Para destruir os recursos criados, use:
```bash
terraform destroy
```


## Documentação
### Releases
É possível acessar os PDFs dos relatórios pré-compilados a partir do [release].

[release]: https://github.com/kenielf/teste-terraform/releases/tag/v1.0.0

### Compilação
Para compilar por conta própria, faça questão de que o ambiente `texlive` 
esteja instalado e configurado para disponibilizar a aplicação `lualatex`.

Acesse a pasta de docs e execute:
```bash
./build.sh
```

