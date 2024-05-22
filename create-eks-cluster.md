# terragrunt commands
terragrunt console
terragrunt state list
terragrunt apply -target=null_resource.add_archive_to_db
terragrunt run-all apply --terragrunt-ignore-external-dependencies
terragrunt run-all apply --exclude-external-dependencies
terragrunt state rm null_resource.add_archive_to_db

# To create a K8s cluster in EKS you need to do following steps:
# 1) Setup or preparation steps
#  - create AWS account
#  - create a VPC - virtual private space
#  - create an IAM role with Security Group (or in other words: create AWS user with list of permissions)
# 2) Create Cluster Control Plane - Master Nodes
#  - choose basic information like cluster name and k8s version
#  - choose region and VPC for your cluster
#  - set security
# 3) Create Worker Nodes and connect to cluster
# The Worker Nodes are some EC2 instances with CPU and storage resources.
#  - Create as a Node Group
#  - Choose cluster it will attach to
#  - Define Security Group, select instance type etc.
----------------------------------------------------------------------------------------------------------------

## Create kubernetes cluster om AWS EKS
 # install eks control
 brew tap weaveworks/tap
 brew install weaveworks/tap/eksctl
 ## important note - eksctl needs to authenticate with AWS in order to create the cluster
 ## you have to have your aws user credentials locally in the path -
 ## link how to configure https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html
 eksctl create cluster \ 
 --name test-cluster \ 
 --version 1.17 \ 
 --region eu-central-1 \ 
 --nodegroup-name linux-nodes \ 
 --node-type t2.micro \
 --nodes 2  
