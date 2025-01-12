
# Guía Completa: Instalación de Alfresco en un Clúster EKS desde AWS Cloud9

Este documento describe paso a paso cómo configurar un clúster de Kubernetes (EKS) desde AWS Cloud9 e instalar Alfresco Content Services. Se incluyen configuraciones detalladas, ejemplos de código y secciones de troubleshooting para resolver problemas comunes.


---

## Configuración Inicial del Ambiente en Cloud9

## Limpiar y recuperar espacio de Cloud 9

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


### Paso 1: Preparación de Cloud9
1. **Lanza una instancia de Cloud9** en la misma VPC donde planeas desplegar tu clúster EKS.
2. Asegúrate de que la instancia tenga permisos administrativos necesarios para gestionar recursos en AWS.

### Paso 2: Configuración de Cloud9
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
```
Instalar Helm
```bash
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 > get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh

helm version | cut -d + -f 1
```

### Configuración de Claves de repositorio Nexus

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

### Paso 1: Crear Variables Básicas
1. **Crea las Variables Necesarias**:
   ```bash
   export EKS_CLUSTER_NAME=alfresco
   export ECR_NAME=alfresco
   export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
   export S3_BUCKET_NAME=alfresco-content-bucket
   export REGION=us-east-1
   
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
### Paso 2: Usar Variables en Comandos
- Ejemplo con `eksctl`:
  ```bash
  eksctl create cluster --name $EKS_CLUSTER_NAME --region $REGION --version 1.29 --instance-types t3.xlarge --nodes 3
  ```

### Troubleshooting: Variables de Entorno
- **Problema:** Variable no definida o devuelve un valor incorrecto.
  - **Solución:** Revisa si la variable está configurada correctamente:
    ```bash
    printenv | grep <variable_name>
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


### Troubleshooting: Conexion EKS y Cloud9 con `aws configure`

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

## Create the EKS cluster
There are multiple ways to set up an EKS cluster, but one of the most simple is by using eksctl. This section will guide you in creating a new EKS cluster that satisfy the minimum requirements to have a basic ACS installation up and running.

Set the default region you want to work on, to avoid having to add --region to every command:

```bash
export AWS_DEFAULT_REGION=eu-west-1
```
Set the cluster name in an environment variable that can be reused later:

```bash
EKS_CLUSTER_NAME=my-alfresco-eks
```
Create the cluster using the latest supported version - check the main README. Most common choices for instance types are m5.xlarge and t3.xlarge:

```bash
eksctl create cluster --name $EKS_CLUSTER_NAME --version 1.29 --instance-types t3.xlarge --nodes 3
```
hay que esperar hasta que construya todos los elementos, el debe crear los nodegroups y los nodos, que son instancias de Ec2

Este comando es para construirlo directamente desde AWS CLI, para personalizaciones>
```bash
aws eks create-cluster \
  --name $EKS_CLUSTER_NAME \
  --region us-east-1 \
  --role-arn arn:aws:iam::$AWS_ACCOUNT_ID:role/EKSClusterRole \
  --resources-vpc-config subnetIds=subnet-075293f3be248f636,securityGroupIds=eks-cluster-sg-devopsalfresco-1278662094
```

Enable the OIDC provider that is necessary to install further EKS addons later:

```bash
eksctl utils associate-iam-oidc-provider --cluster=$EKS_CLUSTER_NAME --approve
```
For further information please refer to the Getting started with Amazon EKS – eksctl guide.

Find The ID of VPC created when your cluster was built using the command below (replacing YOUR-CLUSTER-NAME with the name you gave your cluster):
```bash
 aws eks describe-cluster \
 --name $EKS_CLUSTER_NAME \
 --query "cluster.resourcesVpcConfig.vpcId" \
 --output text
