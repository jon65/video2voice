#!/bin/bash

set -e

NAMESPACE="dev"
LABEL_SELECTOR="app=frontend"
SERVICE_NAME="frontend-service"

echo "🔍 Checking pods with label '$LABEL_SELECTOR' in namespace '$NAMESPACE'..."

kubectl wait --for=condition=ready pod -l "$LABEL_SELECTOR" -n "$NAMESPACE" --timeout=60s

echo "✅ Pods are ready."

NODE_PORT=$(kubectl get svc "$SERVICE_NAME" -n "$NAMESPACE" -o=jsonpath='{.spec.ports[0].nodePort}')
NODE_IP=$(kubectl get nodes -o=jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

if [ -z "$NODE_PORT" ] || [ -z "$NODE_IP" ]; then
  echo "❌ Could not determine Node IP or NodePort. Is the service running?"
  exit 1
fi

echo "🌐 Testing HTTP response from http://$NODE_IP:$NODE_PORT"

RESPONSE=$(curl -s --max-time 5 "http://$NODE_IP:$NODE_PORT")

if [[ $RESPONSE == *"Welcome"* || $RESPONSE == *"nginx"* ]]; then
  echo "✅ Frontend is serving HTTP successfully!"
else
  echo "❌ Frontend is not responding as expected."
  exit 1
fi


