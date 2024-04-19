This article describes how to work with multiple EKS clusters and switch between them.

Adding  new EKS cluster config
1. Switch to the desired AWS_PROFILE (set aws profile name)
   export AWS_PROFILE={PROFILE_NAME}
2. List environment EKS clusters
   aws eks list-clusters --region {REGION}
3. Import Kubernetes cluster context
   aws eks update-kubeconfig \ --name {CUSTOMER_NAME} \ --region {REGION}

Switching between k8s cluster context
1. List your EKS context
   kubectl config get-context -o name
2. Set desired context
   kubectl config use-context arn:aws:eks:REGION:ACCOUNT_ID:cluster/CUSTOMER_NAME

## To interact with the cluster make sure you are connected to the environment client/customer VPN and allowed to access the private subnet.
