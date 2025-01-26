
# Guía Completa: Instalación de Alfresco en un Clúster EKS

Este documento describe paso a paso cómo configurar un clúster de Kubernetes (EKS) desde AWS Cloud9 e instalar Alfresco Content Services. Se incluyen configuraciones detalladas, ejemplos de código y secciones de troubleshooting para resolver problemas comunes.

## Configuración Inicial del Ambiente en Cloud9


### Preparación de Cloud9
1. **Lanza una instancia de Cloud9** en la misma VPC donde planeas desplegar tu clúster EKS.
2. Asegúrate de que la instancia tenga permisos administrativos necesarios para gestionar recursos en AWS.

### Limpiar y recuperar espacio de Cloud 9

A continuación, te mostraré algunos pasos para limpiar tu entorno y recuperar espacio antes de volver a ejecutar make:
1.	Eliminar las Imágenes, Contenedores y Caché de Docker

Para liberar espacio ocupado por imágenes, contenedores y volúmenes que ya no necesitas, ejecuta:

```bash
docker system prune -a --volumes -f
```

Este comando:
  - docker system prune: Limpia contenedores detenidos, capas intermedias y demás.
  - -a: Incluirá imágenes no referenciadas por ningún contenedor.
  -	--volumes: Limpiará también volúmenes sin uso.
  -	-f: Forzará la acción sin solicitar confirmación.

Esto debería recuperar una buena cantidad de espacio.

2.	Limpiar los Artefactos del Proyecto Alfresco Dockerfiles Bakery
Si el repositorio Bakery guarda los artefactos descargados en artifacts_cache/, eliminarlos te permitirá comenzar de nuevo.

Desde el directorio raíz del repositorio, ejecuta:
```bash
make clean
```
El make clean está pensado para remover artefactos y dejar el proyecto en un estado inicial.
Si no existe una regla clean o no libera todo, puedes manualmente borrar la carpeta de artefactos:

```bash
rm -rf artifacts_cache/**
```
Esto obliga a fetch-artifacts.sh a descargarlos de nuevo cuando se ejecute el make.

3.	Verificar el Espacio Disponible
En tu máquina local o en el entorno Cloud9, puedes verificar el espacio con:
```bash
df -h
```
Esto mostrará el uso del disco en todos los sistemas de archivos. Asegúrate de tener suficiente espacio antes de volver a ejecutar la compilación.



### Paso 2: Instalación
Ejecuta los siguientes comandos en la terminal de Cloud9 para instalar las herramientas necesarias:

```bash
sudo yum update -y
```

instalar kubectl
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
kubectl version --client
```

instalar eksctl
```bash
curl --silent --location "https://github.com/weaveworks/eksctl/releases/download/v0.140.0/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
eksctl version

#Actualizado:
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
eksctl version
```
Instalar Helm
```bash
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 > get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh

helm version | cut -d + -f 1
```

### Paso 3: Configuración de AWS CLI
Configura las credenciales de AWS con el siguiente comando:

```bash
aws configure
```

Proporciona:
- **AWS Access Key ID** y **Secret Access Key** (debes generarlos desde la consola de IAM).
- **Región por defecto** (por ejemplo, `us-east-1`).
- **Formato de salida** (puedes usar `json`).


#### Troubleshooting: Conexion EKS y Cloud9 con `aws configure`

- **Problema:** Error `InvalidClientTokenId` al ejecutar comandos de AWS CLI.
  - **Solución:** Asegúrate de que las credenciales proporcionadas sean válidas.
    ```bash
    aws sts get-caller-identity
    ```



- **Problema:** no se pude conectar con el comando ```kubectl get nodes``` 
  - **Solución:** Limpieza del Archivo `~/.aws/credentials`
  - Asegúrate de que el archivo solo contenga las claves de acceso:
    ```ini
    [default]
    aws_access_key_id = AKIA2...
    aws_secret_access_key = 0bqc...
    ```
    ***NOTA:*** No incluyas tokens manuales en este archivo, ya que los genera dinámicamente `aws eks get-token`.

## Configuración de Claves de repositorio Nexus

La modificación para configurar la autenticación al servidor de Nexus de Alfresco se realiza creando o editando un archivo llamado .netrc en el directorio home del usuario con el que estás trabajando en la terminal. La ruta ~/.netrc se refiere a un archivo llamado .netrc ubicado en el directorio personal del usuario actual. El símbolo ~ significa "home del usuario actual" en sistemas Unix/Linux.

Por ejemplo, si estás trabajando en AWS Cloud9, tu usuario por defecto suele ser ubuntu u otro nombre predefinido. Cuando abres la terminal en Cloud9, te encontrarás en /home/ubuntu/ (o similar). Allí, ~ es un atajo que representa /home/ubuntu. Por lo tanto, ~/.netrc se traduce a /home/ubuntu/.netrc.
Pasos para crear o editar el archivo .netrc en Cloud9 o en cualquier entorno similar:

1.	Confirma tu directorio actual:
```pwd``` Este comando debería mostrar algo como /home/ubuntu si estás en Cloud9. Si no es así, puedes ir a tu home con:
```cd ~```

2.	Crea o edita el archivo .netrc con tu editor de preferencia. Si no tienes preferencias, nano es una buena opción:
nano ~/.netrc
Esto abrirá el editor nano mostrándote un archivo vacío si es la primera vez que lo creas.

3.	Dentro de este archivo, añade las líneas indicadas en las instrucciones del repositorio, por ejemplo:

```bash
machine nexus.alfresco.com
login miusuario
password mimotdepasse
```
En el caso de ser autenticaicón con SSO, acceder a la consola de nexus manualmente https://nexus.alfresco.com/nexus/, luego a la cuenta y en la opción **USER TOKEN** y luego en **ACCESS USER TOKEN** y generar el usuario y el token:

|  |  |
|----------|----------|
| Usuario de Token de Nexus    | P_th42iS   
| Token passcode   | HFLbbJ9_EoRPStkyPpjQlh267nsYXtfYEtO-zF3aFodd  |
|     |    |  |



4.	Guarda el archivo:
Si usas nano, presiona Ctrl + O (letra O), luego Enter para confirmar.
Después Ctrl + X para salir.
5.	Asegura que el archivo .netrc no sea accesible por otros usuarios, cambiando sus permisos:
```bash
chmod 600 ~/.netrc
```

Esto permite que solo tu usuario pueda leer y escribir el archivo, manteniendo las credenciales seguras.

### 3.	Instalar AWS CLI (si no está ya instalada):

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws configure
```

### Troubleshooting: Configuración de Herramientas
- **Problema:** `kubectl` no está disponible después de instalarlo.
  - **Solución:** Asegúrate de que está en el PATH con:
    ```bash
    echo $PATH
    ```

## Configuración de Variables de Entorno

1. **Crea las Variables Necesarias**:
```bash
  export EKS_CLUSTER_NAME=alfresco-cluster
  export ECR_NAME=alfresco
  export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
  
  export S3_BUCKET_NAME=alfresco-content-bucket
  export REGION=us-east-1
  export AWS_REGION=us-east-1
  export NAMESPACE=alfresco1
  export EFSDNS=fs-0f4a4381a8b3f4daa.efs.us-east-1.amazonaws.com #esto es solo para purebas, esto es dinamico en terraform.
  export EFS_DNS_NAME=fs-0f4a4381a8b3f4daa.efs.us-east-1.amazonaws.com #esto es solo para purebas, esto es dinamico en 
  export EFS_ID=fs-0f4a4381a8b3f4daa
  terraform. 
  export N=alfresco1
  export K=kube-system
  export CERTIFICATE_ARN=arn:aws:acm:us-east-1:706722401192:certificate/a8babb15-e7fe-4e14-a692-a23dbee1cb47
  export QUAY_USERNAME=fc7430
  export QUAY_PASSWORD=Bunny2024!
  export DOMAIN=tfmfc.com
  export EFS_PV_NAME=alfresco
  export NODEGROUP_NAME=$(aws eks list-nodegroups --cluster-name $EKS_CLUSTER_NAME --output text)


  export EKS_CLUSTER_NAME=alfresco
  export ECR_NAME=alfresco
  export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
  export S3_BUCKET_NAME=alfresco-content-bucket
  export REGION=us-east-1
  export NAMESPACE=alfresco
  export N=alfresco
  export EFSDNS=fs-098a5b313abf42c10.efs.us-east-1.amazonaws.com
  export CERTIFICATE_ARN=arn:aws:acm:us-east-1:706722401192:certificate/a8babb15-e7fe-4e14-a692-a23dbee1cb47
  export QUAY_USERNAME=fc7430
  export QUAY_PASSWORD=Bunny2024!
  export DOMAIN=tfmfc.com
  export EFS_PV_NAME=

   AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
   EKS_CLUSTER_NAME="devopsalfresco"
   CLUSTER_ACCOUNT_INFO="${EKS_CLUSTER_NAME}-${AWS_ACCOUNT_ID}"
   echo "Cluster and Account Info: $CLUSTER_ACCOUNT_INFO"
```

2. **Verifica las Variables**:
   ```bash
   echo $EKS_CLUSTER_NAME
   echo $AWS_ACCOUNT_ID
   echo $S3_BUCKET_NAME
   echo $REGION
   ```

#### Troubleshooting: Variables de Entorno
- **Problema:** Variable no definida o devuelve un valor incorrecto.
  - **Solución:** Revisa si la variable está configurada correctamente:
    ```bash
    printenv | grep <variable_name>
    ```

# Bakery

## Crear un Repositorio ECR
¿Por qué este paso?
ECR (Elastic Container Registry) es donde almacenaremos nuestras imágenes Docker resultantes.


    ```bash
    aws ecr create-repository --repository-name $ECR_NAME
    ```

Anota el URI del repositorio que aparecerá en la respuesta:
(algo como <tu_account_id>.dkr.ecr.us-east-1.amazonaws.com/alfresco-initial).

