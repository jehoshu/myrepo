#!/bin/sh
aws eks update-kubeconfig --region "$1" --name "$3-$4-$5" > /dev/null 2>&1
kubectl --context arn:aws:eks:$1:$2:cluster/$3-$4-$5 -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo