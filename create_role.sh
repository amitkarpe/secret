
echo "Set/Export all ENV variable from .env file"
export $(grep -v '^#' ENV | xargs);
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text); echo $AWS_ACCOUNT_ID;
export OIDC_PROVIDER=$(aws eks describe-cluster --name $cluster --query "cluster.identity.oidc.issuer" --output text | sed -e "s/^https:\/\///"); echo OIDC_PROVIDER - $OIDC_PROVIDER; echo "";

echo ${secret};
export SECRET_ARN=$(aws secretsmanager get-secret-value --secret-id ${secret} --query ARN --output text)
echo ${SECRET_ARN}

echo ""
echo "Get role name"
aws iam get-role --role-name $role_name;
echo ""
echo ""
set -a;
#envsubst < src/trust.json | tee output/trust.json
envsubst < src/trust.json | tee output/trust.json
echo ""
echo ""
echo "creating role - $role_name"; aws iam create-role --role-name ${role_name} --assume-role-policy-document file://output/trust.json --description "eks: manage k8s secrets ";
echo ""

