#!/usr/bin/env bash
bypass=0
usage () {
    echo "USAGE: $0 -r eu-west-1 -p shieldfc_demo -cit m5.2xlarge -eit i3.xlarge.elasticsearch -rit db.t3.xlarge -e stage -b"
    echo "  [-r|--aws-region region_name] Customer's AWS region."
    echo "  [-p|--aws-profile-name] Local AWS Profile name"
    echo "  [-e|--env-name] Environment name"
    echo "  [-cit|--eks-instance-type] Main EKS nodegroup instance type (Default: t3.2xlarge)"
    echo "  [-eit|--elastic-instance-type] Elasticserach data nodes instance type (Default: i3.large.elasticsearch)"
    echo "  [-rit|--rds-instance-type] RDS instance type (Default: db.t3.large)"
    echo "  [-b|--bypass] Bypass manual inputs"
    echo "  [-h|--help] Usage message"
}

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -r|--aws-region)
        REGION="$2"
        shift
        shift
        ;;
        -p|--aws-profile-name)
        PROFILE_NAME="$2"
        shift
        shift
        ;;
        -e|--env-name)
        ENV_NAME="$2"
        shift
        shift
        ;;
        -cit|--main-eks-instance-type)
        main_nodegroup_instance_type="$2"
        shift
        shift
        ;;
        -eit|--elastic-instance-type)
        es_instance_type="$2"
        shift
        shift
        ;;
        -rit|--rds-instance-type)
        rds_instance_type="$2"
        shift
        shift
        ;;
        -b|--bypass)
        bypass=1
        shift
        ;;
        -h|--help)
        help=1
        shift
        ;;
        *)
        usage
        exit 1
        ;;
    esac
done

if [[ -z $REGION ]]; then
    usage
    exit 1
fi

if [[ -z $PROFILE_NAME ]]; then
    usage
    exit 1
fi

if [[ -z $ENV_NAME ]]; then
    usage
    exit 1
fi

export AWS_PROFILE=$PROFILE_NAME
export ENV_NAME=$ENV_NAME

export TG_TF_REGISTRY_TOKEN=$(aws ssm get-parameter --region $REGION --name /aft/$(aws ssm get-parameter --region $REGION --name "/aft/account_custom_fields/environment_name" --query "Parameter.Value" --output text | jq --raw-output)/terraform/registry/token  --query "Parameter.Value" --output text --with-decrypt)
export TF_TOKEN_app_terraform_io=$TG_TF_REGISTRY_TOKEN
if [[ -z $main_nodegroup_instance_type ]]; then
    main_nodegroup_instance_type=$(sed -n -e '/main_nodegroup_instance_type/p' $ENV_NAME/env.hcl | awk '{print $3}')
    echo "==========================IMPORTANT================================"
    echo "Main EKS instance type parameter is not provided, used value from env.hcl ($main_nodegroup_instance_type)."
    echo "You can use --eks-instance-type argument to pass custom EKS main node group instance type."
else
    sed -i -e '/main_nodegroup_instance_type =/ s/= .*/= "'"$main_nodegroup_instance_type"'"/' $ENV_NAME/env.hcl
    git add $ENV_NAME/env.hcl 
    echo "==========================IMPORTANT================================"
    echo "Used EKS main nodegroup instance type: $main_nodegroup_instance_type"
fi

if [[ -z $es_instance_type ]]; then
    es_instance_type=$(sed -n -e '/es_instance_type/p' $ENV_NAME/env.hcl | awk '{print $3}')
    echo "Elasticsearch instance type parameter is not provided, used value from env.hcl ($es_instance_type)."
    echo "You can use --elastic-instance-type argument to pass custom data node instance type."
else
    sed -i -e '/es_instance_type =/ s/= .*/= "'"$es_instance_type"'"/' $ENV_NAME/env.hcl
    git add $ENV_NAME/env.hcl
    echo "Used Elasticsearch data nodes instance type: $es_instance_type"
fi

