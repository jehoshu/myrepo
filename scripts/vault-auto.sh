#!/bin/bash
set -euo pipefail

# Function to exit script on error
error_exit() {
  echo "$1"
  exit 1
}

# Function to Wait for Vault to be Running
wait_for_vault() {
  while [[ "$(kubectl -n vault get pods -l app.kubernetes.io/name=vault | awk '/vault-0/ {print $3}')" != "Running" ]]; do
    sleep 5
    echo "Debug: Waiting for vault-0 pod to run..."
  done
}

# Function to join Vault nodes to the cluster
join_raft_cluster() {
  for i in 1 2; do
    echo "Debug: Attempting to join vault-$i to cluster"
    kubectl exec vault-$i -n vault -- vault operator raft join http://vault-0.vault-internal:8200 >/dev/null 2>&1 \
    && echo "vault-$i successfully joined cluster" \
    || error_exit "vault-$i cluster join failed"
  done
}

# Function to Initialize Vault
init_vault() {
  echo "Debug: Initializing Vault..."
  # Fetch KEY_ID from SSM
  KEY_ID=$(aws ssm get-parameter --region $REGION --name /aft/$(aws ssm get-parameter --region $REGION --name "/aft/account_custom_fields/environment_name" --query "Parameter.Value" --output text | jq --raw-output)/kms/key_id | jq --raw-output ".Parameter.Value")
  echo "Debug: KEY_ID = $KEY_ID"

  IS_INITIALIZED=$(kubectl get pods -n vault -l component=server,statefulset.kubernetes.io/pod-name=vault-0 -o jsonpath='{.items[*].metadata.labels.vault-initialized}')
  echo "Debug: VAULT_STATUS = $IS_INITIALIZED"

  if [ "$IS_INITIALIZED" == "true" ]; then
    echo "Vault is already initialized, skipping further actions."
    exit 0
  else
    VAULT_INIT=$(kubectl exec -n vault vault-0 -c vault "--" sh -c "vault operator init -format='json'")
    echo "Debug: VAULT_INIT = $VAULT_INIT"
    for i in {0..4}; do
      aws ssm put-parameter \
      --region $REGION \
      --name "/aft/$ENV_NAME/$ENV_COLOR/vault/recovery_keys_b64_$i" \
      --value "$(echo $VAULT_INIT | jq --raw-output ".recovery_keys_b64[$i]")" \
      --type "SecureString" \
      --key-id "$KEY_ID" \
      --overwrite \
      && echo "Successfully uploaded recovery key $i to parameter store" \
      || error_exit "Failed to upload recovery key $i to parameter store"
    done
    
    aws ssm put-parameter \
    --region $REGION \
    --name "/aft/$ENV_NAME/$ENV_COLOR/vault/root_token" \
    --value "$(echo $VAULT_INIT | jq --raw-output ".root_token")" \
    --type "SecureString" \
    --key-id "$KEY_ID" \
    --overwrite \
    && echo "Successfully uploaded root token to parameter store" \
    || error_exit "Failed to upload root token to parameter store"
  fi
}

# Main Execution
main() {
  if [[ $# -ne 4 ]]; then
    error_exit "Usage: $0 REGION CUSTOMER_NAME ENV_NAME ENV_COLOR"
  fi

  REGION=$1
  CUSTOMER_NAME=$2
  ENV_NAME=$3
  ENV_COLOR=$4

  # Debug: Print Environment variables and other debug info
  echo "Debug Info:"
  echo "REGION: $REGION"
  echo "CUSTOMER_NAME: $CUSTOMER_NAME"
  echo "ENV_NAME: $ENV_NAME"
  echo "ENV_COLOR: $ENV_COLOR"

  # Debug: Updating kubeconfig
  echo "Debug: Updating kubeconfig..."
  aws eks update-kubeconfig --region "$REGION" --name "$CUSTOMER_NAME-$ENV_NAME-$ENV_COLOR"

  wait_for_vault
  init_vault
  join_raft_cluster
}

main "$@"