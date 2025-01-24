#!/bin/bash

# Lista de repositorios a limpiar
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

# Función para limpiar imágenes de un repositorio
clean_repository() {
  local REPO=$1
  echo "Limpiando imágenes del repositorio $REPO..."

  # Obtener los imageDigests
  IMAGE_IDS=$(aws ecr list-images --repository-name "$REPO" --query 'imageIds[*].[imageDigest]' --output text)

  if [ -z "$IMAGE_IDS" ]; then
    echo "El repositorio $REPO está vacío. No hay imágenes para eliminar."
    return
  fi

  # Crear una lista formateada para batch-delete-image
  IMAGE_ID_ARGS=$(echo "$IMAGE_IDS" | awk '{print "{\"imageDigest\":\"" $1 "\"}"}' | paste -sd "," -)
  JSON_PAYLOAD="{\"imageIds\":[$IMAGE_ID_ARGS]}"

  # Llamada única para eliminar todas las imágenes
  echo "Eliminando imágenes del repositorio $REPO..."
  aws ecr batch-delete-image --repository-name "$REPO" --cli-input-json "$JSON_PAYLOAD"

  if [ $? -eq 0 ]; then
    echo "Todas las imágenes del repositorio $REPO han sido eliminadas exitosamente."
  else
    echo "Error al eliminar imágenes del repositorio $REPO."
  fi
}

# Exportar la función para usarla con xargs
export -f clean_repository

# Limpiar los repositorios en paralelo
echo "Iniciando limpieza de repositorios..."
printf "%s\n" "${REPOSITORIES[@]}" | xargs -P 5 -n 1 bash -c 'clean_repository "$0"'

echo "Limpieza de repositorios completada."