if [[ -z $rds_instance_type ]]; then
    rds_instance_type=$(sed -n -e '/rds_instance_type/p' $ENV_NAME/env.hcl | awk '{print $3}')
    echo "RDS instance type parameter is not provided, used value from env.hcl ($rds_instance_type)."
    echo "You can use --rds-instance-type argument to pass custom RDS instance type."
else
    sed -i -e '/rds_instance_type =/ s/= .*/= "'"$rds_instance_type"'"/' $ENV_NAME/env.hcl
    echo "Used RDS instance type: $rds_instance_type"
    git add $ENV_NAME/env.hcl
    rm $ENV_NAME/env.hcl
    git commit -a -m "[automation]updated env.hcl with new values"
fi

if [[ $help ]]; then
    usage
    exit 0
fi

if [[ $bypass == 1 ]]; then
  echo "Look like you bypassing the manual inputs. Please remove --bypass/-b flag if this is your first run."
  read -p "Proceed NOW!!! (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
fi

if [[ $bypass == 0 ]]; then
  echo "Do you connected to network-account client vpn?"
  read -p "Continue? (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
else
  echo "================================================================="
  echo "Skipping manual input. Remove --bypass/-b flag for manual inputs."
  echo "Assuming that you are connected to the network-account VPN"
fi

aws sts get-caller-identity > /dev/null 2>&1
RETURN=$?
if [[ $RETURN==0 ]]; then
  ACCOUNT_ID=$(aws sts get-caller-identity | jq  --raw-output ".Account" )
else
  exit 1 && echo "error in authorization with AWS"
fi

if [[ $bypass == 0 ]]; then
  echo "Is the account ID is: $ACCOUNT_ID"
  read -p "Continue? (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
else
  echo "================================================================="
  echo "Assuming that customer's account is: $ACCOUNT_ID"
fi

REGION=$(aws ssm get-parameter --region $REGION --name "/aft/account_custom_fields/main_region" --query "Parameter.Value" --output text | jq --raw-output) && echo "region is: "$REGION

if [[ $bypass == 0 ]]; then
  echo "The main region recorded in parameter store is: $REGION"
  read -p "Continue? (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
else
  echo "================================================================="
  echo "The main region recorded in parameter store is: $REGION"
fi

if [[ $bypass == 0 ]]; then
  echo "Environment name is: "$ENV_NAME
  read -p "Continue? (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
else
  echo "================================================================="
  echo "The environment name stored in paramter store is: "$ENV_NAME
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

EXIT=1
cd $SCRIPT_DIR/$ENV_NAME
cd parameters
terragrunt apply -auto-approve && echo "===========================applied parameters===========================" && EXIT=0
if [ $EXIT == 1 ]; then
  echo "parameters failed"
  exit 1
fi

EXIT=1
cd $SCRIPT_DIR/$ENV_NAME
cd security-groups-set
terragrunt init && terragrunt apply -auto-approve && echo "===========================applied security-groups-set===========================" && EXIT=0
if [ $EXIT == 1 ]; then
  echo "security-groups-set failed"
  exit 1
fi

EXIT=1
cd $SCRIPT_DIR/$ENV_NAME
cd efs
terragrunt apply -auto-approve && echo "===========================applied efs==================================" && EXIT=0
if [ $EXIT == 1 ]; then
  echo "parameters failed"
  exit 1
fi

EXIT=1
cd $SCRIPT_DIR/$ENV_NAME
cd prometheus
terragrunt apply -auto-approve && echo "===========================Prometheus===========================" && EXIT=0
if [ $EXIT == 1 ]; then
  echo "Prometheus failed"
  exit 1
fi


# this script creating ssh-key pair if not exists in parameter store go given user
# injecting it to parameter store of exists localy only or not exists at all
# injecting a private key secret to k8s cluster

if [[ $bypass == 0 ]]; then
  read -p "Secret injection phase, Continue? (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
else
  echo "================================================================="
  echo "Secret injection phase skipped"
fi

CUSTOMER_NAME=$(aws ssm get-parameter --region $REGION --name "/aft/account_custom_fields/customer_name" --query "Parameter.Value" --output text | jq --raw-output)

