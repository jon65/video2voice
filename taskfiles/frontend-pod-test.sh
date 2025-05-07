#!/bin/bash

set -e

NAMESPACE="dev"
LABEL_SELECTOR="app=frontend"
SERVICE_NAME="frontend-service"

echo "🔍 Checking pods with label '$LABEL_SELECTOR' in namespace '$NAMESPACE'..."

# Wait for pods to be ready
kubectl wait --for=condition=ready pod -l "$LABEL_SELECTOR" -n "$NAMESPACE" --timeout=60s

echo "✅ Pods are ready."

# Check for the service and get NodePort (or fall back to port-forwarding if NodePort not available)
NODE_PORT=$(kubectl get svc "$SERVICE_NAME" -n "$NAMESPACE" -o=jsonpath='{.spec.ports[0].nodePort}')
CLUSTER_IP=$(kubectl get svc "$SERVICE_NAME" -n "$NAMESPACE" -o=jsonpath='{.spec.clusterIP}')

if [ -z "$NODE_PORT" ] && [ -z "$CLUSTER_IP" ]; then
  echo "❌ Could not find a valid NodePort or ClusterIP for the service. Is the service running?"
  exit 1
fi

# If NodePort is available, use it to test externally
if [ -n "$NODE_PORT" ]; then
  NODE_IP=$(kubectl get nodes -o=jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
  echo "🌐 Testing HTTP response from http://$NODE_IP:$NODE_PORT"
  
  RESPONSE=$(curl -s --max-time 5 "http://$NODE_IP:$NODE_PORT")
  
  if [[ $RESPONSE == *"Welcome"* || $RESPONSE == *"nginx"* ]]; then
    echo "✅ Frontend is serving HTTP successfully on http://$NODE_IP:$NODE_PORT!"
  else
    echo "❌ Frontend is not responding as expected on $NODE_IP:$NODE_PORT."
    exit 1
  fi
else
  # Fallback to port-forward if NodePort is not available
  echo "⚠️ NodePort is not available. Using port-forwarding for local testing..."

  kubectl port-forward svc/$SERVICE_NAME 8080:80 -n "$NAMESPACE" &
  PORT_FORWARD_PID=$!
  sleep 3  # Wait for port-forward to establish

  echo "🌐 Testing HTTP response from http://localhost:8080"
  RESPONSE=$(curl -s --max-time 5 "http://localhost:8080")

  if [[ $RESPONSE == *"Welcome"* || $RESPONSE == *"nginx"* ]]; then
    echo "✅ Frontend is serving HTTP successfully via port-forward on http://localhost:8080!"
  else
    echo "❌ Frontend is not responding as expected on http://localhost:8080."
    exit 1
  fi

  # Kill port-forward after testing
  kill $PORT_FORWARD_PID
fi
