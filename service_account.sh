
echo "Set/Export all ENV variable from .env file"
export $(grep -v '^#' ENV | xargs);
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text); echo $AWS_ACCOUNT_ID;
export OIDC_PROVIDER=$(aws eks describe-cluster --name $cluster --query "cluster.identity.oidc.issuer" --output text | sed -e "s/^https:\/\///"); echo OIDC_PROVIDER - $OIDC_PROVIDER; echo "";

echo "Secret: " ${secret};
export SECRET_ARN=$(aws secretsmanager get-secret-value --secret-id ${secret} --query ARN --output text)
echo "Secret ARN: " ${SECRET_ARN}

#SECRET_ARN=${ARN}
echo "Secret ARN: " ${SECRET_ARN}

echo "Annotate serviceaccount"; kubectl get sa -n ${ns} ${service_account}  -o yaml | grep annotations -A 1;
echo "";
echo "";
echo "kubectl annotate serviceaccount -n ${ns} ${service_account} eks.amazonaws.com/role-arn=arn:aws:iam::${AWS_ACCOUNT_ID}:role/${policy_name} --overwrite";
kubectl annotate serviceaccount -n ${ns} ${service_account} eks.amazonaws.com/role-arn=arn:aws:iam::${AWS_ACCOUNT_ID}:role/${role_name} --overwrite; echo "";

kubectl delete deploy webserver
kubectl delete pod hello
envsubst < src/webserver.yaml | tee output/webserver.yaml > /dev/null
sleep 5
#kubectl apply -f output/webserver.yaml
#kubectl logs  deployment/webserver

envsubst < src/hello.yaml | tee output/hello.yaml > /dev/null
kubectl apply -f output/hello.yaml
kubectl logs  hello
