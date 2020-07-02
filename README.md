# Kubernetes secret on EKS

## This is sample program for use K8S secret with AWS Secret Manager.

### Install AWS Secrets Admission Controller Webhook

```
helm repo add secret-inject https://aws-samples.github.io/aws-secret-sidecar-injector/
helm repo update
helm install secret-inject secret-inject/secret-inject
kubectl get mutatingwebhookconfiguration

```


### Creating secrets

Without using JSON file

```
aws secretsmanager create-secret --name $${secret} --secret-string abcdefgh --region ap-southeast-1 --description "Test k8s secret"
```

Or with using JSON file

```
aws secretsmanager create-secret --name $${secret} --region ap-southeast-1 --secret-string file://src/mycreds.json --description "Test k8s secret" --tags '[{"Key":"app","Value":"api"},{"Key":"env","Value":"ci"}]'
```

### Create an AWS role to access secrets in AWS Secrets Manager

```
aws iam create-policy --policy-name webserver-secrets-policy --policy-document file://src/policy.json

aws iam create-role --role-name webserver-secrets-role --assume-role-policy-document file://src/trust.json --description "IAM Role to access webserver secret"

aws iam attach-role-policy --role-name webserver-secrets-role --policy-arn=arn:aws:iam::123456789012:policy/webserver-secret-policy
```

### Creating a Kubernetes Service Account

```
kubectl create sa ws
kubectl annotate serviceaccount ws  eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/webserver-secrets-role
kubectl annotate serviceaccount -n ${ns} ${service_account}  eks.amazonaws.com/role-arn=arn:aws:iam::${AWS_ACCOUNT_ID}:role/${role_name} --overwrite 
```

### Deploy the webserver

```
kubectl apply -f src/hello.yaml
```