```json     
{
    "repository": {
        "repositoryArn": "arn:aws:ecr:us-east-1:706722401192:repository/alfresco",
        "registryId": "706722401192",
        "repositoryName": "alfresco",
        "repositoryUri": "706722401192.dkr.ecr.us-east-1.amazonaws.com/alfresco",
        "createdAt": "2024-12-15T18:37:54.957000+00:00",
        "imageTagMutability": "MUTABLE",
        "imageScanningConfiguration": {
            "scanOnPush": false
        },
        "encryptionConfiguration": {
            "encryptionType": "AES256"
        }
    }
}
```

## Establecer Variables de Entorno Antes de Ejecutar make

El README del Alfresco Dockerfiles Bakery menciona que puedes usar las variables REGISTRY, REGISTRY_NAMESPACE y TAG antes de ejecutar make. Por ejemplo, si tu ECR está en us-east-1 y tu repositorio se llama alfresco-initial:

REGISTRY debe apuntar a tu registro ECR base, es decir, ```<tu_account_id>.dkr.ecr.us-east-1.amazonaws.com```
**REGISTRY_NAMESPACE** define la parte del nombre que va después de la barra, por ejemplo alfresco-initial.

TAG es opcional, por defecto es latest. Puedes ponerle un tag descriptivo, por ejemplo test.

De la respuesta mostrada, se ve claramente la línea:

```json
"repositoryUri": "706722401192.dkr.ecr.us-east-1.amazonaws.com/alfresco"
```
Esta dirección URI se compone de dos partes:

El registro base: ```706722401192.dkr.ecr.us-east-1.amazonaws.com```
El nombre del repositorio: ```alfresco```
Por lo tanto, el REGISTRY que necesitas exportar para que las imágenes se empujen a ECR es la parte antes del slash (/), es decir:

```sh
706722401192.dkr.ecr.us-east-1.amazonaws.com
```
Este valor lo asignarás a la variable de entorno REGISTRY. Por ejemplo:

```sh
export REGISTRY=706722401192.dkr.ecr.us-east-1.amazonaws.com
```

Además, la parte alfresco (el nombre del repositorio) la asignarás a **REGISTRY_NAMESPACE**, ya que el Makefile utiliza esta convención para componer las rutas de las imágenes:

```sh
export REGISTRY_NAMESPACE=alfresco
```

Con estas dos variables, junto con TAG (por ejemplo latest o el que quieras) y **TARGETARCH** (por ejemplo linux/amd64), podrás ejecutar el comando make para construir y empujar las imágenes directamente a tu ECR. Por ejemplo:

```bash

export REGISTRY=706722401192.dkr.ecr.us-east-1.amazonaws.com
export REGISTRY_NAMESPACE=alfresco
export TAG=latest
export TARGETARCH=linux/amd64
make community
```

De esta manera, las imágenes construidas serán etiquetadas y empujadas directamente a 706722401192.dkr.ecr.us-east-1.amazonaws.com/alfresco con el tag latest.

## Iniciar Sesión en ECR y EKS: (ver doc de word para la parte de los permisos)

Necesitamos subir las imágenes al ECR. Antes de eso, debemos iniciar sesión (login) con Docker.
1.	Ejecuta:

```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 706722401192.dkr.ecr.us-east-1.amazonaws.com
```


### 1.	Clona el repositorio de bakery:
¿Por qué este paso?
El repositorio proporciona los Dockerfiles y scripts necesarios para crear las imágenes de Alfresco.
```bash
git clone https://github.com/Alfresco/alfresco-dockerfiles-bakery.git
```

### Descarga de Artefactos
¿Por qué este paso?
El repositorio requiere artefactos (por ejemplo, war files, AMPs) para construir las imágenes. El script fetch-artifacts.sh los descargará por ti.

Ejecuta:

```bash
./scripts/fetch-artifacts.sh
```

Este script utiliza curl, wget y jq para descargar y colocar los artefactos en el directorio artifacts_cache/.

Verifica el resultado:

```bash
ls artifacts_cache/
```
Deberías ver archivos descargados.


## Usando Make:

siguiendo la documentación de bakery ## Getting started quickly

```sh
time make enterprise
```

or for Community edition:

```sh
make community
```

estos comandos construyen localmente 


# Creación del Clúster EKS

## Crear el Clúster con `eksctl`
Ejecuta el siguiente comando para crear un clúster básico de EKS:

```bash
eksctl create cluster --name $EKS_CLUSTER_NAME --region $REGION --version 1.31 --instance-types t3.xlarge --nodes 3
```

Para una versión anterior de EKS, puedes usar:

```bash
eksctl create cluster --name $EKS_CLUSTER_NAME --region $REGION --version 1.29 --instance-types t3.xlarge --nodes 3
```

Para eliminar el clúster, ejecuta:

```bash
eksctl delete cluster --name $EKS_CLUSTER_NAME
```

##  Crear el Clúster con Terraform
Inicializa Terraform:

```bash
terraform init
```

Planifica la infraestructura:

```bash
terraform plan
```

Aplica los cambios automáticamente:

```bash
terraform apply -auto-approve
```



## Registrar el Cluster
registrar el cluster>
```bash
aws eks update-kubeconfig --name $EKS_CLUSTER_NAME --region $REGION 
```

## Crear el Namespace

```bash
kubectl create namespace $NAMESPACE

if ! kubectl get namespace ${NAMESPACE}; then kubectl create namespace ${NAMESPACE}; fi

kubectl get namespace ${NAMESPACE} || \
kubectl create namespace ${NAMESPACE}
```

### Validar el Archivo `kubeconfig`
```bash
cat ~/.kube/config
```
Revisa que el archivo incluya correctamente el endpoint y el método de autenticación para tu clúster EKS. Debe contener una sección como esta:
```yaml
users:
- name: arn:aws:eks:us-east-1:<account-id>:cluster/<cluster-name>
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      command: aws
      args:
      - eks
      - get-token
      - --region
      - us-east-1
      - --cluster-name
      - <cluster-name>
```

### Verificar el Estado del Clúster
```bash
kubectl get nodes
```

Si los nodos no están listados, revisa los eventos del clúster:
```bash
kubectl describe nodes
kubectl get events -A
```

### Obtener info del Cluster 

#### Sacar la VPc Creada
Find The ID of VPC created when your cluster was built using the command below (replacing YOUR-CLUSTER-NAME with the name you gave your cluster):
```bash
aws eks describe-cluster \
--name $EKS_CLUSTER_NAME \
--query "cluster.resourcesVpcConfig.vpcId" \
--region $REGION \
--output text
```

#### Obtener el Endpoint del Clúster
```bash
aws eks describe-cluster --region us-east-1 --name $EKS_CLUSTER_NAME --query "cluster.endpoint" --output text
```
Esto devuelve el endpoint del clúster.


##### Verificar Conectividad con el Endpoint
```bash
curl -k <CLUSTER_ENDPOINT>
```
Reemplaza `<CLUSTER_ENDPOINT>` con el endpoint obtenido en el paso anterior. Si responde con un mensaje "403 Forbidden", significa que la conexión funciona, pero las credenciales no están configuradas correctamente.






# EBS: Configuración del Clúster EKS Addons EBS

### OIDC Provider
Siguiendo: https://github.com/Alfresco/acs-deployment/blob/master/docs/helm/eks-deployment.md
Luego: https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html -> https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html

Enable the OIDC provider that is necessary to install further EKS addons later:

```bash
eksctl utils associate-iam-oidc-provider --cluster=$EKS_CLUSTER_NAME --region $REGION  --approve
```

https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html
Determine the OIDC issuer ID for your cluster.
Retrieve your cluster’s OIDC issuer ID and store it in a variable. Replace my-cluster with your own value.
```bash
oidc_id=$(aws eks describe-cluster --name $EKS_CLUSTER_NAME --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)
echo $oidc_id

```

### Crear el Rol IAM

#### ***IMPORTANTE*** Borrar existentes iamserviceaccount y roles

```bash
        aws iam list-roles | grep AmazonEKS_EBS_CSI_DriverRole
        aws iam list-attached-role-policies --role-name AmazonEKS_EBS_CSI_DriverRole
        aws iam detach-role-policy --role-name AmazonEKS_EBS_CSI_DriverRole --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy
        aws iam delete-role --role-name AmazonEKS_EBS_CSI_DriverRole
        kubectl get serviceaccount -n kube-system
        kubectl delete serviceaccount ebs-csi-controller-sa -n kube-system
        kubectl delete serviceaccount ebs-csi-controller-sa -n $NAMESPACE
        eksctl delete iamserviceaccount \
        --name ebs-csi-controller-sa \
        --namespace kube-system \
        --cluster $EKS_CLUSTER_NAME
```
#### Crea un rol IAM para el controlador del EBS CSI Driver:

Acá estuvo el error tuve que eliminar la cuenta y volverla a crear:

```bash
eksctl create iamserviceaccount \
--name ebs-csi-controller-sa-$EKS_CLUSTER_NAME \
--namespace kube-system \
--cluster $EKS_CLUSTER_NAME \
--attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
--approve \
--role-only \
--role-name AmazonEKS_EBS_CSI_DriverRole_$EKS_CLUSTER_NAME


eksctl create iamserviceaccount \
--name ebs-csi-controller-sa \
--namespace kube-system \
--cluster $EKS_CLUSTER_NAME \
--attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
--approve \
--role-only \
--role-name AmazonEKS_EBS_CSI_DriverRole


eksctl create iamserviceaccount --name ebs-csi-controller-sa-$EKS_CLUSTER_NAME --namespace kube-system --cluster $EKS_CLUSTER_NAME --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy --approve --role-only --role-name AmazonEKS_EBS_CSI_DriverRole_$EKS_CLUSTER_NAME

Lo que use en la ultima prueba:

eksctl create iamserviceaccount \
--name ebs-csi-controller-sa \
--namespace kube-system \
--cluster $EKS_CLUSTER_NAME \
--attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
--approve \
--role-only \
--role-name AmazonEKS_EBS_CSI_DriverRole


#Eliminación Automatización:

#        aws iam list-roles | grep AmazonEKS_EBS_CSI_DriverRole_$EKS_CLUSTER_NAME
#        aws iam list-attached-role-policies --role-name AmazonEKS_EBS_CSI_DriverRole_$EKS_CLUSTER_NAME
#        aws iam detach-role-policy --role-name AmazonEKS_EBS_CSI_DriverRole_$EKS_CLUSTER_NAME --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy
#        aws iam delete-role --role-name AmazonEKS_EBS_CSI_DriverRole_$EKS_CLUSTER_NAME
#        kubectl delete serviceaccount ebs-csi-controller-sa-$EKS_CLUSTER_NAME -n kube-system
#        eksctl delete iamserviceaccount \
#        --name ebs-csi-controller-sa-$EKS_CLUSTER_NAME \
#        --namespace kube-system \
#        --cluster $EKS_CLUSTER_NAME
```

