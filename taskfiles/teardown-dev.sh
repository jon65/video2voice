#!/bin/bash

NAMESPACE="dev"

echo "🔄 Tearing down all resources in namespace: $NAMESPACE..."

# Delete all standard resources
kubectl delete all --all -n "$NAMESPACE" --ignore-not-found

# Delete PVCs
kubectl delete pvc --all -n "$NAMESPACE" --ignore-not-found

# Delete ConfigMaps, Secrets, and other non-"all" resources
kubectl delete configmap --all -n "$NAMESPACE" --ignore-not-found
kubectl delete secret --all -n "$NAMESPACE" --ignore-not-found
kubectl delete ingress --all -n "$NAMESPACE" --ignore-not-found
kubectl delete job --all -n "$NAMESPACE" --ignore-not-found
kubectl delete cronjob --all -n "$NAMESPACE" --ignore-not-found
kubectl delete hpa --all -n "$NAMESPACE" --ignore-not-found
kubectl delete serviceaccount --all -n "$NAMESPACE" --ignore-not-found

echo "✅ Teardown complete for namespace: $NAMESPACE"
