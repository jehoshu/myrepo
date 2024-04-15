# ADD IT IN THE ./zshrc shell profile
# AWS PROFILE SWITCH
aws-profiles() {
     cat ~/.aws/credentials | grep -v '#' | tr -d '[' | tr -d ']'
}
sap() {
 local aws_profile=$1
 export AWS_PROFILE=${aws_profile}
}
lap() {
 local aws_profile=$1
 aws sso login --profile ${aws_profile}
 export AWS_PROFILE=${aws_profile}
}

# ADD PROFILE ACCOUNT
 add_profile() {
  local aws_profile=$1
  local region=$2
  aws sso login --profile ${aws_profile}
  export AWS_PROFILE=${aws_profile}
  cluster=$(aws eks list-cluster --region ${region} | jq -r '.cluster[0]')
  aws eks update-kubeconfig --name ${cluster} --region ${region}
  arn=$(aws eks describe-cluster --name "$cluster" --region "$region" | jq -r '.cluster.arn')
  kubectl config use-context ${arn}
 }