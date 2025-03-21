#!/bin/bash
set -e

NAMESPACE="open-cluster-management"
echo "====== ACM Cleanup Script ======"
echo "This script will clean up ACM resources in namespace $NAMESPACE"

# 1. Remove MultiClusterHub
echo "Removing MultiClusterHub resources..."
if oc get multiclusterhub -n $NAMESPACE &>/dev/null; then
  echo "Deleting MultiClusterHub..."
  oc delete multiclusterhub --all -n $NAMESPACE --timeout=60s || true
  
  # Wait for initial deletion to start
  sleep 10
  
  # Force remove finalizers
  if oc get multiclusterhub -n $NAMESPACE &>/dev/null; then
    echo "Force removing finalizers from MultiClusterHub..."
    for mch in $(oc get multiclusterhub -n $NAMESPACE -o name); do
      oc patch $mch -n $NAMESPACE --type="json" -p '[{"op":"remove","path":"/metadata/finalizers"}]' || true
    done
  fi
fi

# 2. Remove subscription
echo "Removing subscriptions..."
oc delete subscription --all -n $NAMESPACE || true

# 3. Remove CSV
echo "Removing ClusterServiceVersion..."
oc delete csv --all -n $NAMESPACE || true

# 4. Force delete pods
echo "Force deleting pods..."
for pod in $(oc get pods -n $NAMESPACE -o name 2>/dev/null); do
  oc delete $pod -n $NAMESPACE --force --grace-period=0 || true
done

# 5. Clean up all other resources
echo "Cleaning up all resources with finalizers..."
for resource in $(oc api-resources --verbs=list --namespaced -o name 2>/dev/null | grep -v "events" | sort | uniq); do
  echo "Checking resource type: $resource"
  oc get $resource -n $NAMESPACE -o name 2>/dev/null | while read object; do
    if [[ ! -z "$object" ]]; then
      echo "Removing finalizers from $object"
      oc patch $object -n $NAMESPACE --type="json" -p '[{"op":"remove","path":"/metadata/finalizers"}]' 2>/dev/null || true
    fi
  done
done

# 6. Force remove namespace finalizer
if oc get namespace $NAMESPACE &>/dev/null; then
  echo "Force removing namespace finalizer..."
  kubectl get namespace $NAMESPACE -o json | jq '.spec.finalizers = []' | kubectl replace --raw "/api/v1/namespaces/$NAMESPACE/finalize" -f - || true
fi

echo "ACM cleanup completed!"
EOF