#!/bin/bash

# Script para configurar Docker en una instancia EC2 sin usar Ansible

set -e

# Verificar que se ha proporcionado una IP
if [ $# -ne 1 ]; then
    echo "Uso: $0 <IP_de_instancia_EC2>"
    exit 1
fi

EC2_PUBLIC_IP=$1
SSH_KEY_PATH="$HOME/.ssh/jump-start-key.pem"

# Verificar que la clave SSH existe
if [ ! -f "${SSH_KEY_PATH}" ]; then
    echo "Error: No se encontró la clave SSH en ${SSH_KEY_PATH}"
    echo "Por favor, asegúrate de que la clave SSH esté en la ubicación correcta o modifica la variable SSH_KEY_PATH en el script."
    exit 1
fi

echo "Configurando Docker en la instancia EC2 ${EC2_PUBLIC_IP}..."

# Ejecutar comandos de instalación de Docker mediante SSH
ssh -o StrictHostKeyChecking=no -i "${SSH_KEY_PATH}" ubuntu@"${EC2_PUBLIC_IP}" << 'EOF'
# Actualizar paquetes
sudo apt-get update

# Instalar paquetes necesarios
sudo apt-get install -y ca-certificates curl

# Crear directorio para keyrings
sudo install -m 0755 -d /etc/apt/keyrings

# Descargar clave GPG de Docker
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Añadir repositorio Docker
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Actualizar paquetes con el nuevo repositorio
sudo apt-get update

# Instalar Docker
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Verificar instalación
docker --version
EOF

# Verificar si la configuración fue exitosa
if [ $? -eq 0 ]; then
    echo "¡Docker instalado y configurado con éxito en la instancia EC2!"
    echo "Puedes conectarte a la instancia con: ssh -i ${SSH_KEY_PATH} ubuntu@${EC2_PUBLIC_IP}"
else
    echo "Ocurrió un error durante la configuración de Docker."
    exit 1
fi
