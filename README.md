# Jumpstart-infra
Infraestructure for JumpStart project

## Configuración de Docker con Terraform y Ansible

Este proyecto automatiza el despliegue de una instancia EC2 en AWS y la instalación de Docker utilizando Terraform y Ansible.

## Requisitos previos

- AWS CLI configurado con credenciales de acceso
- Terraform instalado
- Ansible instalado
- Clave SSH configurada en AWS

## Estructura del proyecto

```
Jumpstart-infra/
├── README.md
├── src/
│   ├── ansible/
│   │   ├── ansible.cfg
│   │   ├── install_docker.yml
│   │   └── inventory
│   ├── terraform/
│   │   └── main.tf
│   └── run_terraform_and_ansible.sh
```

## Uso

1. Asegúrate de tener la clave SSH en `~/.ssh/jump-start-key.pem` o modifica la ruta en el script

2. Ejecuta el script de automatización:

```bash
cd Jumpstart-infra
./src/run_terraform_and_ansible.sh
```

3. El script realizará las siguientes acciones:
   - Desplegará la infraestructura con Terraform
   - Obtendrá la IP de la instancia EC2
   - Esperará a que la instancia esté lista para SSH
   - Configurará Docker usando Ansible

## Detalles de configuración

### Terraform
- Despliega una instancia EC2 Ubuntu en AWS
- Configura un grupo de seguridad para SSH
- Utiliza una VPC existente
- Asigna una IP pública a la instancia

### Ansible
- Instala Docker y Docker Compose
- Configura el repositorio oficial de Docker
- Añade el usuario al grupo docker
- Verifica la instalación

## Limpieza

Para eliminar la infraestructura desplegada:

```bash
cd src/terraform
terraform destroy
```