### Habilitar el Addon del EBS CSI Driver

#### ***IMPORTANTE*** Borrar existentes addon

```sh
eksctl get addon  --cluster $EKS_CLUSTER_NAME 
eksctl delete addon \
--name aws-ebs-csi-driver \
--cluster $EKS_CLUSTER_NAME \
--region $REGION

```

#### Crear el addon
``` bash
eksctl create addon \
--name aws-ebs-csi-driver \
--cluster $EKS_CLUSTER_NAME \
--region $REGION \
--service-account-role-arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/AmazonEKS_EBS_CSI_DriverRole_$EKS_CLUSTER_NAME \
--force

eksctl create addon \
--name aws-ebs-csi-driver \
--cluster $EKS_CLUSTER_NAME \
--region $REGION \
--service-account-role-arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/AmazonEKS_EBS_CSI_DriverRole \
--force


eksctl create addon --name aws-ebs-csi-driver --cluster $EKS_CLUSTER_NAME --region $AWS_REGION --service-account-role-arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/AmazonEKS_EBS_CSI_DriverRole_$EKS_CLUSTER_NAME --force
```



aws eks describe-cluster --name $EKS_CLUSTER_NAME --query "cluster.roleArn"


#### Troubleshooting: Verificación del EBS CSI Driver

##### **Listar Roles para validar su creación**:
    ``` bash
    aws iam list-roles | grep AmazonEKS_EBS_CSI_DriverRole
    ```
##### **Validar el addon creado**:
    ``` bash
    eksctl get addons --cluster $EKS_CLUSTER_NAME
    ```
##### **Revisar los pods del controlador**:
   ```bash
   kubectl get pods -n kube-system | grep ebs
   ```
   Deberías ver algo como:
   ``` php
   ebs-csi-controller-0     3/3     Running   0          <AGE>
   ebs-csi-node-xxxxxx      2/2     Running   0          <AGE>
   ```
#####  **Logs del pod**:
   ```bash
   kubectl logs -n kube-system <nombre-del-pod>
   ```
##### **Diagnostico de incidente de Rol**:
      
  ###### Paso 1: Verifica la Cuenta de Servicio Existente
      
  Verifica si la cuenta de servicio ebs-csi-controller-sa ya está creada en Kubernetes:
  ```bash
  kubectl get serviceaccount ebs-csi-controller-sa -n kube-system
  ```
  Si aparece, significa que ya existe pero no está asociada con el rol IAM que      deseas crear.

  ###### Paso 2: Eliminar la Cuenta de Servicio Existente (Opcional)
  Si no necesitas conservar la cuenta de servicio existente, elimínala
  ```bash
  kubectl delete serviceaccount ebs-csi-controller-sa -n kube-system
  ```
  
  ###### Paso 3: Verifica el Rol
  Después de ejecutar el comando, verifica que el rol haya sido creado
  ``` bash
  aws iam get-role --role-name AmazonEKS_EBS_CSI_DriverRole
  ```
  Si el rol fue creado correctamente, verás información como el ARN.



# EFS: File System, Pv, PVC y Claim

## 1. Reglas de seguridad
Se crea manualmente el EFS en la misma VPC del Cluster.

Aca es importante que en el VPC del cluster se ponga la regla de entrada del CDIR, con NFS como dice el tutorial, en teoria el EFS se monta en la misma vpc entonces aplica.
Ver Word 

Tutorial: se ejecutan estos comando para sacer las ids y los rangos de ip de la vpc del cluster:
```sh

#COMANDO UNIFICADO
aws ec2 describe-vpcs --vpc-ids $(aws eks describe-cluster --name $EKS_CLUSTER_NAME --query "cluster.resourcesVpcConfig.vpcId" --output text) --query "Vpcs[].CidrBlock" --output text

 
 # Ejecutar el primer comando y guardar el resultado en una variable de entorno
export VPC_ID=$(aws eks describe-cluster --name "$EKS_CLUSTER_NAME" \
    --query "cluster.resourcesVpcConfig.vpcId" \
    --region "$REGION" \
    --output text)

# Verificar que la variable se haya establecido correctamente
echo "VPC_ID: $VPC_ID"

# Usar la variable de entorno en el segundo comando
export CIDR_BLOCK=$(aws ec2 describe-vpcs --vpc-ids "$VPC_ID" \
    --query "Vpcs[].CidrBlock" \
    --output text)

# Verificar que la segunda variable se haya establecido correctamente
echo "CIDR_BLOCK: $CIDR_BLOCK"
```
Agregar el CIDR al grupo de seguridad


## 2. Nuevo AWS EFS csi storage driver
Primero borrar si ya existe:
```bash
helm uninstall aws-efs-csi-driver --namespace kube-system
```
```bash
# Crear archivo de configuración para el driver EFS CSI
cat > files/aws-efs-values.yml <<EOT
storageClasses:
  - mountOptions:
      - tls
    name: nfs-client
    parameters:
      directoryPerms: "700"
      uid: "33000"
      gid: "1000"
      fileSystemId: "${EFS_ID}"
      provisioningMode: "efs-ap"
    reclaimPolicy: Retain
    volumeBindingMode: Immediate
EOT

# Agregar el repositorio de Helm para el driver EFS CSI
helm repo add aws-efs-csi-driver https://kubernetes-sigs.github.io/aws-efs-csi-driver

# Instalar o actualizar el driver EFS CSI usando el archivo de configuración
envsubst < ~/environment/CICDAlfresco/files/aws-efs-values.yml | helm upgrade aws-efs-csi-driver aws-efs-csi-driver/aws-efs-csi-driver \
  --install \
  --namespace kube-system \
  -f -


envsubst < aws-efs-values.yml | helm upgrade aws-efs-csi-driver aws-efs-csi-driver/aws-efs-csi-driver --install --namespace kube-system -f -




    
```
### ERRORES:

#### ERROR del ID del File
El error ocurre porque en la configuración del EFS estás utilizando el DNS del sistema de archivos (fs-015bdcfa7ef338361.efs.us-east-1.amazonaws.com) en lugar del ID del sistema de archivos (fs-015bdcfa7ef338361). El controlador EFS CSI requiere específicamente el ID del sistema de archivos en el campo fileSystemId.

Proceso de diagnostico:
```sh
kubectl get pods -n $K
efs-csi-controller-b999f9d4c-48ts6    3/3     Running   0          2m2s
efs-csi-controller-b999f9d4c-bmdch    3/3     Running   0          2m2s

#se valida cada nodo y en uno se encuentra:
kubectl logs efs-csi-controller-b999f9d4c-bmdch -n $K 
1 validation error detected: Value 'fs-015bdcfa7ef338361.efs.us-east-1.amazonaws.com' at 'fileSystemId' failed to satisfy constraint: Member must satisfy regular expression pattern: ^(arn:aws[-a-z]*:elasticfilesystem:[0-9a-z-:]+:file-system/fs-[0-9a-f]{8,40}|fs-[0-9a-f]{8,40})$
```
#### Error de politica
igual que antes se busca en los logs del controlador y se encuentra:
```sh
E0126 02:28:02.272790       1 driver.go:109] GRPC error: rpc error: code = Unauthenticated desc = Access Denied. Please ensure you have the right AWS permissions: Access denied
```
El error Access Denied indica que el controlador EFS CSI no tiene los permisos necesarios en AWS para acceder y gestionar el sistema de archivos EFS. Esto generalmente ocurre debido a problemas con la IAM o la configuración del rol asociado.

Verificar el rol asociado al controlador: Identifica el rol IAM que utiliza el controlador EFS CSI. Puedes buscar el ServiceAccount asociado al controlador en el namespace kube-system:
```sh
kubectl get serviceaccount -n kube-system
```
Busca el ServiceAccount relacionado con el EFS CSI (puede tener un nombre similar a efs-csi-controller-sa).

Verificar los permisos del rol IAM: Encuentra el rol IAM asociado al ServiceAccount ejecutando:
```sh
aws eks list-nodegroups --cluster-name $EKS_CLUSTER_NAME --output text
ng-56ea77ce
aws eks describe-nodegroup --cluster-name $EKS_CLUSTER_NAME --nodegroup-name $NODEGROUP_NAME --query "nodegroup.nodeRole" --output text
aws eks describe-nodegroup --cluster-name $EKS_CLUSTER_NAME --nodegroup-name alfresco-node-group --query "nodegroup.nodeRole" --output text
arn:aws:iam::706722401192:role/eksctl-alfresco-cluster-nodegroup--NodeInstanceRole-aviSAZQhKVUE

arn:aws:iam::706722401192:role/eksctl-alfresco-nodegroup
```

Luego, revisa las políticas adjuntas al rol:
```sh
aws iam list-attached-role-policies --role-name <ROLENAME>
aws iam list-attached-role-policies --role-name eksctl-alfresco-nodegroup
```
Adjuntar la política requerida: Asegúrate de que el rol IAM tenga la política AmazonEFSCSIDriverPolicy adjunta. Si no está adjunta, ejecútala:
```sh
aws iam attach-role-policy --role-name <ROLENAME> --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy
aws iam attach-role-policy --role-name eksctl-alfresco-cluster-nodegroup--NodeInstanceRole-aviSAZQhKVUE --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy
```

