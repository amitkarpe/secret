
echo "Set/Export all ENV variable from .env file"
export $(grep -v '^#' ENV | xargs);
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text); echo $AWS_ACCOUNT_ID;
export OIDC_PROVIDER=$(aws eks describe-cluster --name $cluster --query "cluster.identity.oidc.issuer" --output text | sed -e "s/^https:\/\///"); echo OIDC_PROVIDER - $OIDC_PROVIDER; echo "";
echo ${secret};
export SECRET_ARN=$(aws secretsmanager get-secret-value --secret-id ${secret} --query ARN --output text); echo ${SECRET_ARN}

echo "Get policy name"
aws iam get-policy --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${policy_name}
#envsubst < src/policy.json | tee output/policy.json
envsubst < src/policy.json | tee output/policy.json

echo "create policy - $policy_name"; aws iam create-policy --policy-name ${policy_name} --policy-document file://output/policy.json --description "eks: manage k8s secrets";
echo ""

echo "attaching role - $role_name to policy - $policy_name";
aws iam attach-role-policy --role-name ${role_name} --policy-arn=arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${policy_name}
echo ""

