#!/bin/bash
set -euo pipefail

kind create cluster --config cluster.yml

MYSQL_NODES=$(kubectl get nodes -l app=mysql -o name || true)
if [[ -n "$MYSQL_NODES" ]]; then
  while IFS= read -r node; do
    echo " -> taint ${node#node/}"
    kubectl taint nodes "${node#node/}" app=mysql:NoSchedule --overwrite
  done <<< "$MYSQL_NODES"
else
  echo "No nodes with label app=mysql, skip."
fi

echo "[2/5] Deploying MySQL..."
kubectl apply -f .infrastructure/mysql/ns.yml
kubectl apply -f .infrastructure/mysql/configMap.yml
kubectl apply -f .infrastructure/mysql/secret.yml
kubectl apply -f .infrastructure/mysql/service.yml
kubectl apply -f .infrastructure/mysql/statefulSet.yml

echo "[3/5] Deploying todoapp..."
kubectl apply -f .infrastructure/app/ns.yml
kubectl apply -f .infrastructure/app/pv.yml
kubectl apply -f .infrastructure/app/pvc.yml
kubectl apply -f .infrastructure/app/secret.yml
kubectl apply -f .infrastructure/app/configMap.yml
kubectl apply -f .infrastructure/app/clusterIp.yml
kubectl apply -f .infrastructure/app/nodeport.yml
kubectl apply -f .infrastructure/app/hpa.yml
kubectl apply -f .infrastructure/app/deployment.yml

echo "[4/5] Install Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

echo "[5/5] Check rollout..."
kubectl rollout status statefulset/mysql -n mysql --timeout=3m || true
kubectl rollout status deployment/todoapp -n todoapp --timeout=3m || true
