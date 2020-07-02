
echo "Set/Export all ENV variable from .env file"
export $(grep -v '^#' ENV | xargs);
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text); echo $AWS_ACCOUNT_ID;
export OIDC_PROVIDER=$(aws eks describe-cluster --name $cluster --query "cluster.identity.oidc.issuer" --output text | sed -e "s/^https:\/\///"); echo OIDC_PROVIDER - $OIDC_PROVIDER; echo "";

echo ${secret};
export SECRET_ARN=$(aws secretsmanager get-secret-value --secret-id ${secret} --query ARN --output text)

echo ${SECRET_ARN}

read -r -d '' POLICY <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "webserversecret",
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetResourcePolicy",
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret",
                "secretsmanager:ListSecretVersionIds"
            ],
            "Resource": "${SECRET_ARN}"
        },
        {
            "Sid": "secretslists",
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetRandomPassword",
                "secretsmanager:ListSecrets"
            ],
            "Resource": "*"
        }
    ]
}
EOF

echo "Get policy name"
aws iam get-policy --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${policy_name}
echo "${POLICY}" > output/policy.json; cat output/policy.json | jq
echo "create policy - $policy_name"; aws iam create-policy --policy-name ${policy_name} --policy-document file://output/policy.json --description "eks: manage k8s secrets";
echo ""


read -r -d '' TRUST_RELATIONSHIP <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/${OIDC_PROVIDER}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${OIDC_PROVIDER}:sub": "system:serviceaccount:${ns}:${service_account}"
        }
      }
    }
  ]
}
EOF

echo "Get role name"
aws iam get-role --role-name $role_name;
echo "${TRUST_RELATIONSHIP}" > output/trust.json; cat output/trust.json| jq
echo "creating role - $role_name"; aws iam create-role --role-name ${role_name} --assume-role-policy-document file://output/trust.json --description "eks: manage k8s secrets ";
echo ""


echo "attaching role - $role_name to policy - $policy_name";
aws iam attach-role-policy --role-name ${role_name} --policy-arn=arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${policy_name}
echo ""


echo "Annotate serviceaccount"; kubectl get sa -n ${ns} ${service_account}  -o yaml | grep annotations -A 1;
echo "kubectl annotate serviceaccount -n ${ns} ${service_account} eks.amazonaws.com/role-arn=arn:aws:iam::${AWS_ACCOUNT_ID}:role/${policy_name} --overwrite";
kubectl annotate serviceaccount -n ${ns} ${service_account} eks.amazonaws.com/role-arn=arn:aws:iam::${AWS_ACCOUNT_ID}:role/${role_name} --overwrite; echo "";

sed -e "s/REPLACE/${SECRET_ARN}/g" src/webserver.yaml | tee output/webserver.yaml
sed -e "s/REPLACE/${SECRET_ARN}/g" src/hello.yaml | tee output/hello.yaml

kubectl delete deploy webserver
kubectl delete pod myapp