NO FUE NECESARIO MODIFICAR EL SERVICE ACCOUNT SOLO CON LA POLITICA FUNCIONÓ EL EFS.
Actualizar el ServiceAccount: Asegúrate de que el ServiceAccount de Kubernetes esté asociado al rol correcto. Si no lo está, puedes recrearlo con el siguiente comando:
```sh
eksctl create iamserviceaccount \
--name efs-csi-controller-sa \
--namespace kube-system \
--cluster $EKS_CLUSTER_NAME \
--attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonElasticFileSystemClientPolicy \
--approve \
--role-only \
--role-name AmazonEKS_EFS_CSI_DriverRole
```


## 2. NFS Provisioner (obsoleto)
Deploy an NFS Client Provisioner with Helm using the following commands (replace EFS-DNS-NAME with the string FILE-SYSTEM-ID.efs.AWS-REGION.amazonaws.com where the FILE-SYSTEM-ID is the ID retrieved in step 1 and AWS-REGION is the region you’re using, e.g. fs-72f5e4f1.efs.us-east-1.amazonaws.com):

la version de https://kubernetes-charts.storage.googleapis.com, esta obsoleta, por lo que se reemplaza por https://charts.helm.sh.stable

```sh
helm repo add stable https://charts.helm.sh.stable

```

Validar:
```sh
helm list -n kube-system
```


ajustado con el id del EFS:
```sh
helm install alfresco-nfs-provisioner stable/nfs-client-provisioner --set nfs.server="$EFS_DNS_NAME" --set nfs.path="/" --set storageClass.name="nfs-client" --set storageClass.archiveOnDelete=false -n kube-system

helm uninstall alfresco-nfs-provisioner -n kube-system

```
Importante este controlador arroja el error:

kubectl get pods -n $K
alfresco-nfs-provisioner-nfs-client-provisioner-8475884887zssdh   1/1     Running   0          11m

kubectl logs alfresco-nfs-provisioner-nfs-client-provisioner-8475884887zssdh -n $K -f 
E0126 02:06:40.459050       1 controller.go:1004] provision "alfresco1/data-acs-postgresql-acs-0" class "nfs-client": unexpected error getting claim reference: selfLink was empty, can't make reference

El error unexpected error getting claim reference: selfLink was empty, can't make reference ocurre debido a un cambio en las versiones recientes de Kubernetes donde selfLink ya no está disponible por defecto. Esto afecta a algunos controladores o provisionadores que dependen de selfLink para operar correctamente. 

## 3. EFS montade con YAML


### **IMPORTANTE** Eliminación de recursos existentes mal configurados

Cuando se crea por primera vez el entorno y falla el no borra los pvc ni la configuración entonces de ahi en adelante siempre va a existir un error, es nececario eliminar manualmente los volumenes:

Este Retorna los pvs antes de su creación:
```sh
kubectl get pvc -n $N
NAME                                                  STATUS    VOLUME           CAPACITY   ACCESS MODES   STORAGECLASS      VOLUMEATTRIBUTESCLASS   AGE
alf-content-pvc                                       Bound     alf-content-pv   1Gi        RWX            alfresco-efs-sc   <unset>                 6h
data-acs-postgresql-acs-0                             Pending                                                                <unset>                 6h43m
elasticsearch-aas-master-elasticsearch-aas-master-0   Pending                                                                <unset>                 6h43m
elasticsearch-master-elasticsearch-master-0           Pending                                                                <unset>                 6h43m
```

Si existen se procede a borrarlos:
```sh
kubectl delete pvc data-acs-postgresql-acs-0 -n $N
kubectl delete pvc elasticsearch-aas-master-elasticsearch-aas-master-0 -n $N
kubectl delete pvc elasticsearch-master-elasticsearch-master-0 -n $N
kubectl get pvc -n $N
```

### Crear los nuevos volumenes para acs
Esto se hace por que se detecta que no monta bien los volumenes
Crear el PVC el PV, el claim y el storage class para el namespace: 
Se modifican los archivos 
```sh
envsubst < ~/environment/CICDAlfresco/files/alf-efs-storage-class.yaml | kubectl create -f -
envsubst < ~/environment/CICDAlfresco/files/alf-content-persistence-volume.yaml | kubectl apply -f -
envsubst < ~/environment/CICDAlfresco/files/alf-content-persistence-volume-claim.yaml | kubectl create -f -

kubectl delete -f files/alf-efs-storage-class.yaml
kubectl delete -f files/alf-content-persistence-volume.yaml
kubectl delete -f files/alf-content-persistence-volume-claim.yaml

kubectl delete -f files/alf-content-persistence-volume.yaml
```

**IMPORTANTE**
Se tiene que modificar los archivos:
```sh
apiVersion: v1
kind: PersistentVolume
metadata:
  name: alf-content-pv
  namespace: ${NAMESPACE}
spec:
  accessModes:
  - ReadWriteMany
  capacity:
    storage: 1Gi
  persistentVolumeReclaimPolicy: Retain
  storageClassName: alfresco-efs-sc
  nfs:
    server: ${EFSDNS}
    path: "/"
```


aws ec2 describe-vpcs \
--vpc-ids vpc-0e0561bf7757c4c31 \
--query "Vpcs[].CidrBlock" \
--output text

Luego se le agrega al comando del helm este comando paa que tome el claim que acabamos de crear esto ya no es necesario con el archivo que incluye variables de entorno, solo lo dejo como referencia:
```sh
--set alfresco-repository.persistence.existingClaim="alf-content-pvc" \ 
--set alfresco-repository.persistence.enabled=true \
```

### ERROREs

####  Warning  FailedScheduling  4m3s  default-scheduler  0/3 nodes are available: pod has unbound immediate PersistentVolumeClaims. preemption: 0/3 nodes are available: 3 Preemption is not helpful for scheduling.

Este error sucede por que los PVC no pueden montar las PV


# Prepare the cluster for Content Services DNS e Ingress
https://docs.alfresco.com/content-services/latest/install/containers/helm/#helm-deployment-with-aws-eks

Now we have an EKS cluster up and running, there are a few one time steps we need to perform to prepare the cluster for Content Services to be installed.

## External DNS

Crea una zona alojada en Route53 utilizando estos pasos si aún no tienes una disponible.

Crea un certificado público para la zona alojada (creada en el paso 1) en Certificate Manager utilizando estos pasos si aún no tienes uno disponible. Toma nota del ARN del certificado para usarlo más adelante.

Crea un archivo llamado external-dns.yaml con el texto a continuación (reemplaza YOUR-DOMAIN-NAME con el nombre de dominio que creaste en el paso 1). Este manifiesto define una cuenta de servicio y un rol de clúster para gestionar DNS:

Se ejecuta el comando:
```sh
#Manual
kubectl apply -f ~/environment/CICDAlfresco/files/external-dns.yaml -n kube-system
#Codebuild:
- kubectl apply -f $CODEBUILD_SRC_DIR/files/external-dns.yaml
```

### ***IMPORTANTE*** Route 53

Lista los grupos de nodos para tu clúster y toma nota del nombre del grupo de nodos YOUR-NODEGROUP (reemplaza YOUR-CLUSTER-NAME con el nombre que le diste a tu clúster).
```sh
aws eks list-nodegroups --cluster-name $EKS_CLUSTER_NAME
```
Encuentra el nombre del rol utilizado por los nodos ejecutando el siguiente comando (reemplaza YOUR-CLUSTER-NAME con el nombre que le diste a tu clúster y YOUR-NODEGROUP con el nombre de tu grupo de nodos):
```sh
aws eks describe-nodegroup --cluster-name $EKS_CLUSTER_NAME --nodegroup-name YOUR-NODEGROUP --query "nodegroup.nodeRole" --output text
{
    "nodegroups": [
        "ng-56ea77ce"
    ]
}
aws eks describe-nodegroup --cluster-name $EKS_CLUSTER_NAME --nodegroup-name ng-56ea77ce --query "nodegroup.nodeRole" --output text


```
En la consola de IAM, encuentra el rol descubierto en el paso anterior y adjunta la política administrada AmazonRoute53FullAccess como se muestra en la captura de pantalla a continuación:

AmazonRoute53FullAccess


### Troubleshooting

Error de Comando original: 
```sh
kubectl apply -f external-dns.yaml -n kube-system
#respuesta:
serviceaccount/external-dns unchanged
deployment.apps/external-dns unchanged
resource mapping not found for name: "external-dns" namespace: "" from "external-dns.yaml": no matches for kind "ClusterRole" in version "rbac.authorization.k8s.io/v1beta1"
ensure CRDs are installed first
resource mapping not found for name: "external-dns-viewer" namespace: "" from "external-dns.yaml": no matches for kind "ClusterRoleBinding" in version "rbac.authorization.k8s.io/v1beta1"
ensure CRDs are installed first
```
se corrige cambiando la versión dentro del archivo:

```yaml
 apiVersion: v1
 kind: ServiceAccount
 metadata:
   name: external-dns
 ---
 apiVersion: rbac.authorization.k8s.io/v1beta1
 kind: ClusterRole
 metadata:
   name: external-dns
 rules:
 - apiGroups: [""]
   resources: ["services","endpoints","pods"]
   verbs: ["get","watch","list"]
 - apiGroups: ["extensions"]
   resources: ["ingresses"]
   verbs: ["get","watch","list"]
 - apiGroups: [""]
   resources: ["nodes"]
   verbs: ["list","watch"]
 ---
 apiVersion: rbac.authorization.k8s.io/v1beta1
 kind: ClusterRoleBinding
 metadata:
   name: external-dns-viewer
 roleRef:
   apiGroup: rbac.authorization.k8s.io
   kind: ClusterRole
   name: external-dns
 subjects:
 - kind: ServiceAccount
   name: external-dns
   namespace: kube-system
 ---
 apiVersion: apps/v1
 kind: Deployment
 metadata:
   name: external-dns
 spec:
   strategy:
     type: Recreate
   selector:
     matchLabels:
       app: external-dns
   template:
     metadata:
       labels:
         app: external-dns
     spec:
       serviceAccountName: external-dns
       containers:
       - name: external-dns
         image: registry.opensource.zalan.do/teapot/external-dns:latest
         args:
         - --source=service
         - --domain-filter=YOUR-DOMAIN-NAME
         - --provider=aws
         - --policy=sync
         - --aws-zone-type=public
         - --registry=txt
         - --txt-owner-id=acs-deployment
         - --log-level=debug
```