```


registrar el cluster>
```bash
aws eks --region us-east-1 update-kubeconfig --name $EKS_CLUSTER_NAME 
```

### Troubleshooting y Validaciones Adicionales

## Validar el Archivo `kubeconfig`
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

---

## Creación del Bucket S3

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


## Creación del Clúster EKS

### Paso 1: Crear el Clúster con `eksctl`
Ejecuta el siguiente comando para crear un clúster básico de EKS:

```bash
eksctl create cluster --name devopsalfresco --region us-east-1 --nodes 2 --node-type t3.medium
```

### Paso 2: Verificar el Estado del Clúster
```bash
kubectl get nodes
```

Si los nodos no están listados, revisa los eventos del clúster:
```bash
kubectl describe nodes
kubectl get events -A
```

### Paso 3: Obtener el Endpoint del Clúster
```bash
aws eks describe-cluster --region us-east-1 --name $EKS_CLUSTER_NAME --query "cluster.endpoint" --output text
```
Esto devuelve el endpoint del clúster.

### Paso 4: Verificar Conectividad con el Endpoint
```bash
curl -k <CLUSTER_ENDPOINT>
```
Reemplaza `<CLUSTER_ENDPOINT>` con el endpoint obtenido en el paso anterior. Si responde con un mensaje "403 Forbidden", significa que la conexión funciona, pero las credenciales no están configuradas correctamente.



---

## Configuración del EBS CSI Driver

### Paso 1: Crear el Rol IAM
Crea un rol IAM para el controlador del EBS CSI Driver:

```bash
eksctl create iamserviceaccount \
--name ebs-csi-controller-sa \
--namespace kube-system \
--cluster $EKS_CLUSTER_NAME \
--attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
--approve \
--role-name AmazonEKS_EBS_CSI_DriverRole
```



### Paso 2: Habilitar el Addon del EBS CSI Driver
``` bash
eksctl create addon \
--name aws-ebs-csi-driver \
--cluster $EKS_CLUSTER_NAME \
--service-account-role-arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/AmazonEKS_EBS_CSI_DriverRole \
--force
```

### Troubleshooting: Verificación del EBS CSI Driver

1. **Listar Roles para validar su creación**:
    ``` bash
    aws iam list-roles | grep AmazonEKS_EBS_CSI_DriverRole
    ```
1. **Validar el addon creado**:
    ``` bash
    eksctl get addons --cluster $EKS_CLUSTER_NAME
    ```
2. **Revisar los pods del controlador**:
   ```bash
   kubectl get pods -n kube-system | grep ebs
   ```
   Deberías ver algo como:
   ``` php
   ebs-csi-controller-0     3/3     Running   0          <AGE>
   ebs-csi-node-xxxxxx      2/2     Running   0          <AGE>
   ```
2. **Logs del pod**:
   ```bash
   kubectl logs -n kube-system <nombre-del-pod>
   ```
4. **Diagnostico de incidente de Rol**:
      ### Paso 1: Verifica la Cuenta de Servicio Existente
      
      Verifica si la cuenta de servicio ebs-csi-controller-sa ya está creada en Kubernetes:

       ```bash
       kubectl get serviceaccount ebs-csi-controller-sa -n kube-system
       ```

      Si aparece, significa que ya existe pero no está asociada con el rol IAM que      deseas crear.

      ### Paso 2: Eliminar la Cuenta de Servicio Existente (Opcional)
      Si no necesitas conservar la cuenta de servicio existente, elimínala:

      ```bash
      kubectl delete serviceaccount ebs-csi-controller-sa -n kube-system
      ```

      ### Paso 3: Verifica el Rol
      Después de ejecutar el comando, verifica que el rol haya sido creado:

      ``` bash
      aws iam get-role --role-name AmazonEKS_EBS_CSI_DriverRole
      ```

      Si el rol fue creado correctamente, verás información como el ARN.
---

# Prepare the cluster for Content Services
https://docs.alfresco.com/content-services/latest/install/containers/helm/#helm-deployment-with-aws-eks

Now we have an EKS cluster up and running, there are a few one time steps we need to perform to prepare the cluster for Content Services to be installed.

## DNS


Create a hosted zone in Route53 using these steps if you don’t already have one available.

Create a public certificate for the hosted zone (created in step 1) in Certificate Manager using these steps if you don’t have one already available. Make a note of the certificate ARN for use later.

Create a file called external-dns.yaml with the text below (replace YOUR-DOMAIN-NAME with the domain name you created in step 1). This manifest defines a service account and a cluster role for managing DNS:

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
el comando ```kubectl apply -f external-dns.yaml -n kube-system```  genera un error: 
```sh
kubectl apply -f external-dns.yaml -n kube-system
serviceaccount/external-dns unchanged
deployment.apps/external-dns unchanged
resource mapping not found for name: "external-dns" namespace: "" from "external-dns.yaml": no matches for kind "ClusterRole" in version "rbac.authorization.k8s.io/v1beta1"
ensure CRDs are installed first
resource mapping not found for name: "external-dns-viewer" namespace: "" from "external-dns.yaml": no matches for kind "ClusterRoleBinding" in version "rbac.authorization.k8s.io/v1beta1"
ensure CRDs are installed first
```
se corrige :



## CREACION DEL DOMINIO y Route 53
ver documento word

esto importante para que pueda registrar el nuevo acs-ingress: 

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
```sh
helm install acs-ingress ingress-nginx/ingress-nginx --version=3.7.1\
 --set controller.scope.enabled=true \
 --set controller.scope.namespace=alfresco \
 --set rbac.create=true \
 --set controller.config."proxy-body-size"="100m" \
 --set controller.service.targetPorts.https=80 \
 --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-backend-protocol"="http" \
 --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-ssl-ports"="https" \
 --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-ssl-cert"="arn:aws:acm:us-east-1:706722401192:certificate/a8babb15-e7fe-4e14-a692-a23dbee1cb47" \
 --set controller.service.annotations."external-dns\.alpha\.kubernetes\.io/hostname"="acs.tfmfc.com" \
 --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-ssl-negotiation-policy"="ELBSecurityPolicy-TLS-1-2-2017-01" \
 --set controller.publishService.enabled=true \
 --atomic \
 --namespace alfresco
