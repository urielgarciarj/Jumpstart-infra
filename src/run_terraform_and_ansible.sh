#!/bin/bash

# Script para ejecutar Terraform y Ansible

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TERRAFORM_DIR="${REPO_DIR}/src/terraform"
ANSIBLE_DIR="${REPO_DIR}/src/ansible"
SSH_KEY_PATH="$HOME/.ssh/jump-start-key.pem"  # Ajusta la ruta a tu clave SSH

# Verificar que Terraform esté instalado
if ! command -v terraform &> /dev/null; then
    echo "Error: Terraform no está instalado. Por favor, instala Terraform antes de continuar."
    echo "Puedes instalarlo con brew: brew install terraform"
    exit 1
fi

# Verificar que Ansible esté instalado
if ! command -v ansible-playbook &> /dev/null; then
    echo "Error: Ansible no está instalado. Por favor, instala Ansible antes de continuar."
    echo "Puedes instalarlo con brew: brew install ansible"
    exit 1
fi

# Verificar que la clave SSH existe
if [ ! -f "${SSH_KEY_PATH}" ]; then
    echo "Error: No se encontró la clave SSH en ${SSH_KEY_PATH}"
    echo "Por favor, asegúrate de que la clave SSH esté en la ubicación correcta o modifica la variable SSH_KEY_PATH en el script."
    exit 1
fi

echo "Ejecutando Terraform..."
cd "${TERRAFORM_DIR}"
terraform init
terraform apply -auto-approve

# Obtener la IP pública de la instancia EC2
EC2_PUBLIC_IP=$(terraform output -raw instance_public_ip)

if [ -z "$EC2_PUBLIC_IP" ]; then
  echo "Error: No se pudo obtener la IP pública de la instancia EC2"
  exit 1
fi

echo "Instancia EC2 desplegada con IP: ${EC2_PUBLIC_IP}"

# Esperar a que la instancia esté lista para conexiones SSH
echo "Esperando a que la instancia esté lista para conexiones SSH..."

COUNTER=0
MAX_ATTEMPTS=30  # 30 intentos * 10 segundos = 300 segundos (5 minutos)
until ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -i "${SSH_KEY_PATH}" ubuntu@"${EC2_PUBLIC_IP}" 'echo SSH ready' 2>/dev/null
do
  echo "Esperando que SSH esté disponible... (intento $((COUNTER+1))/$MAX_ATTEMPTS)"
  COUNTER=$((COUNTER+1))
  if [ $COUNTER -ge $MAX_ATTEMPTS ]; then
    echo "Tiempo de espera agotado después de $MAX_ATTEMPTS intentos."
    exit 1
  fi
  sleep 10
done

# Crear archivo de inventario dinámico
echo "Creando inventario para Ansible..."
cat > "${ANSIBLE_DIR}/inventory" << EOF
[aws_ec2]
${EC2_PUBLIC_IP} ansible_user=ubuntu ansible_ssh_private_key_file=${SSH_KEY_PATH} ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF

# Ejecutar Ansible
echo "Ejecutando Ansible para configurar Docker..."
cd "${ANSIBLE_DIR}"

# Intentar ejecutar ansible-playbook con manejo de errores
if ! ansible-playbook -i inventory install_docker.yml; then
    echo "Error al ejecutar Ansible. Ofreciendo alternativa..."
    echo "Puedes configurar Docker manualmente ejecutando los siguientes comandos en la instancia EC2:"
    echo "-------------------------------------"
    echo "ssh -i ${SSH_KEY_PATH} ubuntu@${EC2_PUBLIC_IP}"
    echo "sudo apt-get update"
    echo "sudo apt-get install -y ca-certificates curl"
    echo "sudo install -m 0755 -d /etc/apt/keyrings"
    echo "sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc"
    echo "sudo chmod a+r /etc/apt/keyrings/docker.asc"
    echo "echo \"deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \$(. /etc/os-release && echo \"\${UBUNTU_CODENAME:-\$VERSION_CODENAME}\") stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null"
    echo "sudo apt-get update"
    echo "sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"
    echo "-------------------------------------"
    exit 1
fi

echo "¡Proceso completado con éxito!"
echo "Puedes conectarte a la instancia con: ssh -i ${SSH_KEY_PATH} ubuntu@${EC2_PUBLIC_IP}"
