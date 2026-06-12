<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=0:1F9BD4,50:2E75B6,100:16265F&height=200&section=header&text=WordpressAWS&fontSize=52&fontColor=ffffff&fontAlignY=38&desc=Deploy%20automatizado%20de%20WordPress%20na%20AWS%20com%20Docker&descAlignY=58&descSize=18&animation=fadeIn" />

<br/>

![AWS](https://img.shields.io/badge/AWS-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![WordPress](https://img.shields.io/badge/WordPress-21759B?style=for-the-badge&logo=wordpress&logoColor=white)
![Shell Script](https://img.shields.io/badge/Shell_Script-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)

<br/>

[![GitHub forks](https://img.shields.io/github/forks/fassir/WordpressAWS?style=flat-square&color=1F9BD4)](https://github.com/fassir/WordpressAWS/network)
[![GitHub stars](https://img.shields.io/github/stars/fassir/WordpressAWS?style=flat-square&color=2E75B6)](https://github.com/fassir/WordpressAWS/stargazers)
[![GitHub issues](https://img.shields.io/github/issues/fassir/WordpressAWS?style=flat-square&color=16265F)](https://github.com/fassir/WordpressAWS/issues)
[![License](https://img.shields.io/badge/license-MIT-1F9BD4?style=flat-square)](LICENSE)

</div>

---

## 🌐 Sobre o Projeto

Este projeto implementa uma infraestrutura completa e automatizada para hospedar **WordPress na AWS**, utilizando serviços gerenciados e orquestração via **Docker Compose**. A solução foi projetada com foco em **escalabilidade**, **disponibilidade** e **segurança**, eliminando exposição direta de IP público das instâncias.

> 💡 O provisionamento é 100% automatizado via `user_data.sh`, executado no Start Instance da EC2 — sem intervenção manual após a inicialização.

<details>
<summary>📋 Objetivos do Projeto</summary>
<br/>

- Hospedar WordPress de forma robusta e escalável na AWS
- Separar responsabilidades: banco de dados, arquivos e aplicação em serviços distintos
- Garantir alta disponibilidade com Load Balancer clássico
- Automatizar toda a instalação com scripts de inicialização
- Usar Docker para containerização portável e reproduzível

</details>

---

## 🏗️ Arquitetura

```
┌────────────────────────────────────────────────────────┐
│                        Internet                        │
└───────────────────────┬────────────────────────────────┘
                        │
              ┌─────────▼──────────┐
              │  Classic Load      │
              │  Balancer (ELB)    │  ← Sem IP público direto
              └─────────┬──────────┘
                        │
              ┌─────────▼──────────┐
              │   EC2 Instance     │
              │   (Docker Host)    │
              │  ┌──────────────┐  │
              │  │ WordPress    │  │
              │  │ Container    │  │
              │  └──────┬───────┘  │
              └─────────┼──────────┘
                        │
        ┌───────────────┼───────────────┐
        │               │               │
┌───────▼──────┐ ┌──────▼───────┐ ┌────▼──────┐
│  RDS MySQL   │ │  EFS Mount   │ │  Docker   │
│  (Managed)   │ │  (Estáticos) │ │  Network  │
└──────────────┘ └──────────────┘ └───────────┘
```

| Componente | Serviço AWS | Função |
|---|---|---|
| **Aplicação** | EC2 + Docker | Hospeda o container WordPress |
| **Banco de Dados** | RDS MySQL/MariaDB | Armazena dados do WordPress (gerenciado) |
| **Arquivos Estáticos** | EFS (Elastic File System) | Mídias e uploads persistentes |
| **Balanceamento** | Classic Load Balancer | Distribui tráfego sem expor IP público |
| **Orquestração** | Docker Compose | Gerencia serviços e dependências |
| **Automação** | user_data.sh | Script de inicialização da EC2 |

---

## 🧰 Stack de Tecnologias

<div align="center">

<a href="https://skillicons.dev">
  <img src="https://skillicons.dev/icons?i=aws,docker,wordpress,bash,linux&theme=dark" />
</a>

<br/><br/>

![Amazon EC2](https://img.shields.io/badge/Amazon_EC2-FF9900?style=flat-square&logo=amazonec2&logoColor=white)
![Amazon RDS](https://img.shields.io/badge/Amazon_RDS-527FFF?style=flat-square&logo=amazonrds&logoColor=white)
![Amazon EFS](https://img.shields.io/badge/Amazon_EFS-FF9900?style=flat-square&logo=amazonaws&logoColor=white)
![Elastic Load Balancing](https://img.shields.io/badge/Load_Balancer-FF9900?style=flat-square&logo=amazonaws&logoColor=white)
![Docker Compose](https://img.shields.io/badge/Docker_Compose-2496ED?style=flat-square&logo=docker&logoColor=white)
![MariaDB](https://img.shields.io/badge/MariaDB-003545?style=flat-square&logo=mariadb&logoColor=white)
![Shell Script](https://img.shields.io/badge/Shell_Script-4EAA25?style=flat-square&logo=gnubash&logoColor=white)

</div>

---

## ⚙️ Pré-requisitos

Antes de iniciar, certifique-se de ter:

- ✅ Conta AWS com permissões para EC2, RDS, EFS e ELB
- ✅ AWS CLI configurada localmente
- ✅ Par de chaves SSH criado na região alvo
- ✅ VPC com subnets públicas e privadas configuradas
- ✅ Security Groups adequados

---

## 🚀 Como Executar

<details>
<summary>📦 Passo 1 — Configurar a infraestrutura AWS</summary>
<br/>

```bash
# 1. Crie o banco de dados RDS (MySQL/MariaDB)
aws rds create-db-instance \
  --db-instance-identifier wordpress-db \
  --db-instance-class db.t3.micro \
  --engine mysql \
  --master-username admin \
  --master-user-password <sua-senha> \
  --allocated-storage 20

# 2. Crie o sistema de arquivos EFS
aws efs create-file-system \
  --performance-mode generalPurpose \
  --throughput-mode bursting \
  --tags Key=Name,Value=wordpress-efs

# 3. Configure os Mount Targets do EFS nas subnets desejadas
aws efs create-mount-target \
  --file-system-id <efs-id> \
  --subnet-id <subnet-id> \
  --security-groups <sg-id>
```

</details>

<details>
<summary>🖥️ Passo 2 — Lançar EC2 com user_data.sh</summary>
<br/>

```bash
# Lance a instância EC2 com o script de inicialização automática
aws ec2 run-instances \
  --image-id ami-0abcdef1234567890 \
  --instance-type t3.small \
  --key-name minha-chave \
  --security-group-ids <sg-id> \
  --subnet-id <subnet-id> \
  --user-data file://user_data.sh \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=wordpress-server}]'
```

O `user_data.sh` realiza automaticamente:

```bash
#!/bin/bash
# Instalação automática via user_data.sh
yum update -y
yum install -y docker amazon-efs-utils
service docker start
usermod -a -G docker ec2-user

# Monta o EFS
mkdir -p /mnt/efs
mount -t efs <efs-id>:/ /mnt/efs

# Instala Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Sobe os containers
cd /home/ec2-user
docker-compose up -d
```

</details>

<details>
<summary>🐳 Passo 3 — Docker Compose</summary>
<br/>

```yaml
# docker-compose.yml
version: '3.8'

services:
  wordpress:
    image: wordpress:latest
    restart: always
    ports:
      - "80:80"
    environment:
      WORDPRESS_DB_HOST: <rds-endpoint>:3306
      WORDPRESS_DB_USER: admin
      WORDPRESS_DB_PASSWORD: ${DB_PASSWORD}
      WORDPRESS_DB_NAME: wordpress
    volumes:
      - /mnt/efs/wordpress:/var/www/html/wp-content
```

</details>

<details>
<summary>⚖️ Passo 4 — Configurar o Load Balancer</summary>
<br/>

```bash
# Crie o Classic Load Balancer
aws elb create-load-balancer \
  --load-balancer-name wordpress-elb \
  --listeners "Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80" \
  --subnets <subnet-id-1> <subnet-id-2> \
  --security-groups <sg-id>

# Registre a instância EC2 no Load Balancer
aws elb register-instances-with-load-balancer \
  --load-balancer-name wordpress-elb \
  --instances <instance-id>
```

</details>

---

## ✨ Funcionalidades

| Funcionalidade | Descrição |
|---|---|
| 🤖 **Provisionamento Automático** | `user_data.sh` instala e configura tudo ao iniciar a EC2 |
| 🐳 **Containerização** | WordPress rodando em Docker — portável e isolado |
| 🗄️ **Banco Gerenciado** | RDS MySQL com backups automáticos e alta disponibilidade |
| 📁 **Arquivos Persistentes** | EFS garante que uploads e mídias sobrevivam a reinicializações |
| 🔒 **Sem IP Público Direto** | Acesso apenas via Load Balancer, aumentando a segurança |
| ⚖️ **Balanceamento de Carga** | Classic ELB distribui tráfego entre instâncias |
| 📈 **Escalabilidade** | Arquitetura preparada para Auto Scaling Groups |

---

## 📂 Estrutura de Arquivos

```
WordpressAWS/
├── 📄 user_data.sh          # Script de inicialização automática da EC2
├── 🐳 docker-compose.yml    # Orquestração dos containers Docker
├── 🔐 .env.example          # Variáveis de ambiente (template)
├── 📋 README.md             # Documentação do projeto
└── 📁 scripts/
    ├── setup-rds.sh         # Script auxiliar para criação do RDS
    ├── setup-efs.sh         # Script auxiliar para criação do EFS
    └── setup-elb.sh         # Script auxiliar para o Load Balancer
```

---

## 🔐 Segurança

<details>
<summary>Boas práticas implementadas</summary>
<br/>

- 🔒 Instâncias EC2 sem IP público — acesso somente via Load Balancer
- 🛡️ Security Groups restritivos por camada (web, app, db)
- 🔑 Credenciais via variáveis de ambiente (nunca hardcoded)
- 🗝️ Acesso SSH apenas via bastion host ou Session Manager
- 📋 RDS em subnet privada — sem acesso direto da internet

</details>

---

## 👤 Autor

<div align="center">

**Fabio Piassi**

[![GitHub](https://img.shields.io/badge/GitHub-fassir-1F9BD4?style=for-the-badge&logo=github&logoColor=white)](https://github.com/fassir)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Fabio_Piassi-2E75B6?style=for-the-badge&logo=linkedin&logoColor=white)](https://linkedin.com/in/fabiopiassi)

*Apaixonado por tecnologia, dados e soluções inteligentes.*
*Formado em Física | Especialista em Ciência de Dados, DevSecOps e IA*
*Volta Redonda — RJ 🇧🇷*

</div>

---

<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=0:16265F,50:2E75B6,100:1F9BD4&height=120&section=footer&fontSize=16&fontColor=ffffff&animation=fadeIn" />

*"Não é sobre ter ideias. É sobre fazer com que elas aconteçam."*

</div>