```

Error de versión: se corrige usando la versión más actualizada del ingres en helm

```sh
helm install acs-ingress ingress-nginx/ingress-nginx\
 --set controller.scope.enabled=true \
 --set controller.scope.namespace=alfresco \
 --set rbac.create=true \
 --set controller.config."proxy-body-size"="100m" \
 --set controller.service.targetPorts.https=80 \
 --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-backend-protocol"="http" \
 --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-ssl-ports"="https" \
 --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-ssl-cert"="arn:aws:acm:us-east-1:706722401192:certificate/a8babb15-e7fe-4e14-a692-a23dbee1cb47" \
 --set controller.service.annotations."external-dns\.alpha\.kubernetes\.io/hostname"="acs.tfmfc.com" \
 --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-ssl-negotiation-policy"="ELBSecurityPolicy-TLS-1-2-2017-01" \
 --set controller.publishService.enabled=true \
 --atomic \
 --namespace alfresco
```

# EFS: File System

Tutorial: se ejecutan estos comando para sacer las ids y los rangos de ip de la vpc del cluster:
```sh
 aws eks describe-cluster --name YOUR-CLUSTER-NAME --query "cluster.resourcesVpcConfig.vpcId" --output text

 aws ec2 describe-vpcs --vpc-ids VPC-ID --query "Vpcs[].CidrBlock" --output text
```

Deploy an NFS Client Provisioner with Helm using the following commands (replace EFS-DNS-NAME with the string FILE-SYSTEM-ID.efs.AWS-REGION.amazonaws.com where the FILE-SYSTEM-ID is the ID retrieved in step 1 and AWS-REGION is the region you’re using, e.g. fs-72f5e4f1.efs.us-east-1.amazonaws.com):
```sh
 helm repo add stable https://kubernetes-charts.storage.googleapis.com
 helm install alfresco-nfs-provisioner stable/nfs-client-provisioner --set nfs.server="EFS-DNS-NAME" --set nfs.path="/" --set storageClass.name="nfs-client" --set storageClass.archiveOnDelete=false -n kube-system