## Ingress

Primero se tiene que crear el dominio y el route 53 ver documento word

### OPCION 1 - Crear un Ingress Generico (incompleto)
https://github.com/Alfresco/acs-deployment/blob/master/docs/helm/ingress-nginx.md

```bash
helm upgrade --install ingress-nginx ingress-nginx \
--repo https://kubernetes.github.io/ingress-nginx \
--namespace ingress-nginx --create-namespace \
--version 4.7.2 \
--set controller.allowSnippetAnnotations=true

kubectl wait --namespace ingress-nginx \
--for=condition=ready pod \
--selector=app.kubernetes.io/component=controller \
--timeout=90s

kubectl get pods --namespace=ingress-nginx
```

### Opcion 2 - Crear un Ingress Personalizado

#### Paso 1: Crear el Cluster Rol para el ingress en el namespace

```sh
# Manual
 envsubst < ~/environment/CICDAlfresco/files/ingress-rbac.yaml | kubectl apply -f - -n ${NAMESPACE}
# CodeBuild
- envsubst < $CODEBUILD_SRC_DIR/files/ingress-rbac.yaml | kubectl apply -f - -n ${NAMESPACE}
```

esto importante para que pueda registrar el nuevo acs-ingress: 

```sh
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
```

#### Paso 2: crear el Ingress:

```sh
 helm install acs-ingress-$EKS_CLUSTER_NAME ingress-nginx/ingress-nginx \
  --set controller.scope.enabled=true \
  --set controller.scope.namespace=$NAMESPACE \
  --set rbac.create=true \
  --set controller.config."proxy-body-size"="100m" \
  --set controller.service.targetPorts.https=80 \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-backend-protocol"="http" \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-ssl-ports"="https" \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-ssl-cert"="${CERTIFICATE_ARN}" \
  --set controller.service.annotations."external-dns\.alpha\.kubernetes\.io/hostname"="acs.${DOMAIN_NAME}" \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-ssl-negotiation-policy"="ELBSecurityPolicy-TLS-1-2-2017-01" \
  --set controller.publishService.enabled=true \
  --set controller.ingressClassResource.name="$NAMESPACE-nginx" \
  --set controller.ingressClassByName=true \
  --atomic --namespace $NAMESPACE

 helm install acs-ingress ingress-nginx/ingress-nginx \
  --set controller.scope.enabled=true \
  --set controller.scope.namespace=$NAMESPACE \
  --set rbac.create=true \
  --set controller.config."proxy-body-size"="100m" \
  --set controller.service.targetPorts.https=80 \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-backend-protocol"="http" \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-ssl-ports"="https" \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-ssl-cert"="${CERTIFICATE_ARN}" \
  --set controller.service.annotations."external-dns\.alpha\.kubernetes\.io/hostname"="acs.${DOMAIN_NAME}" \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-ssl-negotiation-policy"="ELBSecurityPolicy-TLS-1-2-2017-01" \
  --set controller.publishService.enabled=true \
  --set controller.ingressClassResource.name="$NAMESPACE-nginx" \
  --set controller.ingressClassByName=true \
  --atomic --namespace $NAMESPACE

helm delete acs-ingress -n $NAMESPACE
 ```
Este se demora en generar la IP del balanceador:
kubectl get service --namespace alfresco acs-ingress-ingress-nginx-controller --output wide --watch

#### ERRORES CORREGIDOS:
- Error de versión: se corrige usando la versión más actualizada del ingres en helm
- Error de despliegue con multriples clusters: El error ocurre porque el IngressClass ya existe en el clúster y está asociado a otra instalación de Helm (acs-ingress-m en el namespace alfrescom). Esto sucede porque el IngressClass es un recurso global, no específico de un namespace, y Helm intenta tomar el control de ese recurso, pero detecta que ya pertenece a otra release.


# Creación del Bucket S3 (opcional)

### Paso 1: Crear el Bucket en AWS S3
1. **Accede a la Consola de S3**:
   - Desde la consola de AWS, ve a "S3" y selecciona "Crear bucket".
   
2. **Configura los Detalles del Bucket**:
   - **Nombre del bucket**: `alfresco-content-bucket`.
   - **Región**: Asegúrate de seleccionar `us-east-1` (o la misma región que tu clúster EKS).
   - Desactiva el bloqueo público si estás en un entorno privado.

3. **Crear el Bucket**:
   - Completa los pasos restantes y selecciona "Crear bucket".

### Paso 2: Configurar Políticas de Acceso para el Bucket
1. **Crear una Política de IAM**:
   - Abre la consola de IAM y crea una política que permita a tu clúster EKS acceder al bucket. Ejemplo:
     ```json
     {
       "Version": "2012-10-17",
       "Statement": [
         {
           "Effect": "Allow",
           "Action": [
             "s3:GetObject",
             "s3:PutObject",
             "s3:ListBucket"
           ],
           "Resource": [
             "arn:aws:s3:::alfresco-content-bucket",
             "arn:aws:s3:::alfresco-content-bucket/*"
           ]
         }
       ]
     }
     ```

2. **Asocia la Política al Rol del Clúster**:
   - Encuentra el rol IAM asociado a tu clúster con:
     ```bash
     aws eks describe-cluster --name $EKS_CLUSTER_NAME  --query "cluster.roleArn"
     ```
Resultado:
  ```bash
  "arn:aws:iam::706722401192:role/eksctl-alfresco-cluster-ServiceRole-ouC79XvxQRLs"
  ```

   - Asocia la política de S3 a este rol desde la consola de IAM o con el CLI.

### Troubleshooting: Acceso al Bucket S3
- **Problema:** Error `Access Denied` al intentar acceder al bucket.
  - **Solución:** Asegúrate de que el rol IAM del clúster tenga los permisos correctos.

---






# Instalación de Alfresco Content Services

## Crear Namespace para Alfresco
```bash
kubectl create namespace $HELM_NAMESPACE
```

## Configuración del Repositorio de Helm

Esto solo se hace para el caso de uso del repo publico, en mi caso se descarga el repositorio y se agrega al proyecto

```bash
helm repo add alfresco https://kubernetes-charts.alfresco.com/stable
helm repo update
```

## Login en Quay
```sh
kubectl create secret docker-registry quay-registry-secret --docker-server=quay.io --docker-username=fc7430 --docker-password=Marzo! -n $NAMESPACE
# para verificar 
kubectl get secrets -n alfresco

#Para probar la conexión ya que sale error de coneión, toca cambiar el password cada cierto tiempo por que sale error de too many request
docker login quay.io
username: fc7430
password: Marzo!

#para borrar y corregir
kubectl get secret -n alfresco
kubectl delete secret <nombre>

docker login quay.io
username: fc7430
password: Bunny2024!

#nuevamente se prueba: 
kubectl create secret docker-registry quay-registry-secret --docker-server=quay.io --docker-username=fc7430 --docker-password=Bunny2024! -n alfresco

kubectl create secret docker-registry quay-registry-secret --docker-server=quay.io --docker-username=$QUAY_USERNAME --docker-password=$QUAY_PASSWORD -n ${NAMESPACE}
```


## instalación de ACS - HELM

