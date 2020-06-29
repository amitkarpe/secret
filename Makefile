

export cluster=ci-internet
export secret=test_secret4
export AWS_ACCOUNT_ID=$$(aws sts get-caller-identity --query "Account" --output text)
export OIDC_PROVIDER=$$(aws eks describe-cluster --name ci-internet  --query "cluster.identity.oidc.issuer" --output text | sed -e "s/^https:\/\///")
export ARN=$$(aws secretsmanager get-secret-value --secret-id sm_nonprod_stp_cistpfedbuser --query ARN --output text)
export


info:
	set -a
	echo $${cluster}
	echo $${secret}
	echo $${AWS_ACCOUNT_ID}
	echo $${OIDC_PROVIDER}
	echo $${ARN}

replace:
	echo "Manually replace ARN & OIDC"
	echo $${ARN} 


create_policy:
	aws iam create-policy --policy-name test_webserver-secrets-policy --policy-document file://policy.json

get_code:
	wget https://github.com/aws-samples/aws-secret-sidecar-injector/raw/master/kubernetes-manifests/webserver.yaml

create_secret:
#	aws secretsmanager create-secret --name $${secret} --secret-string abcdefgh --region ap-southeast-1 --description "Test k8s secret" 
	aws secretsmanager create-secret --name $${secret} --region ap-southeast-1 --secret-string file://output/mycreds.json --description "Test k8s secret" --tags '[{"Key":"app","Value":"api"},{"Key":"env","Value":"ci"}]'

get_secret:
	aws secretsmanager get-secret-value --secret-id $${secret}
	aws secretsmanager get-secret-value --secret-id $${secret} --query ARN --output text
	aws secretsmanager get-secret-value --secret-id $${secret} --query SecretString --output text
	aws secretsmanager get-secret-value --secret-id $${secret} | jq .