if [[ $bypass == 0 ]]; then
  echo "customer name is: "$CUSTOMER_NAME
  read -p "Continue? (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
else
  echo "================================================================="
  echo "Assuming that correct customer name is: "$CUSTOMER_NAME
fi

if [[ $bypass == 0 ]]; then
  aws eks update-kubeconfig --name "$CUSTOMER_NAME-$ENV_NAME" --region "$REGION"
  RETURN=$?
  if [[ RETURN==0 ]]; then
    echo "successfully configured eks kubectconfig"
  else 
    echo "error in eks kubeconfig"
    exit 1
  fi
fi

if [[ $bypass == 0 ]]; then
  #kubectl set context
  kubectl config use-context arn:aws:eks:$REGION:"$ACCOUNT_ID":cluster/$CUSTOMER_NAME-$ENV_NAME

  if [[ $(kubectl describe secrets/ops-ssh-keys) ]]; then
    echo "secret alredy exists in k8s cluster"
  else
    #check if private key exists in ssm parameter store
    PRIVATE_KEY=$(aws ssm get-parameter --region $REGION --name "/aft/bitbucket/ssh_private_key" --query "Parameter.Value" --output text --with-decrypt)
    if [[ $PRIVATE_KEY ]]; then
      echo "private key exists in parameter store, injecting the secret"
      kubectl create secret generic ops-ssh-keys --from-literal=ops-secret-key="$PRIVATE_KEY"
    else
      echo "ssh key doesn't exists in parameter store, creating it localy"
      PREFIX_PATH=~
      if [[ -f "$PREFIX_PATH/.ssh/$CUSTOMER_NAME/$CUSTOMER_NAME-$ENV_NAME-ops" ]]; then
        echo "ssh key-pair alredy exists localy"
      else
        mkdir -p ~/.ssh/$CUSTOMER_NAME
        echo "creating ssh key pair in ~/.ssh/$CUSTOMER_NAME/$CUSTOMER_NAME-$ENV_NAME-ops"
        ssh-keygen \
        -q \
        -t ecdsa \
        -N ''\
        -f ~/.ssh/$CUSTOMER_NAME/$CUSTOMER_NAME-$ENV_NAME-ops && echo "have create ssh-key pair in $PREFIX_PATH/.ssh/$CUSTOMER_NAME/$CUSTOMER_NAME-$ENV_NAME-ops"
      fi
      echo "uploading new ssh key-pair to parameter store"
      KEY_ID=$(aws ssm get-parameter --region $REGION --name /aft/$(aws ssm get-parameter --region $REGION --name "/aft/account_custom_fields/environment_name" --query "Parameter.Value" --output text | jq --raw-output)/kms/key_id | jq --raw-output ".Parameter.Value")
      aws ssm put-parameter --name "/aft/bitbucket/ssh_private_key" --value "$(cat $PREFIX_PATH/.ssh/$CUSTOMER_NAME/$CUSTOMER_NAME-$ENV_NAME-ops)" --type "SecureString" --key-id "$KEY_ID" --overwrite > /dev/null && echo "succefuly uploaded private key to parameter store" || echo "failed upload private key to parameter store"
      aws ssm put-parameter --name "/aft/bitbucket/ssh_public_key" --value "$(cat $PREFIX_PATH/.ssh/$CUSTOMER_NAME/$CUSTOMER_NAME-$ENV_NAME-ops.pub)" --type "SecureString" --key-id "$KEY_ID" --overwrite > /dev/null && echo "succefuly uploaded public key to parameter store" || echo "failed upload private key to parameter store"
      echo "injection of secret to k8s cluster"
      kubectl create secret generic ops-ssh-keys --from-file=ops-secret-key=$PREFIX_PATH/.ssh/$CUSTOMER_NAME/$CUSTOMER_NAME-$ENV_NAME-ops && echo "sucessfuly injected private ssh-key secret to k8s"
    fi
  fi
fi

if [[ $bypass == 0 ]]; then
  aws ssm get-parameter --region $REGION --name "/aft/bitbucket/ssh_public_key" --query "Parameter.Value" --output text --with-decryption | pbcopy