Comando actualizado para usar el helm local
```sh
helm uninstall acs -n $N

kubectl delete pvc data-acs-postgresql-acs-0  -n $N
kubectl delete pvc elasticsearch-aas-master-elasticsearch-aas-master-0 -n $N
kubectl delete pvc elasticsearch-master-elasticsearch-master-0 -n $N
kubectl delete pvc filestore-default-pvc -n $N
kubectl delete pvc activemq-default-pvc -n $N

kubectl delete pvc alf-content-pvc -n $N

helm install acs ~/environment/CICDAlfresco/alfresco-content-services \
--set externalPort="443" \
--set externalProtocol="https" \
--set externalHost="acs.${DOMAIN}" \
--set persistence.enabled=true \
--set persistence.storageClass.enabled=true \
--set persistence.storageClass.name="nfs-client" \
--set alfresco-repository.persistence.existingClaim="alf-content-pvc" \
--set postgresql.primary.persistence.existingClaim="alf-content-pvc" \
--set activemq.persistence.existingClaim="alf-content-pvc" \
--set alfresco-transform-service.filestore.persistence.existingClaim="alf-content-pvc" \
--set postgresql.volumePermissions.enabled=true \
--set alfresco-repository.persistence.enabled=true \
--set global.alfrescoRegistryPullSecrets=quay-registry-secret \
--set alfresco-sync-service.enabled=false \
--set postgresql-sync.enabled=false \
--set alfresco-transform-service.transformrouter.replicaCount="1" \
--set alfresco-transform-service.pdfrenderer.replicaCount="1" \
--set alfresco-transform-service.imagemagick.replicaCount="1" \
--set alfresco-transform-service.libreoffice.replicaCount="1" \
--set alfresco-transform-service.tika.replicaCount="1" \
--set alfresco-transform-service.transformmisc.replicaCount="1" \
--set alfresco-transform-service.transformrouter.resources.limits.memory="2Gi" \
--set alfresco-transform-service.pdfrenderer.resources.limits.memory="2Gi" \
--set alfresco-transform-service.imagemagick.resources.limits.memory="2Gi" \
--set alfresco-transform-service.libreoffice.resources.limits.memory="2Gi" \
--set alfresco-transform-service.tika.resources.limits.memory="2Gi" \
--set alfresco-transform-service.transformmisc.resources.limits.memory="2Gi" \
--set alfresco-transform-service.transformrouter.resources.limits.cpu="250m" \
--set alfresco-transform-service.pdfrenderer.resources.limits.cpu="250m" \
--set alfresco-transform-service.imagemagick.resources.limits.cpu="250m" \
--set alfresco-transform-service.libreoffice.resources.limits.cpu="250m" \
--set alfresco-transform-service.tika.resources.limits.cpu="250m" \
--set alfresco-transform-service.transformmisc.resources.limits.cpu="250m" \
--set alfresco-transform-service.filestore.resources.limits.cpu="250m" \
--set postgresql.primary.resources.requests.cpu="250m" \
--set postgresql.primary.resources.limits.cpu="500m" \
--set postgresql.primary.resources.limits.memory="6Gi" \
--set alfresco-share.resources.limits.cpu="250m" \
--set alfresco-search-enterprise.resources.requests.cpu="250m" \
--set alfresco-search-enterprise.resources.limits.cpu="250m" \
--set alfresco-repository.resources.requests.cpu="500m" \
--set alfresco-repository.resources.limits.cpu="500m" \
--set alfresco-repository.readinessProbe.periodSeconds="200" \
--set alfresco-repository.livenessProbe.periodSeconds="200" \
--set alfresco-repository.startupProbe.periodSeconds="200" \
--set alfresco-transform-service.pdfrenderer.livenessProbe.periodSeconds="200" \
--set alfresco-transform-service.pdfrenderer.readinessProbe.periodSeconds="200" \
--set alfresco-transform-service.imagemagick.livenessProbe.periodSeconds="200" \
--set alfresco-transform-service.imagemagick.readinessProbe.periodSeconds="200" \
--set alfresco-transform-service.tika.livenessProbe.periodSeconds="200" \
--set alfresco-transform-service.tika.readinessProbe.periodSeconds="200" \
--set alfresco-transform-service.libreoffice.livenessProbe.periodSeconds="200" \
--set alfresco-transform-service.libreoffice.readinessProbe.periodSeconds="200" \
--set alfresco-transform-service.transformmisc.livenessProbe.periodSeconds="200" \
--set alfresco-transform-service.transformmisc.readinessProbe.periodSeconds="200" \
--set alfresco-share.livenessProbe.periodSeconds="200" \
--set alfresco-share.readinessProbe.periodSeconds="200" \
--set alfresco-search-enterprise.reindexing.enabled=false \
--timeout 20m0s \
--namespace=$NAMESPACE

helm install acs ~/environment/CICDAlfresco/alfresco-content-services \
--set externalPort="443" \
--set externalProtocol="https" \
--set externalHost="acs.${DOMAIN}" \
--set persistence.enabled=false \
--set persistence.storageClass.enabled=false \
--set alfresco-repository.persistence.enabled=false \
--set global.alfrescoRegistryPullSecrets=quay-registry-secret \
--set alfresco-sync-service.enabled=false \
--set postgresql-sync.enabled=false \
--set alfresco-transform-service.transformrouter.replicaCount="1" \
--set alfresco-transform-service.pdfrenderer.replicaCount="1" \
--set alfresco-transform-service.imagemagick.replicaCount="1" \
--set alfresco-transform-service.libreoffice.replicaCount="1" \
--set alfresco-transform-service.tika.replicaCount="1" \
--set alfresco-transform-service.transformmisc.replicaCount="1" \
--set alfresco-transform-service.transformrouter.resources.limits.memory="2Gi" \
--set alfresco-transform-service.pdfrenderer.resources.limits.memory="2Gi" \
--set alfresco-transform-service.imagemagick.resources.limits.memory="2Gi" \
--set alfresco-transform-service.libreoffice.resources.limits.memory="2Gi" \
--set alfresco-transform-service.tika.resources.limits.memory="2Gi" \
--set alfresco-transform-service.transformmisc.resources.limits.memory="2Gi" \
--set alfresco-transform-service.transformrouter.resources.limits.cpu="250m" \
--set alfresco-transform-service.pdfrenderer.resources.limits.cpu="250m" \
--set alfresco-transform-service.imagemagick.resources.limits.cpu="250m" \
--set alfresco-transform-service.libreoffice.resources.limits.cpu="250m" \
--set alfresco-transform-service.tika.resources.limits.cpu="250m" \
--set alfresco-transform-service.transformmisc.resources.limits.cpu="250m" \
--set alfresco-transform-service.filestore.resources.limits.cpu="250m" \
--set postgresql.primary.resources.requests.cpu="250m" \
--set postgresql.primary.resources.limits.cpu="500m" \
--set postgresql.primary.resources.limits.memory="6Gi" \
--set alfresco-share.resources.limits.cpu="250m" \
--set alfresco-search-enterprise.resources.requests.cpu="250m" \
--set alfresco-search-enterprise.resources.limits.cpu="250m" \
--set alfresco-repository.resources.requests.cpu="500m" \
--set alfresco-repository.resources.limits.cpu="500m" \
--set alfresco-repository.readinessProbe.periodSeconds="200" \
--set alfresco-repository.livenessProbe.periodSeconds="200" \
--set alfresco-repository.startupProbe.periodSeconds="200" \
--set alfresco-transform-service.pdfrenderer.livenessProbe.periodSeconds="200" \
--set alfresco-transform-service.pdfrenderer.readinessProbe.periodSeconds="200" \
--set alfresco-transform-service.imagemagick.livenessProbe.periodSeconds="200" \
--set alfresco-transform-service.imagemagick.readinessProbe.periodSeconds="200" \
--set alfresco-transform-service.tika.livenessProbe.periodSeconds="200" \
--set alfresco-transform-service.tika.readinessProbe.periodSeconds="200" \
--set alfresco-transform-service.libreoffice.livenessProbe.periodSeconds="200" \
--set alfresco-transform-service.libreoffice.readinessProbe.periodSeconds="200" \
--set alfresco-transform-service.transformmisc.livenessProbe.periodSeconds="200" \
--set alfresco-transform-service.transformmisc.readinessProbe.periodSeconds="200" \
--set alfresco-share.livenessProbe.periodSeconds="200" \
--set alfresco-share.readinessProbe.periodSeconds="200" \
--set alfresco-search-enterprise.reindexing.enabled=false \
--timeout 20m0s \
--namespace=$NAMESPACE
```

## instalación de ACS - HELM con S3
S3:

aws s3api put-bucket-versioning --bucket alfresco-content-bucket --versioning-configuration Status=Enabled
 aws eks describe-nodegroup --cluster-name alfresco --nodegroup-name linux-nodes --query "nodegroup.nodeRole" --output text


otro comando de : https://docs.alfresco.com/content-services/latest/install/containers/helm-examples/
```sh
helm install acs alfresco/alfresco-content-services \
--set externalPort="443" \
--set externalProtocol="https" \
--set externalHost="acs.YOUR-DOMAIN-NAME" \
--set persistence.enabled=true \
--set persistence.storageClass.enabled=true \
--set persistence.storageClass.name="nfs-client" \
--set global.alfrescoRegistryPullSecrets=quay-registry-secret \
--set repository.image.repository="quay.io/alfresco/alfresco-content-repository-aws" \
--set s3connector.enabled=true \
--set s3connector.config.bucketName="YOUR-BUCKET-NAME" \
--set s3connector.config.bucketLocation="YOUR-AWS-REGION" \
--set postgresql.enabled=false \
--set database.external=true \
--set database.driver="org.postgresql.Driver" \
--set database.url="jdbc:postgresql://YOUR-DATABASE-ENDPOINT:5432/" \
--set database.user="alfresco" \
--set database.password="YOUR-DATABASE-PASSWORD" \
--set activemq.enabled=false \
--set messageBroker.url="YOUR-MQ-ENDPOINT" \
--set messageBroker.user="alfresco" \
--set messageBroker.password="YOUR-MQ-PASSWORD" \
--atomic \
--timeout 10m0s \
--namespace=alfresco




```sh
helm install acs ./alfresco-content-services \
--set externalPort="443" \
--set externalProtocol="https" \
--set externalHost="acs.tfmfc.com" \
--set persistence.enabled=true \
--set persistence.storageClass.enabled=true \
--set persistence.storageClass.name="nfs-client" \
--set global.alfrescoRegistryPullSecrets=quay-registry-secret \
--set repository.image.repository="quay.io/alfresco/alfresco-content-repository-aws" \
--set s3connector.enabled=true \
--set s3connector.config.bucketName="alfresco-content-bucket " \
--set s3connector.config.bucketLocation="us-east-1" \
--set alfresco-sync-service.enabled=false \
--set postgresql-sync.enabled=false \
--set alfresco-transform-service.transformrouter.replicaCount="1" \
--set alfresco-transform-service.pdfrenderer.replicaCount="1" \
--set alfresco-transform-service.imagemagick.replicaCount="1" \
--set alfresco-transform-service.libreoffice.replicaCount="1" \
--set alfresco-transform-service.tika.replicaCount="1" \
--set alfresco-transform-service.transformmisc.replicaCount="1" \
--set alfresco-transform-service.transformrouter.resources.limits.memory="1Gi" \
--set alfresco-transform-service.pdfrenderer.resources.limits.memory="1Gi" \
--set alfresco-transform-service.imagemagick.resources.limits.memory="1Gi" \
--set alfresco-transform-service.libreoffice.resources.limits.memory="1Gi" \
--set alfresco-transform-service.tika.resources.limits.memory="1Gi" \
--set alfresco-transform-service.transformmisc.resources.limits.memory="1Gi" \
--set alfresco-transform-service.transformrouter.resources.limits.cpu="250m" \
--set alfresco-transform-service.pdfrenderer.resources.limits.cpu="250m" \
--set alfresco-transform-service.imagemagick.resources.limits.cpu="250m" \
--set alfresco-transform-service.libreoffice.resources.limits.cpu="250m" \
--set alfresco-transform-service.tika.resources.limits.cpu="250m" \
--set alfresco-transform-service.transformmisc.resources.limits.cpu="250m" \
--set alfresco-transform-service.filestore.resources.limits.cpu="250m" \
--set postgresql.primary.resources.requests.cpu="250m" \
--set postgresql.primary.resources.limits.cpu="500m" \
--set postgresql.primary.resources.limits.memory="6Gi" \
--set alfresco-share.resources.limits.cpu="250m" \
--set alfresco-search-enterprise.resources.requests.cpu="250m" \
--set alfresco-search-enterprise.resources.limits.cpu="250m" \
--set alfresco-repository.resources.requests.cpu="250m" \
--set alfresco-repository.resources.limits.cpu="500m" \
--atomic \
--timeout 10m0s \
--namespace=alfresco
```

## IMPORTANTE comandos de diagnostico adicionales

Comandos de diagnóstico:
```sh
# Validar despliegues en el namespace alfresco
kubectl get deployments -n alfresco

