#!/bin/bash

# Lista de repositorios a crear
REPOSITORIES=(
  "alfresco/alfresco-control-center"
  "alfresco/repository_community"
  "alfresco/share_community"
  "alfresco/tengine_pdfrenderer"
  "alfresco/tengine_imagemagick"
  "alfresco/tengine_misc"
  "alfresco/tengine_aio"
  "alfresco/search_service"
  "alfresco/tengine_libreoffice"
  "alfresco/alfresco-pdf-renderer"
  "alfresco/alfresco-transform-misc"
  # enterprise
  "alfresco/alfresco-content-repository"                     
  "alfresco/alfresco-share"                                  
  "alfresco/alfresco-transform-core-aio"                     
  "alfresco/alfresco-base-tomcat"                            
  "alfresco/alfresco-imagemagick"                            
  "alfresco/alfresco-tika"                                   
  "alfresco/alfresco-libreoffice"                            
  "alfresco/alfresco-sync-service"                           
  "alfresco/alfresco-transform-router"                       
  "alfresco/alfresco-pdf-renderer"                           
  "alfresco/alfresco-ms-teams-service"                       
  "alfresco/alfresco-elasticsearch-live-indexing-content"    
  "alfresco/alfresco-elasticsearch-live-indexing-metadata"   
  "alfresco/alfresco-ooi-service"                            
  "alfresco/alfresco-elasticsearch-live-indexing"            
  "alfresco/alfresco-shared-file-store"                      
  "alfresco/alfresco-elasticsearch-reindexing"               
  "alfresco/alfresco-elasticsearch-live-indexing-mediation"  
  "alfresco/alfresco-elasticsearch-live-indexing-path"       
  "alfresco/alfresco-audit-storage"                          
  "alfresco/alfresco-transform-misc"                         
  "alfresco/alfresco-base-java"                              
  "alfresco/alfresco-control-center"                         
  "alfresco/alfresco-digital-workspace"       
)

# Obtener la lista de repositorios existentes en AWS ECR
echo "Obteniendo lista de repositorios existentes..."
EXISTING_REPOS=$(aws ecr describe-repositories --query 'repositories[*].repositoryName' --output text)

# Función para validar y crear repositorio si no existe
validate_and_create() {
  REPO=$1
  if echo "$EXISTING_REPOS" | grep -qw "$REPO"; then
    echo "El repositorio $REPO ya existe."
  else
    echo "El repositorio $REPO no existe. Creándolo..."
    aws ecr create-repository --repository-name "$REPO" && echo "Repositorio $REPO creado exitosamente." || echo "Error al crear el repositorio $REPO."
  fi
}

# Validar y crear repositorios en paralelo
export EXISTING_REPOS
export -f validate_and_create
printf "%s\n" "${REPOSITORIES[@]}" | xargs -P 10 -n 1 bash -c 'validate_and_create "$0"'
