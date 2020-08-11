Hi Team,
Current code for webserver.yaml is not working.
But once added following code, then it's working. There must be some instructions which I am not able to understand either from the README.md file or [blog](https://aws.amazon.com/blogs/containers/aws-secrets-controller-poc/).


```
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    run: webserver
  name: webserver
spec:
  replicas: 1
  selector:
    matchLabels:
      run: webserver
  template:
    metadata:
      annotations:
        secrets.k8s.aws/sidecarInjectorWebhook: enabled
        secrets.k8s.aws/secret-arn: arn:aws:secretsmanager:zzz:xxxxxxxxxx:secret:database-password-hlRvvF
      labels:
        run: webserver
    spec:
      serviceAccountName: webserver-service-account
      volumes:
        - name: secret-vol
          emptyDir:
            medium: Memory
      containers:
      - image: busybox:1.28
        name: webserver
        command: ['sh', '-c', 'echo $(cat /tmp/secret) && sleep 3600']
        volumeMounts:
          - name: secret-vol
            mountPath: /tmp
      initContainers:
      - name: aws-secrets-manager
        image: amazon/aws-secrets-manager-secret-sidecar:v0.1.1
        env:
          - name: SECRET_ARN
            valueFrom:
              fieldRef:
                fieldPath: metadata.annotations['secret.k8s.aws/secret-arn']
        volumeMounts:
          - name: secret-vol
            mountPath: /tmp
```

Whereas `hello.deployment.yaml` working without any issue as expected. Where it is having initContainers to inject secret into the main container.

```
  initContainers:
  - name: aws-secrets-manager
    image: amazon/aws-secrets-manager-secret-sidecar:v0.1.1
    env:
      - name: SECRET_ARN
        valueFrom:
          fieldRef: 
            fieldPath: metadata.annotations['secret.k8s.aws/secret-arn']
    volumeMounts:
      - name: secret-vol
        mountPath: /tmp
```

Can I update README.md for accurate instructions?
I do understand that `admission-controller/pods.go` have logic to append podsInitContainerPatch. Where `annotations` as `secrets.k8s.aws/sidecarInjectorWebhook: enabled`, helps to add `initContainers` or inject secret using initContainers. But I think it is not working as expected. 
Should I open a new issue? Sorry for adding a comment in the commit.