```
la version de https://kubernetes-charts.storage.googleapis.com, esta obsoleta, por lo que se reemplaza por https://charts.helm.sh.stable

```sh
helm repo add stable https://charts.helm.sh.stable
```
```sh
helm list -n kube-system
```
NAME                            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                           APP VERSION
alfresco-nfs-provisioner        kube-system     1               2024-12-27 02:31:32.278936629 +0000 UTC deployed        nfs-client-provisioner-1.2.11   3.1.0    


ajustado con el id del EFS:

 helm repo add stable https://kubernetes-charts.storage.googleapis.com
 helm install alfresco-nfs-provisioner stable/nfs-client-provisioner --set nfs.server="EFS-DNS-NAME" --set nfs.path="/" --set storageClass.name="nfs-client" --set storageClass.archiveOnDelete=false -n kube-system





# Sesion juan jose

kubectl get pods -n alfresco

kubectl logs acs-ingress-ingress-nginx-controller-7f7f98c9c8-pzmlj -n alfresco -f


```sh
kubectl create secret docker-registry quay-registry-secret --docker-server=quay.io --docker-username=fc7430 --docker-password=Bunny2024! -n alfresco
```
```sh
helm install acs alfresco/alfresco-content-services \
--set externalPort="443" \
--set externalProtocol="https" \
--set externalHost="acs.tfmfc.com" \
--set persistence.enabled=true \
--set persistence.storageClass.enabled=true \
--set persistence.storageClass.name="nfs-client" \
--set global.alfrescoRegistryPullSecrets=quay-registry-secret \
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
--set alfresco-common.nginx.annotations=" " \
--set alfresco-common.nginx.secure.annotations=" " \
--atomic \
--timeout 10m0s \
--namespace=alfresco
```

Comando actualizado para usar el helm local
```sh
helm install acs ./alfresco-content-services \
--set externalPort="443" \
--set externalProtocol="https" \
--set externalHost="acs.tfmfc.com" \
--set persistence.enabled=true \
--set persistence.storageClass.enabled=true \
--set persistence.storageClass.name="nfs-client" \
--set alfresco-repository.persistence.existingClaim="alf-content-pvc" \
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
--set alfresco-search-enterprise.reindexing.enabled=false \
--namespace=alfresco
```

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
```
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

 kubectl create -f alf-efs-storage-class.yaml


comandos de diagnostico:
```sh
kubectl get svc -n alfresco
kubectl get pods -n alfresco 
kubectl logs acs-postgresql-acs-0 -n alfresco
kubectl describe pod acs-alfresco-repository-f9f5b9fc5-66jw6 -n alfresco
kubectl get events -n alfresco | grep repository
kubectl get pv

kubectl get deployments -n alfresco


kubectl exec -it acs-alfresco-repository-8c7688574-tfbvj  -n alfresco -- /bin/bash

ec2-user:~/environment/volumenes $ kubectl exec -it acs-alfresco-repository-5fc97dbb67-dn45l  -n alfresco -- /bin/bash                                                                                                              
[alfresco@acs-alfresco-repository-5fc97dbb67-dn45l tomcat]$ ls -l
total 72
-rw-r----- 1 root Alfresco 60393 Jul  7 21:02 LICENSE
-rw-r----- 1 root Alfresco  2333 Jul  7 21:02 NOTICE
drwxrwsrwx 4 root Alfresco    54 Dec 28 04:55 alf_data
drwxr-xr-x 1 root Alfresco    40 Nov 20 09:47 alfresco-mmt
drwxr-xr-x 1 root Alfresco   185 Nov 20 09:55 amps
drwxrwx--- 1 root Alfresco  4096 Aug  5 02:48 bin
drwxrwx--- 1 root Alfresco   254 Nov 20 09:47 conf
drwxrwx--- 1 root Alfresco  4096 Nov 20 09:47 lib
drwxrwx--- 1 root Alfresco   132 Dec 28 04:54 logs
drwxrwx--- 1 root Alfresco   110 Aug  5 02:49 native-jni-lib
drwxr-xr-x 1 root Alfresco    21 Nov 20 09:47 shared
drwxrwx--- 1 root Alfresco    49 Dec 28 04:55 temp
drwxr-x--- 1 root Alfresco    42 Nov 20 09:53 webapps
drwxrwx--- 1 root Alfresco    22 Dec 28 04:53 work
[alfresco@acs-alfresco-repository-5fc97dbb67-dn45l tomcat]$ cd alf_data
[alfresco@acs-alfresco-repository-5fc97dbb67-dn45l alf_data]$ ls -l
total 0
drwxr-s--- 2 alfresco Alfresco 6 Dec 28 04:55 contentstore
drwxr-s--- 2 alfresco Alfresco 6 Dec 28 04:54 contentstore.deleted
[alfresco@acs-alfresco-repository-5fc97dbb67-dn45l alf_data]$ cd contentstore
[alfresco@acs-alfresco-repository-5fc97dbb67-dn45l contentstore]$ ls -l
total 0
[alfresco@acs-alfresco-repository-5fc97dbb67-dn45l contentstore]$ df -h
Filesystem      Size  Used Avail Use% Mounted on
overlay          80G  9.9G   71G  13% /
tmpfs            64M     0   64M   0% /dev
tmpfs           7.8G     0  7.8G   0% /sys/fs/cgroup
/dev/nvme0n1p1   80G  9.9G   71G  13% /etc/hosts
shm              64M     0   64M   0% /dev/shm
tmpfs           8.0G   12K  8.0G   1% /run/secrets/kubernetes.io/serviceaccount
tmpfs           8.0G     0  8.0G   0% /usr/local/tomcat/shared/classes/alfresco/extension/license
tmpfs           7.8G     0  7.8G   0% /proc/acpi
tmpfs           7.8G     0  7.8G   0% /sys/firmware
[alfresco@acs-alfresco-repository-5fc97dbb67-dn45l contentstore]$ exit
exit
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
```

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

