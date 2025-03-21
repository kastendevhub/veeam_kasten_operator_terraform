#!/bin/bash
# K10 Kasten namespace cleanup script
# This script will remove finalizers and clean up resources to unstick a terminating namespace

set -e

NAMESPACE="kasten-io"
echo "====== Kasten K10 Cleanup Script ======"
echo "This script will clean up Kasten K10 resources in namespace $NAMESPACE"

# Check if namespace exists
if ! oc get namespace $NAMESPACE &>/dev/null; then
  echo "Namespace $NAMESPACE does not exist. Nothing to clean up."
  exit 0
fi

# Check if namespace is terminating
PHASE=$(oc get namespace $NAMESPACE -o jsonpath='{.status.phase}' 2>/dev/null)
if [[ "$PHASE" != "Terminating" ]]; then
  echo "Namespace $NAMESPACE is not in terminating state. Current phase: $PHASE"
  echo "Do you want to proceed with cleanup anyway? (y/n)"
  read -r PROCEED
  if [[ "$PROCEED" != "y" ]]; then
    echo "Cleanup aborted."
    exit 0
  fi
fi

# 1. Remove K10 instance first
echo "Removing K10 resources..."
if oc get k10 -n $NAMESPACE &>/dev/null; then
  echo "Deleting K10 instances..."
  oc delete k10 --all -n $NAMESPACE --timeout=60s || true
  
  # Wait for initial deletion to start
  sleep 10
  
  # Force remove finalizers from K10
  if oc get k10 -n $NAMESPACE &>/dev/null; then
    echo "Force removing finalizers from K10..."
    for k10 in $(oc get k10 -n $NAMESPACE -o name); do
      oc patch $k10 -n $NAMESPACE --type="json" -p '[{"op":"remove","path":"/metadata/finalizers"}]' || true
    done
  fi
fi

# 2. Remove profiles
echo "Removing profiles..."
if oc get profiles.config.kio.kasten.io -n $NAMESPACE &>/dev/null; then
  oc delete profiles.config.kio.kasten.io --all -n $NAMESPACE || true
  
  # Force remove finalizers
  for profile in $(oc get profiles.config.kio.kasten.io -n $NAMESPACE -o name 2>/dev/null || true); do
    echo "Removing finalizers from $profile"
    oc patch $profile -n $NAMESPACE --type="json" -p '[{"op":"remove","path":"/metadata/finalizers"}]' 2>/dev/null || true
  done
fi

# 3. Remove all other Kasten custom resources
for crd in $(oc get crd | grep -E 'kasten.io|k10' | awk '{print $1}'); do
  echo "Checking CRD: $crd..."
  if oc get $crd -n $NAMESPACE &>/dev/null; then
    echo "Deleting resources for $crd..."
    oc delete $crd --all -n $NAMESPACE || true
    
    # Force remove finalizers
    for res in $(oc get $crd -n $NAMESPACE -o name 2>/dev/null || true); do
      echo "Removing finalizers from $res"
      oc patch $res -n $NAMESPACE --type="json" -p '[{"op":"remove","path":"/metadata/finalizers"}]' 2>/dev/null || true
    done
  fi
done

# 4. Remove subscription
echo "Removing K10 operator subscription..."
oc delete subscription -l app=k10 -n $NAMESPACE || true
oc delete subscription --all -n $NAMESPACE || true

# 5. Remove CSV
echo "Removing ClusterServiceVersion..."
oc delete csv --all -n $NAMESPACE || true

# 6. Force delete all deployments
echo "Removing deployments..."
oc delete deployment --all -n $NAMESPACE --timeout=30s || true

# 7. Force delete all statefulsets
echo "Removing statefulsets..."
oc delete statefulset --all -n $NAMESPACE --timeout=30s || true

# 8. Force delete all pods
echo "Force deleting pods..."
for pod in $(oc get pods -n $NAMESPACE -o name 2>/dev/null); do
  echo "Deleting pod $pod"
  oc delete $pod -n $NAMESPACE --force --grace-period=0 || true
done

# 9. Delete any PVCs that might be blocking
echo "Removing persistent volume claims..."
for pvc in $(oc get pvc -n $NAMESPACE -o name 2>/dev/null); do
  echo "Deleting PVC $pvc"
  oc delete $pvc -n $NAMESPACE --force --grace-period=0 || true
done

# 10. Clean up all resources with finalizers
echo "Cleaning up all resources with finalizers..."
for resource in $(oc api-resources --verbs=list --namespaced -o name 2>/dev/null | grep -v "events" | sort | uniq); do
  echo "Checking resource type: $resource"
  if ! oc get $resource -n $NAMESPACE &>/dev/null; then
    continue
  fi
  
  oc get $resource -n $NAMESPACE -o name 2>/dev/null | while read object; do
    if [[ ! -z "$object" ]]; then
      echo "Removing finalizers from $object"
      oc patch $object -n $NAMESPACE --type="json" -p '[{"op":"remove","path":"/metadata/finalizers"}]' 2>/dev/null || true
    fi
  done
done

# 11. Check for cluster-scoped resources that might be blocking namespace deletion
echo "Checking for cluster-scoped resources that might be blocking namespace deletion..."
for clusterres in clusterroles clusterrolebindings; do
  echo "Looking for $clusterres referencing the namespace..."
  for res in $(oc get $clusterres -o name | grep -E "k10|kasten"); do
    echo "Removing $res..."
    oc delete $res --ignore-not-found || true
  done
done

# 12. Force remove namespace finalizer
if oc get namespace $NAMESPACE &>/dev/null; then
  echo "Force removing namespace finalizer..."
  kubectl get namespace $NAMESPACE -o json | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/" | kubectl replace --raw /api/v1/namespaces/$NAMESPACE/finalize -f - || true
fi

# 13. If the above method doesn't work, try the jq method
if oc get namespace $NAMESPACE &>/dev/null; then
  echo "Trying alternative method to remove namespace finalizer..."
  kubectl get namespace $NAMESPACE -o json | jq '.spec.finalizers = []' | kubectl replace --raw "/api/v1/namespaces/$NAMESPACE/finalize" -f - || true
fi

echo "Kasten K10 cleanup completed!"
echo "If namespace is still terminating, you may need to restart the Kubernetes API server or contact your cluster administrator."