### Paso 1: Crear Variables Básicas
1. **Crea las Variables Necesarias**:
   ```bash
   export EKS_CLUSTER_NAME=alfresco-manual
   export ECR_NAME=alfresco
   export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
   export S3_BUCKET_NAME=alfresco-content-bucket
   export REGION=us-east-1
   ```


```bash
eksctl create cluster --name $EKS_CLUSTER_NAME --region $REGION  --version 1.31 --instance-types m5.xlarge --nodes 3
```