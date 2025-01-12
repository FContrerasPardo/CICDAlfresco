En esta solución se realiza lo siguiente:
1. Construcción de Entorno Cloud multicapa en AWS con instalación base de stack MEAN.
2. Configuración de Red y grupos de seguridad internos
3. Configuración de balanceo de cargas en AWS.

Los comando utilizados para el despliegue son:
1. terraform init
2. terraform plan -var-file="env_dev.tfvars"
3. terraform apply -var-file="env_dev.tfvars"
4. terraform destroy -var-file="env_dev.tfvars"     

Para la ejecución de estos comandos se deben modificar las variables del archivo "env_dev.tfvars" con las variables del entorno propio de ejecución.

Para la conexión por SSH se debe reemplazar el fichero terraformkey.pem en la carpeta Keys, por un par de claves creado en el entorno propio de AWS.
Ejemplo de conexión a instancia Mongo DB
ssh -i "terraformkey.pem" bitnami@ec2-3-92-65-87.compute-1.amazonaws.com

Pruebas unitarias:
1. Para probar que la DB este levantada y la creación correcta del usuario ejecutar el sigueinte comando dentro de la instancia de MongoDB: 
mongo admin --username MongoUser -p myPassword
2. Para probar la conexión desde el servidor de aplicación hacia Mongo desde comandos, ejecutar el siguiente comando, reemplazando por la IP del servidor de mongo generada en AWS:
mongo 'mongodb://MongoUser:myPassword@172.31.91.194:27017/admin'
db.version()
db.stats()

Cambios en el App Server:
1. una vez desplegada la instancia, todo cambio realizado sobre la aplicación, requiere el reinicio del sitio, para ello ejecutar el comando:
pm2 restart /home/ubuntu/app.js