# Validar el espacio y rendimiento de los nodos
kubectl get nodes
kubectl describe node <nombre>

# Validar la configuración de la conexión del repository con la base de datos (por error wait-db-ready)
# Listar ConfigMaps
kubectl get configmaps -n alfresco
kubectl describe configmap repository -n alfresco

# Editar y verificar un despliegue
kubectl get deployments -n alfresco
kubectl edit deployments acs-alfresco-repository -n alfresco

# Descargar y descomprimir el helm para corregir
tar -xzvf alfresco-content-services-8.6.1.tgz

# Ejecutar el contenedor y evaluar el error
kubectl get svc -n alfresco
kubectl get pods -n alfresco 
kubectl logs acs-postgresql-acs-0 -n alfresco
kubectl describe pod acs-alfresco-repository-f9f5b9fc5-66jw6 -n alfresco
kubectl get events -n alfresco | grep repository

# Validar evento de error relacionado con EBS
kubectl get pv
```

## Conectarse a un pod

Para conectarse a un pod específico y ejecutar comandos dentro de él, siga estos pasos:

1. **Ejecutar el comando `kubectl exec`**:
```bash
kubectl exec -it acs-alfresco-repository-db4947df-drjjm -n $NAMESPACE -- /bin/bash

kubectl exec -it acs-postgresql-acs-0 -n $NAMESPACE -- /bin/bash

```
Este comando abre una sesión interactiva de bash en el pod `acs-alfresco-repository-8c7688574-tfbvj` en el namespace `alfresco`.

```bash
# Listar el contenido del directorio actual
ls -l

# Cambiar al directorio `alf_data`
cd alf_data

# Listar el contenido del directorio `alf_data`
ls -l

# Cambiar al directorio `contentstore`
cd contentstore

# Listar el contenido del directorio `contentstore`
ls -l

# Verificar el uso del disco
df -h

# Salir de la sesión del pod
exit
```

# instalación de Alfresco Process Services

```sh
helm install aps ./alfresco-process-services \
--set alfresco-activiti.persistence.existingClaim="default/efs-pvc" \
--set elasticsearch.enabled=false \
--set alfresco-activiti.persistence.enabled=true \
--set alfresco-activiti.persistence.storageClass.enabled=true \
--set alfresco-activiti.persistence.storageClass.name="nfs-client" \
--set postgresql.global.storageClass="nfs-client" \
--atomic \
--timeout 10m0s \
--namespace=$NAMESPACE


--set externalPort="443" \
--set externalProtocol="https" \
--set externalHost="acs.YOUR-DOMAIN-NAME" \
--set persistence.enabled=true \
--set persistence.storageClass.enabled=true \
--set persistence.storageClass.name="nfs-client" \
--set global.alfrescoRegistryPullSecrets=quay-registry-secret \
--set repository.image.repository="quay.io/alfresco/alfresco-content-repository-aws" \
--set s3connector.enabled=true \
--set s3connector.config.bucketName="YOUR-BUCKET-NAME" \
--set s3connector.config.bucketLocation="YOUR-AWS-REGION" \
--set postgresql.enabled=false \
--set database.external=true \
--set database.driver="org.postgresql.Driver" \
--set database.url="jdbc:postgresql://YOUR-DATABASE-ENDPOINT:5432/" \
--set database.user="alfresco" \
--set database.password="YOUR-DATABASE-PASSWORD" \
--set activemq.enabled=false \
--set messageBroker.url="YOUR-MQ-ENDPOINT" \
--set messageBroker.user="alfresco" \
--set messageBroker.password="YOUR-MQ-PASSWORD" \
--atomic \
--timeout 10m0s \
--namespace=alfresco
```

## Instalación de Alfresco Content Services

### Paso 1: Configuración del Repositorio de Helm
```bash
helm repo add alfresco https://kubernetes-charts.alfresco.com/stable
helm repo update
```

### Paso 2: Crear Namespace para Alfresco
```bash
kubectl create namespace $HELM_NAMESPACE
```

### Paso 3: Crear Archivo de Configuración
Crea un archivo `alfresco-values.yaml` con la configuración necesaria:

```yaml
persistence:
  storageClass: gp2
alfresco-infrastructure:
  repository:
    adminPassword: "admin"
    s3:
      enabled: true
      bucketName: "alfresco-content-bucket"
      bucketRegion: "us-east-1"
  database:
    type: "embedded"
    persistence:
      storageClass: gp2
activemq:
  enabled: true
externalAccess:
  enabled: true
  protocol: http
```

### Paso 4: Desplegar Alfresco
```bash
helm install alfresco alfresco/alfresco-content-services --namespace $HELM_NAMESPACE -f alfresco-values.yaml
```

### Paso 5: Verificar el Despliegue
```bash
kubectl get pods -n alfresco
kubectl get svc -n alfresco
```





---

## Configuración de DNS con Ingress-NGINX

antes de todo valida que no exista ningun ingress previamente instalado:

```bash
kubectl get all -A | grep ingress-nginx

#agregar el repositorio y actualizar
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm upgrade -i ingress-nginx ingress-nginx/ingress-nginx \
    --version 4.2.3 \
    --namespace kube-system \
    --set controller.service.type=ClusterIP
```

### Paso 1: Instalar Ingress-NGINX
```bash
helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace
```

### Paso 2: Configurar el DNS
1. Obtén la IP pública del servicio de Ingress:
```bash
kubectl get svc ingress-nginx-controller -n ingress-nginx
```
2. Configura un registro A en tu proveedor de DNS apuntando a esta IP.

### Paso 3: Crear Ingress para Alfresco
Crea un archivo `alfresco-ingress.yaml`:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: alfresco-ingress
  namespace alfresco
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: alfresco.mydomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: alfresco-share
            port:
              number: 80
```

Aplica el archivo:
```bash
kubectl apply -f alfresco-ingress.yaml
```

---

## Troubleshooting General

### Problemas con el Clúster
```bash
kubectl get nodes
kubectl get pods -A
kubectl get svc -A
kubectl get events -A
```

### Problemas con DNS
```bash
nslookup alfresco.mydomain.com
```

### Limpieza y Reinstalación
```bash
helm uninstall acs --namespace $NAMESPACE
kubectl delete pvc --all -n alfresco
kubectl delete configmap --all -n alfresco
kubectl delete secret --all -n alfresco
```

---

--- 

# Guía para Detener Servicios y Minimizar Costos en AWS EKS

Este documento describe cómo detener temporalmente los servicios de un clúster EKS para evitar costos adicionales mientras no estás trabajando activamente.

## 1. Desinstalar Alfresco con Helm
Ejecuta el siguiente comando para desinstalar Alfresco:

```bash
helm uninstall acs --namespace $NAMESPACE
```

## 2. Desinstalar el Ingress

ojo con el nombre del ingress:
```bash
 helm uninstall acs-ingress-$EKS_CLUSTER_NAME -n $NAMESPACE
```


## Eliminación del ingress-nginx (Opcional - general) 

Esta eliminación solo en caso de requerir validaciones adicionales

1. **Identificar el Release de NGINX**
  Verifica el nombre del release que usaste para instalar NGINX Ingress:

```bash
  helm list -n ingress-nginx
```

  Esto debería mostrar una lista de releases, incluyendo el que corresponde a NGINX.

2. **Desinstalar NGINX**
  Usa el siguiente comando para desinstalar NGINX:

```bash
  helm uninstall <release-name> -n ingress-nginx
```

  Por ejemplo, si el release se llama `ingress-nginx`, ejecuta:

```bash
  helm uninstall ingress-nginx -n ingress-nginx
```

3. **Verificar la Eliminación**
  Después de desinstalar NGINX, verifica que los recursos hayan sido eliminados:

  Revisar Servicios, Pods y Otros Recursos:

```bash
  kubectl get all -n ingress-nginx
```

  Si quedan recursos como servicios o pods, elimínalos manualmente:

```bash
  kubectl delete pod,svc --all -n ingress-nginx
```

  Eliminar el Namespace (Opcional): Si ya no necesitas el namespace `ingress-nginx`, elimínalo:

```bash
  kubectl delete namespace ingress-nginx
```

4. **Verificar Servicios de Tipo LoadBalancer**
  Si NGINX creó un servicio de tipo LoadBalancer, puede que siga activo y generando costos.

  Lista todos los servicios:

```bash
  kubectl get svc -A
```

  Elimina el servicio de LoadBalancer asociado a NGINX (si aún existe):

```bash
  kubectl delete svc <SERVICE_NAME> -n ingress-nginx
```

5. **Confirmar Limpieza**
  Verifica que no haya recursos residuales:

  Revisar Recursos de Kubernetes:

```bash
  kubectl get all -A
  kubectl get pvc -A
```


## 3 destruir el EFS 

Esto se puede hacer manual o validación por codigo.
Tras eliminar el EFS, validar y reliminar los recursos persistentes.

### 3. Eliminar Recursos Persistentes
Eliminar PVCs (Persistent Volume Claims):

```bash
kubectl delete pvc --all -n $NAMESPACE
```
Eliminar ConfigMaps y Secrets:

```bash
kubectl delete configmap --all -n $NAMESPACE
kubectl delete secret --all -n $NAMESPACE
```
Eliminar el Namespace (Opcional): Si no necesitas mantener el namespace alfresco, elimínalo:

```bash
kubectl delete namespace alfresco
```

## 5. Deshabilitar Addons del Clúster
Los addons de EKS, como el EBS CSI Driver, también pueden generar costos.

1. Verifica los addons instalados:
```bash
  eksctl get addon --cluster $EKS_CLUSTER_NAME
```

2. Elimina los addons que no sean necesarios temporalmente:
```bash
  eksctl delete addon --name aws-ebs-csi-driver --cluster $EKS_CLUSTER_NAME
```

## Identificar y Eliminar Servicios
1. Lista todos los servicios de Kubernetes:
   ```bash
   kubectl get svc -A
   ```

