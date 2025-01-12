#!/bin/bash
# Script para crear el archivo .netrc de forma automática

echo "Configurando archivo .netrc para autenticación con Nexus"
pwd

# Crear o sobrescribir el archivo .netrc
echo "machine nexus.alfresco.com" > ~/.netrc
echo "login $NEXUS_USER" >> ~/.netrc
echo "password $NEXUS_PASSWORD" >> ~/.netrc

# Ajustar permisos
chmod 600 ~/.netrc
echo "Archivo .netrc configurado con éxito."
cat ~/.netrc