helm upgrade -i ingress-nginx ingress-nginx/ingress-nginx \
    --version 4.2.3 \
    --namespace kube-system \
    --set controller.service.type=ClusterIP


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
helm uninstall alfresco --namespace alfresco
kubectl delete pvc --all -n alfresco
kubectl delete configmap --all -n alfresco
kubectl delete secret --all -n alfresco
```

---

--- 

# Guía para Detener Servicios y Minimizar Costos en AWS EKS

Este documento describe cómo detener temporalmente los servicios de un clúster EKS para evitar costos adicionales mientras no estás trabajando activamente.

---
# (IMPORTANTE) Apagar el Clúster Completamente
Si no necesitas mantener el clúster temporalmente, puedes eliminarlo por completo:

```bash
eksctl delete cluster --name $EKS_CLUSTER_NAME
```


## **1. Escalar los Nodos a Cero**
La forma más efectiva de detener costos en un clúster EKS es escalar los nodos a cero, ya que las instancias EC2 asociadas representan los costos principales.

### Escalar los Nodos
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

## **2. Eliminar Servicios de Tipo LoadBalancer**
Servicios como `LoadBalancer` pueden seguir generando costos debido a las direcciones IP y balanceadores asociados.

### Identificar y Eliminar Servicios
1. Lista todos los servicios de Kubernetes:
   ```bash
   kubectl get svc -A
   ```

2. Busca los servicios de tipo `LoadBalancer` y elimínalos:
   ```bash
   kubectl delete svc <SERVICE_NAME> -n <NAMESPACE>
   ```

**Nota:** Asegúrate de tener un respaldo de las configuraciones antes de eliminarlos.

---

## **3. Deshabilitar Addons del Clúster**
Los addons de EKS, como el EBS CSI Driver, también pueden generar costos.

### Deshabilitar Addons
1. Verifica los addons instalados:
   ```bash
   eksctl get addon --cluster $EKS_CLUSTER_NAME
   ```

2. Elimina los addons que no sean necesarios temporalmente:
   ```bash
   eksctl delete addon --name aws-ebs-csi-driver --cluster $EKS_CLUSTER_NAME
   ```

---

## **4. Suspender Recursos de Infraestructura**
### Eliminar Nodos Manualmente
Si los nodos aún están activos, puedes eliminarlos manualmente desde la consola de EC2 o usando el siguiente comando:
```bash
aws ec2 terminate-instances --instance-ids <INSTANCE_ID>
```

# (IMPORTANTE) Apagar el Clúster Completamente
Si no necesitas mantener el clúster temporalmente, puedes eliminarlo por completo:

```bash
eksctl delete cluster --name $EKS_CLUSTER_NAME
```

**Nota:** Esto eliminará todos los recursos asociados al clúster.

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

### Volver a Crear Servicios
Si eliminaste servicios de tipo `LoadBalancer`, vuelve a aplicarlos desde los manifiestos originales con:
```bash
kubectl apply -f <SERVICE_MANIFEST>
```

---


## 1. Desinstalar Alfresco con Helm
Ejecuta el siguiente comando para desinstalar Alfresco:

```bash
helm uninstall alfresco --namespace alfresco
```

Esto eliminará los recursos de Alfresco creados por Helm en el espacio de nombres alfresco.

## 2. Verificar la Eliminación
Después de ejecutar el comando, verifica que no queden recursos asociados a Alfresco:

```bash
kubectl get all -n alfresco
```

Si aún quedan recursos (como PersistentVolumeClaims o ConfigMaps), elimínalos manualmente.

## 3. Eliminar Recursos Persistentes
Eliminar PVCs (Persistent Volume Claims):

```bash
kubectl delete pvc --all -n alfresco
```
Eliminar ConfigMaps y Secrets:

```bash
kubectl delete configmap --all -n alfresco
kubectl delete secret --all -n alfresco
```
Eliminar el Namespace (Opcional): Si no necesitas mantener el namespace alfresco, elimínalo:

```bash
kubectl delete namespace alfresco
```

ingress-nginx


1. Identificar el Release de NGINX
Verifica el nombre del release que usaste para instalar NGINX Ingress:

```bash
helm list -n ingress-nginx
```

Esto debería mostrar una lista de releases, incluyendo el que corresponde a NGINX.

2. Desinstalar NGINX
Usa el siguiente comando para desinstalar NGINX:

```bash
helm uninstall <release-name> -n ingress-nginx
```

Por ejemplo, si el release se llama ingress-nginx, ejecuta:

```bash
helm uninstall ingress-nginx -n ingress-nginx
```

3. Verificar la Eliminación
Después de desinstalar NGINX, verifica que los recursos hayan sido eliminados:

Revisar Servicios, Pods y Otros Recursos:

```bash
kubectl get all -n ingress-nginx
```

Si quedan recursos como servicios o pods, elimínalos manualmente:

```bash
kubectl delete pod,svc --all -n ingress-nginx
```

Eliminar el Namespace (Opcional): Si ya no necesitas el namespace ingress-nginx, elimínalo:

```bash
kubectl delete namespace ingress-nginx
```
4. Verificar Servicios de Tipo LoadBalancer

Si NGINX creó un servicio de tipo LoadBalancer, puede que siga activo y generando costos.

Lista todos los servicios:

```bash
kubectl get svc -A
```
Elimina el servicio de LoadBalancer asociado a NGINX (si aún existe):

```bash
kubectl delete svc <SERVICE_NAME> -n ingress-nginx
```

5. Escalar NodeGroups a Cero (Opcional)
Si los nodos del clúster fueron utilizados solo para NGINX y Alfresco, considera escalarlos a cero o eliminarlos:

Escalar Nodos:
```bash
eksctl scale nodegroup --cluster $EKS_CLUSTER_NAME --name $NODEGROUP_NAME --nodes 0
```

Eliminar NodeGroup:

```bash
eksctl delete nodegroup --cluster $EKS_CLUSTER_NAME --name $NODEGROUP_NAME
```

6. Confirmar Limpieza
Verifica que no haya recursos residuales:

Revisar Recursos de Kubernetes:

```bash
kubectl get all -A
kubectl get pvc -A
```

Revisar en AWS: Desde la consola de AWS, confirma que no haya:

Instancias EC2 activas.
LoadBalancers asociados.
Volúmenes EBS no eliminados.


No olvidar de eliminar la VPS los net gateways y las elastics IP ya que generan costos tambien

1. Eliminar los NAT Gateways
Ve a la consola de Amazon VPC.
En el menú lateral, selecciona NAT Gateways.
Busca los NAT Gateways asociados al clúster (puedes identificarlos por el nombre que incluye eksctl-<nombre-cluster>).
Selecciona el NAT Gateway y haz clic en Actions > Delete NAT Gateway.
Confirma la eliminación y espera a que el estado cambie a Deleted.
2. Liberar las Elastic IPs
En la consola de EC2, selecciona Elastic IPs en el menú lateral.
Busca las Elastic IPs asociadas al clúster (usualmente tienen etiquetas o están asociadas a los NAT Gateways eliminados).
Selecciona cada Elastic IP, haz clic en Actions > Release Elastic IP address.
Confirma la liberación.


1. Verifica que la Elastic IP no esté asociada
Primero, necesitas asegurarte de que la Elastic IP no esté asociada a ningún recurso activo, como una instancia EC2 o un NAT Gateway.

Comando para listar Elastic IPs:
bash
Copiar código
aws ec2 describe-addresses --query 'Addresses[*].[AllocationId, PublicIp, InstanceId, AssociationId, NetworkInterfaceId]' --output table
Esto te mostrará una lista de Elastic IPs y sus asociaciones actuales. Busca la IP que deseas eliminar y toma nota de su AllocationId.

2. Verifica si la IP está asociada a un NAT Gateway
Dado que los clústeres de EKS suelen usar Elastic IPs para NAT Gateways, verifica si el NAT Gateway sigue existiendo.

Comando para listar NAT Gateways:
bash
Copiar código
aws ec2 describe-nat-gateways --query 'NatGateways[*].[NatGatewayId, State, SubnetId, VpcId]' --output table
Si el NAT Gateway correspondiente todavía existe, elimina primero el NAT Gateway:

Comando para eliminar el NAT Gateway:
bash
Copiar código
aws ec2 delete-nat-gateway --nat-gateway-id <NAT_GATEWAY_ID>
3. Libera la Elastic IP
Una vez que estés seguro de que la Elastic IP no está asociada a ningún recurso, puedes liberarla.

Comando para liberar la Elastic IP:
bash
Copiar código
aws ec2 release-address --allocation-id <ALLOCATION_ID>
Este comando libera la Elastic IP y evita que genere costos adicionales.

4. Verifica que la Elastic IP fue liberada
Después de ejecutar los comandos anteriores, verifica que la IP ya no esté presente:

Comando para verificar:
bash
Copiar código
aws ec2 describe-addresses --query 'Addresses[*].[PublicIp, AllocationId]' --output table
Notas Importantes
Eliminar el NAT Gateway: Los NAT Gateways suelen ser uno de los recursos que más costos generan en AWS, así que asegúrate de eliminarlos si ya no los necesitas.
Eliminación Completa del Clúster: Al eliminar un clúster de EKS, verifica que todas las pilas de CloudFormation asociadas al clúster hayan sido eliminadas. Si no es así, ve al panel de CloudFormation en la consola de AWS y elimina las pilas manualmente.

tener en cuenta que quedan los templates en Cloudformation entonces si se dersea recrear se puede usar el template o se elimina el template en la consola

1. Verifica el estado del stack en CloudFormation
Ve a la consola de CloudFormation en AWS.
Busca el stack llamado eksctl-alfresco-cluster.
Revisa su estado:
Si está en estado CREATE_FAILED, elimina el stack seleccionándolo y haciendo clic en Delete.
Si está en otro estado (CREATE_IN_PROGRESS, etc.), espera a que finalice o cancela la operación manualmente.
2. Limpia recursos relacionados
Si no puedes eliminar el stack, limpia manualmente los recursos asociados:

a. Subnets y Security Groups
Ve a la consola de VPC.
Verifica las subnets y grupos de seguridad asociados con el stack.
Elimina los que están sin uso.
b. Elastic IPs
Ve a la consola de EC2.
Busca Elastic IPs asociadas al stack y libéralas.
c. NAT Gateways
Ve a la consola de VPC.
Busca y elimina los NAT Gateways relacionados.
d. Load Balancers
Ve a la consola de EC2.
Revisa los Load Balancers asociados y elimínalos.
3. Intenta eliminar el stack nuevamente
Después de limpiar los recursos relacionados, vuelve a intentar eliminar el stack desde la consola de CloudFormation.

4. Crea el clúster nuevamente
Una vez que hayas eliminado el stack, intenta crear el clúster de nuevo:

bash
Copiar código
eksctl create cluster --name alfresco --region us-east-1
Si sigues teniendo problemas, asegúrate de que no existan conflictos en los nombres de las subnets o VPC que eksctl intenta usar.