fi

if [[ $bypass == 0 ]]; then
  echo "please paste the public key (ALREADY IN YOUR CLIPBOARD) to bitbucket repository"
  read -p "Continue? (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
else
  echo "================================================================="
  echo "Assuming that you already added the public key to the bitbucket repository"
fi

if [[ $bypass == 0 ]]; then

  EXIT=1
  cd $SCRIPT_DIR/$ENV_NAME
  cd vault
  terragrunt apply -auto-approve && echo "===========================applied vault===========================" && EXIT=0
  if [ $EXIT == 1 ]; then
    echo "vault failed"
    exit 1
  fi
  sleep 10
  echo "=====================Init phase 2 - vault automation======================="
  #kubectl set context
  CUSTOMER_NAME=$(aws ssm get-parameter --region $REGION --name "/aft/account_custom_fields/customer_name" --query "Parameter.Value" --output text | jq --raw-output)
  kubectl config use-context arn:aws:eks:$REGION:"$ACCOUNT_ID":cluster/$CUSTOMER_NAME-$ENV_NAME

  while [[ "$(kubectl -n vault get pods | awk '{print $3}' | tail -n 3 | head -n 1)" -ne "Running" ]]; do sleep 5; echo "waiting for vault-0 pod to run"; done

  KEY_ID=$(aws ssm get-parameter --region $REGION --name /aft/$(aws ssm get-parameter --region $REGION --name "/aft/account_custom_fields/environment_name" --query "Parameter.Value" --output text | jq --raw-output)/kms/key_id | jq --raw-output ".Parameter.Value")

  #init vault and extract tookens
  VAULT_INIT=$(kubectl exec -i -t -n vault vault-0 -c vault "--" sh -c "vault operator init -format 'json'") 
  if [ $? == 0 ]; then
    echo "succefuly init vault"
    #parse and upload to parameter store
    for i in {0..4}; do
    aws ssm put-parameter\
      --region $REGION \
      --name "/aft/$ENV_NAME/vault/recovery_keys_b64_$i"\
      --value "$(echo $VAULT_INIT | jq --raw-output ".recovery_keys_b64[$i]")"\
      --type "SecureString"\
      --key-id "$KEY_ID"\
      --overwrite\
      > /dev/null \
      && echo "successfully uploaded recovery key $i to parameter store" \
      || echo "failed upload recovery key $i to parameter store"
    done
    aws ssm put-parameter\
      --region $REGION \
      --name "/aft/$ENV_NAME/vault/root_token"\
      --value "$(echo $VAULT_INIT | jq --raw-output ".root_token")"\
      --type "SecureString"\
      --key-id "$KEY_ID"\
      --overwrite\
      > /dev/null \
      && echo "successfully uploaded root token to parameter store" \
      || echo "failed upload private key to parameter store"

  else
    echo "init already have done"
  fi

  export VAULT_TOKEN=$(aws ssm get-parameter --region $REGION --name "/aft/$ENV_NAME/vault/root_token" --query "Parameter.Value" --output text --with-decrypt ) && echo "sucessfuly got root token from parameter store" || echo "failed get root token from parameter store"

  kubectl exec vault-1 -n vault \
  -- vault operator raft join http://vault-0.vault-internal:8200 \
  && echo "Successfully joined vault-1 to raft" \
  || echo "Unsuccessfully joined vault-1 to raft"

  pkill -f "port-forward" # Kill port forward
fi

EXIT=1
cd $SCRIPT_DIR/$ENV_NAME
cd vault-secrets
terragrunt apply -auto-approve && echo "===========================vault-secret===========================" && EXIT=0
if [ $EXIT == 1 ]; then
  echo "vault-secret failed"
  exit 1
fi

EXIT=1
cd $SCRIPT_DIR/$ENV_NAME
cd s3-archive
terragrunt run-all apply --terragrunt-ignore-external-dependencies && echo "===========================s3-archives===========================" && EXIT=0
if [ $EXIT == 1 ]; then
  echo "s3-archives failed"
  exit 1
fi