2. Busca los servicios de tipo `LoadBalancer` y elimínalos:
   ```bash
   kubectl delete svc <SERVICE_NAME> -n <NAMESPACE>

   kubectl delete svc --all
   ```

**Nota:** Asegúrate de tener un respaldo de las configuraciones antes de eliminarlos.

---

## Eliminación de componentes manual

Revisar en AWS: Desde la consola de AWS, confirma que no haya:

- Instancias EC2 activas.
- LoadBalancers asociados.
- Volúmenes EBS no eliminados.

No olvidar de eliminar la VPC, los NAT Gateways y las Elastic IP ya que generan costos también.

### 1. Eliminar los NAT Gateways

1. Ve a la consola de Amazon VPC.
2. En el menú lateral, selecciona **NAT Gateways**.
3. Busca los NAT Gateways asociados al clúster (puedes identificarlos por el nombre que incluye `eksctl-<nombre-cluster>`).
4. Selecciona el NAT Gateway y haz clic en **Actions > Delete NAT Gateway**.
5. Confirma la eliminación y espera a que el estado cambie a `Deleted`.

### 2. Liberar las Elastic IPs

1. En la consola de EC2, selecciona **Elastic IPs** en el menú lateral.
2. Busca las Elastic IPs asociadas al clúster (usualmente tienen etiquetas o están asociadas a los NAT Gateways eliminados).
3. Selecciona cada Elastic IP, haz clic en **Actions > Release Elastic IP address**.
4. Confirma la liberación.

### 3. Verificar que la Elastic IP no esté asociada

Primero, necesitas asegurarte de que la Elastic IP no esté asociada a ningún recurso activo, como una instancia EC2 o un NAT Gateway.

Comando para listar Elastic IPs:

```bash
aws ec2 describe-addresses --query 'Addresses[*].[AllocationId, PublicIp, InstanceId, AssociationId, NetworkInterfaceId]' --output table
```

Esto te mostrará una lista de Elastic IPs y sus asociaciones actuales. Busca la IP que deseas eliminar y toma nota de su `AllocationId`.

### 4. Verificar si la IP está asociada a un NAT Gateway

Dado que los clústeres de EKS suelen usar Elastic IPs para NAT Gateways, verifica si el NAT Gateway sigue existiendo.

Comando para listar NAT Gateways:

```bash
aws ec2 describe-nat-gateways --query 'NatGateways[*].[NatGatewayId, State, SubnetId, VpcId]' --output table
```

Si el NAT Gateway correspondiente todavía existe, elimina primero el NAT Gateway:

Comando para eliminar el NAT Gateway:

```bash
aws ec2 delete-nat-gateway --nat-gateway-id <NAT_GATEWAY_ID>
```

### 5. Liberar la Elastic IP

Una vez que estés seguro de que la Elastic IP no está asociada a ningún recurso, puedes liberarla.

Comando para liberar la Elastic IP:

```bash
aws ec2 release-address --allocation-id <ALLOCATION_ID>
```

Este comando libera la Elastic IP y evita que genere costos adicionales.

### 6. Verificar que la Elastic IP fue liberada

Después de ejecutar los comandos anteriores, verifica que la IP ya no esté presente:

Comando para verificar:

```bash
aws ec2 describe-addresses --query 'Addresses[*].[PublicIp, AllocationId]' --output table
```

### Notas Importantes

- **Eliminar el NAT Gateway:** Los NAT Gateways suelen ser uno de los recursos que más costos generan en AWS, así que asegúrate de eliminarlos si ya no los necesitas.
- **Eliminación Completa del Clúster:** Al eliminar un clúster de EKS, verifica que todas las pilas de CloudFormation asociadas al clúster hayan sido eliminadas. Si no es así, ve al panel de CloudFormation en la consola de AWS y elimina las pilas manualmente.

### Verificar el estado del stack en CloudFormation

1. Ve a la consola de CloudFormation en AWS.
2. Busca el stack llamado `eksctl-alfresco-cluster`.
3. Revisa su estado:
  - Si está en estado `CREATE_FAILED`, elimina el stack seleccionándolo y haciendo clic en **Delete**.
  - Si está en otro estado (`CREATE_IN_PROGRESS`, etc.), espera a que finalice o cancela la operación manualmente.

### Limpiar recursos relacionados

Si no puedes eliminar el stack, limpia manualmente los recursos asociados:

#### a. Subnets y Security Groups

1. Ve a la consola de VPC.
2. Verifica las subnets y grupos de seguridad asociados con el stack.
3. Elimina los que están sin uso.

#### b. Elastic IPs

1. Ve a la consola de EC2.
2. Busca Elastic IPs asociadas al stack y libéralas.

#### c. NAT Gateways

1. Ve a la consola de VPC.
2. Busca y elimina los NAT Gateways relacionados.

#### d. Load Balancers

1. Ve a la consola de EC2.
2. Revisa los Load Balancers asociados y elimínalos.

### Intentar eliminar el stack nuevamente

Después de limpiar los recursos relacionados, vuelve a intentar eliminar el stack desde la consola de CloudFormation o terraform en su defecto.







## 2. Verificar la Eliminación
Después de ejecutar el comando, verifica que no queden recursos asociados a Alfresco:

```bash
kubectl get all -n $NAMESPACE
```

Si aún quedan recursos (como PersistentVolumeClaims o ConfigMaps), elimínalos manualmente.

## (IMPORTANTE) Apagar el Clúster Completamente

### Terraform
Si es por terraform es 
```bash
terraform destroy
```
En caso de que no se pueda eliminar hay que revisar que el EFS creado manualmente no tenga asociado ningun grupo de seguridad del terraform, tambien hay que validar que no existe ningun ELB creado asociado y que no exista ningun SG asociado a la VPC.

aws elbv2 describe-load-balancers --region $REGION --query "LoadBalancers[?VpcId=='vpc-093a9e628c3f781df']"


### kubectl
si es po kubectl: 

```bash
eksctl delete cluster --name $EKS_CLUSTER_NAME 
 ```

### Diagnosticar:
```bash
aws cloudformation list-stacks --region us-east-1
aws eks list-clusters --region us-east-1
aws eks --region us-east-1 update-kubeconfig --name alfresco-manual
```

## Descativación sin borar y re activación

## **1. Escalar los Nodos a Cero**
La forma más efectiva de detener costos en un clúster EKS es escalar los nodos a cero, ya que las instancias EC2 asociadas representan los costos principales.

## Escalar los Nodos
1. Encuentra el nombre del grupo de nodos:
   ```bash
   export NODEGROUP_NAME=$(eksctl get nodegroup --cluster $EKS_CLUSTER_NAME -o json | jq -r '.[0].Name')
   ```

2. Escala el grupo de nodos a cero:
   ```bash
   eksctl scale nodegroup    --cluster $EKS_CLUSTER_NAME    --name $NODEGROUP_NAME    --nodes 0
   ```

3. Verifica que no haya nodos activos:
   ```bash
   kubectl get nodes
   ```

---

## **5. Reactivar el Clúster**
Cuando estés listo para trabajar nuevamente, puedes reactivar los servicios.

### Escalar los Nodos
1. Escala los nodos a su estado original:
   ```bash
   eksctl scale nodegroup    --cluster $EKS_CLUSTER_NAME>    --name <NODEGROUP_NAME>    --nodes <DESIRED_COUNT>
   ```

2. Verifica que los nodos estén activos:
   ```bash
   kubectl get nodes
   ```

# CodeBuild Local
```sh
git clone https://github.com/aws/aws-codebuild-docker-images.git
cd ~/environment/aws-codebuild-docker-images/al/x86_64/standard/5.0


```


# terraform:

Para Clonar la configuración de red y pasarla aterraform, se ejecutan estos comandos y el resultado se le pasa a chatgpt
```bash
ec2-user:~/environment $ aws ec2 describe-vpcs --filters "Name=cidr-block,Values=192.168.0.0/16"
```

```bash
ec2-user:~/environment $ aws ec2 describe-subnets --filters "Name=vpc-id,Values= vpc-0624fa88e91fbba3e"
```


```bash
ec2-user:~/environment $ aws ec2 describe-route-tables --filters "Name=vpc-id,Values= vpc-0624fa88e91fbba3e "
```

``` bash
terraform init
terraform plan
terraform apply -auto-approve
terraform destroy
#cuando el estado del backend ya existe y genera conflicto
terraform init -reconfigure
```


# nuevo helm intento:

```bash
export ACS_HOSTNAME=acs.$DOMAIN

helm upgrade --install acs alfresco/alfresco-content-services \
--set alfresco-repository.persistence.enabled=true \
--set alfresco-repository.persistence.storageClass="nfs-client" \
--set alfresco-transform-service.filestore.persistence.enabled=true \
--set alfresco-transform-service.filestore.persistence.storageClass="nfs-client" \
--set global.known_urls=https://${ACS_HOSTNAME} \
--set global.alfrescoRegistryPullSecrets=quay-registry-secret \
--namespace=$NAMESPACE


helm upgrade --install acs ./alfresco-content-services \
--set alfresco-repository.persistence.enabled=true \
--set alfresco-repository.persistence.storageClass="nfs-client" \
--set alfresco-transform-service.filestore.persistence.enabled=true \
--set alfresco-transform-service.filestore.persistence.storageClass="nfs-client" \
--set global.known_urls=https://${ACS_HOSTNAME} \
--set global.alfrescoRegistryPullSecrets=quay-registry-secret \
--values letsencrypt_values.yaml \
--namespace=alfresco



echo "UPSTREAM_HELM_VALUES=values.yaml" >> $GITHUB_ENV
export UPSTREAM_HELM_VALUES=values.yaml

helm install acs ./alfresco-content-services \
--set global.search.sharedSecret="$(openssl rand -hex 24)" \
--set global.known_urls=https://${ACS_HOSTNAME} \
--set global.alfrescoRegistryPullSecrets=quay-registry-secret \
--values ./acs-deployment-master/helm/alfresco-content-services/$UPSTREAM_HELM_VALUES 

```
