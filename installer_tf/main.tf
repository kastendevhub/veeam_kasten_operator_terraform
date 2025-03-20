############################################################################################
// Create Kasten-IO Namespace
############################################################################################

resource "kubernetes_namespace" "kasten_io" {
  metadata {
    name = var.kasten_namespace
    
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "openshift.io/cluster-monitoring" = "true"
    }
  }
}

############################################################################################
// Wait for OpenShift OLM CRDs
############################################################################################
resource "null_resource" "wait_for_operator_crds" {
  depends_on = [kubernetes_namespace.kasten_io]
  
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOT
      echo "Waiting for Operator Lifecycle Manager CRDs to be available..."
      
      # Wait for OperatorGroup CRD
      for i in {1..20}; do
        if oc get crd operatorgroups.operators.coreos.com &>/dev/null; then
          echo "OperatorGroup CRD found!"
          break
        fi
        echo "Waiting for OperatorGroup CRD... ($i/20)"
        sleep 10
        if [ $i -eq 20 ]; then
          echo "Warning: OperatorGroup CRD not found. Continuing anyway, but this may cause errors."
        fi
      done
      
      # Wait for Subscription CRD
      for i in {1..20}; do
        if oc get crd subscriptions.operators.coreos.com &>/dev/null; then
          echo "Subscription CRD found!"
          break
        fi
        echo "Waiting for Subscription CRD... ($i/20)"
        sleep 10
        if [ $i -eq 20 ]; then
          echo "Warning: Subscription CRD not found. Continuing anyway, but this may cause errors."
        fi
      done
    EOT
  }
}

############################################################################################
// Create EBS IO2 StorageClass
############################################################################################

# First, remove the default annotation from any existing default StorageClass
resource "null_resource" "remove_default_annotation" {
  provisioner "local-exec" {
    command = <<-EOT
      # Get current default StorageClass
      DEFAULT_SC=$(kubectl get sc -o=jsonpath='{.items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")].metadata.name}')
      
      if [ ! -z "$DEFAULT_SC" ]; then
        echo "Removing default annotation from StorageClass $DEFAULT_SC"
        kubectl patch storageclass $DEFAULT_SC -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "false"}}}'
      else
        echo "No default StorageClass found"
      fi
    EOT
  }
}

# Then create the IO2 StorageClass
resource "kubernetes_storage_class" "ebs_io2_storageclass" {
  depends_on = [null_resource.remove_default_annotation]

  metadata {
    name = "ebs-csi-io2"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true" //Set the io2 storage class as default
      "k10.kasten.io/sc-supports-block-mode-exports" = "true" //Enable block mode exports
      "k10.kasten.io/is-snapshot-class" = "csi-aws-vsc" //Enable snapshot class
    }
  }

  storage_provisioner = "ebs.csi.aws.com"
  volume_binding_mode = "WaitForFirstConsumer"
  parameters = {
    type = "io2"
    iops = "4000"
  }
}

############################################################################################
// Create CSI VolumeSnapshotClass
############################################################################################

# First check if the VolumeSnapshotClass already exists
resource "null_resource" "check_volumesnapshotclass" {
  depends_on = [kubernetes_storage_class.ebs_io2_storageclass]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Checking if VolumeSnapshotClass csi-aws-vsc already exists..."
      
      if kubectl get volumesnapshotclass csi-aws-vsc &>/dev/null; then
        echo "VolumeSnapshotClass csi-aws-vsc already exists. Importing it into Terraform state..."
        # Create a temporary file for the resource definition
        cat <<EOF > /tmp/vsc.yaml
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshotClass
metadata:
  name: csi-aws-vsc
  annotations:
    k10.kasten.io/is-snapshot-class: "true"
driver: ebs.csi.aws.com
deletionPolicy: Delete
EOF
        
        echo "VSC_EXISTS=true" > /tmp/vsc_status.txt
      else
        echo "VolumeSnapshotClass csi-aws-vsc does not exist."
        echo "VSC_EXISTS=false" > /tmp/vsc_status.txt
      fi
    EOT
  }
}

# Create VolumeSnapshotClass only if it doesn't exist
resource "null_resource" "create_volumesnapshotclass" {
  depends_on = [null_resource.check_volumesnapshotclass]

  provisioner "local-exec" {
    command = <<-EOT
      # Read the status file
      source /tmp/vsc_status.txt
      
      if [ "$VSC_EXISTS" = "false" ]; then
        echo "Creating VolumeSnapshotClass csi-aws-vsc..."
        cat <<EOF | kubectl apply -f -
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshotClass
metadata:
  name: csi-aws-vsc
  annotations:
    k10.kasten.io/is-snapshot-class: "true"
driver: ebs.csi.aws.com
deletionPolicy: Delete
EOF
        echo "VolumeSnapshotClass csi-aws-vsc created successfully."
      else
        echo "Skipping VolumeSnapshotClass creation as it already exists."
      fi
    EOT
  }
}

resource "null_resource" "cleanup_volumesnapshotclass" {
  depends_on = [null_resource.create_volumesnapshotclass]
  triggers = {
    vsc_name = "csi-aws-vsc"
  }

  # This only runs during terraform destroy
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "Cleaning up VolumeSnapshotClass ${self.triggers.vsc_name}..."
      
      # Remove finalizers from the VolumeSnapshotClass if they exist
      if kubectl get volumesnapshotclass ${self.triggers.vsc_name} &>/dev/null; then
        echo "Removing finalizers from VolumeSnapshotClass..."
        kubectl patch volumesnapshotclass ${self.triggers.vsc_name} --type=json -p='[{"op": "remove", "path": "/metadata/finalizers"}]' || true
        
        # Force delete if necessary
        kubectl delete volumesnapshotclass ${self.triggers.vsc_name} --timeout=60s --wait=false || true
        
        # Wait for it to be gone
        echo "Waiting for VolumeSnapshotClass to be deleted..."
        for i in {1..30}; do
          if ! kubectl get volumesnapshotclass ${self.triggers.vsc_name} &>/dev/null; then
            echo "VolumeSnapshotClass deleted successfully."
            break
          fi
          echo "Still waiting for deletion... (attempt $i/30)"
          sleep 5
        done
      else
        echo "VolumeSnapshotClass ${self.triggers.vsc_name} not found, skipping cleanup"
      fi
    EOT
  }
}

############################################################################################
// Create Kasten Operator Subscription
############################################################################################

# Create the OperatorGroup using oc apply instead of kubectl_manifest
resource "null_resource" "kasten_operator_group" {
  depends_on = [kubernetes_namespace.kasten_io, null_resource.wait_for_operator_crds]
  
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOT
      echo "Creating Kasten operator group..."
      cat <<EOF | oc apply -f -
      apiVersion: operators.coreos.com/v1
      kind: OperatorGroup
      metadata:
        name: kasten-operator-group
        namespace: ${var.kasten_namespace}
      spec:
        targetNamespaces:
        - ${var.kasten_namespace}
      EOF
      
      # Verify it was created
      echo "Verifying operator group creation..."
      oc get operatorgroup kasten-operator-group -n ${var.kasten_namespace} -o yaml
    EOT
  }
}

# Create the Subscription using oc apply 
resource "null_resource" "kasten_subscription" {
  depends_on = [null_resource.kasten_operator_group]
  
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOT
      echo "Creating Kasten operator subscription..."
      cat <<EOF | oc apply -f -
      apiVersion: operators.coreos.com/v1alpha1
      kind: Subscription
      metadata:
        name: kasten-operator
        namespace: ${var.kasten_namespace}
        labels:
          operators.coreos.com/${var.kasten_operator_name}.${var.kasten_namespace}: ""
      spec:
        channel: ${var.channel}
        installPlanApproval: ${var.installPlanApproval}
        name: ${var.kasten_operator_name}
        source: ${var.source_catalog}
        sourceNamespace: ${var.sourceNamespace}
        startingCSV: ${var.startingCSV}
      EOF
      
      # Verify it was created and wait for it to begin installing
      echo "Verifying subscription creation and waiting for installation to start..."
      for i in {1..10}; do
        SUB_STATUS=$(oc get subscription kasten-operator -n ${var.kasten_namespace} -o jsonpath='{.status.state}' 2>/dev/null)
        if [[ "$SUB_STATUS" == "AtLatestKnown" || "$SUB_STATUS" == "UpgradePending" ]]; then
          echo "Subscription is being processed: $SUB_STATUS"
          break
        fi
        echo "Waiting for subscription to be processed... ($i/10)"
        sleep 10
      done
    EOT
  }
}

############################################################################################
// Wait for Kasten operator to be ready and for K10 CRD to be available
############################################################################################
resource "null_resource" "wait_for_k10_crds" {
  depends_on = [null_resource.kasten_subscription]
  
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOT
      echo "Waiting for Kasten K10 operator to be ready..."
      
      # Wait for the CSV to be successfully installed
      for i in {1..30}; do
        CSV=$(oc get subscription kasten-operator -n ${var.kasten_namespace} -o jsonpath='{.status.installedCSV}' 2>/dev/null)
        if [[ ! -z "$CSV" ]]; then
          STATUS=$(oc get csv $CSV -n ${var.kasten_namespace} -o jsonpath='{.status.phase}' 2>/dev/null)
          if [[ "$STATUS" == "Succeeded" ]]; then
            echo "Kasten operator is ready! CSV: $CSV"
            break
          fi
        fi
        echo "Waiting for Kasten operator to be ready... ($i/30)"
        sleep 10
        
        if [[ $i -eq 30 ]]; then
          echo "WARNING: Timeout waiting for Kasten operator. Current status:"
          oc get subscription kasten-operator -n ${var.kasten_namespace} -o yaml
          oc get csv -n ${var.kasten_namespace}
        fi
      done
      
      # Wait for the K10 CRD to be available
      echo "Waiting for K10 CRD to be available..."
      for i in {1..30}; do
        if oc get crd k10s.apik10.kasten.io &>/dev/null; then
          echo "K10 CRD is available!"
          break
        fi
        echo "Waiting for K10 CRD... ($i/30)"
        sleep 10
        
        if [[ $i -eq 30 ]]; then
          echo "WARNING: Timeout waiting for K10 CRD. Current available CRDs:"
          oc get crd | grep -i kasten
        fi
      done
    EOT
  }
}

############################################################################################
// Create Service Accounts required for K10 
############################################################################################

# Create required service accounts before K10 instance creation
resource "kubernetes_service_account" "k10_service_accounts" {
  depends_on = [null_resource.kasten_subscription]
  
  for_each = toset([
    "k10-k10",
    "k10-metering",
    "k10-config",
    "k10-jobs",
    "k10-aggregatedapis"
  ])
  
  metadata {
    name = each.key
    namespace = "kasten-io"
    labels = {
      "app.kubernetes.io/name" = "k10"
      "app.kubernetes.io/instance" = "k10"
      "app.kubernetes.io/managed-by" = "Helm"
      "app" = "k10"
      "release" = "k10"
    }
    annotations = {
      "meta.helm.sh/release-name" = "k10"
      "meta.helm.sh/release-namespace" = "kasten-io"
    }
  }
}

# Add OpenShift SCC permissions to the service accounts
resource "null_resource" "apply_scc_to_accounts" {
  depends_on = [kubernetes_service_account.k10_service_accounts]
  
  provisioner "local-exec" {
    command = <<-EOT
      echo "Applying OpenShift SCC permissions to K10 service accounts..."
      
      # Apply anyuid SCC to all service accounts
      oc adm policy add-scc-to-user anyuid -z k10-k10 -n kasten-io
      oc adm policy add-scc-to-user anyuid -z k10-metering -n kasten-io
      oc adm policy add-scc-to-user anyuid -z k10-config -n kasten-io
      oc adm policy add-scc-to-user anyuid -z k10-jobs -n kasten-io
      oc adm policy add-scc-to-user anyuid -z k10-aggregatedapis -n kasten-io
      
      # Apply privileged SCC to k10-k10
      oc adm policy add-scc-to-user privileged -z k10-k10 -n kasten-io
      
      echo "SCC permissions applied successfully"
    EOT
  }
}

############################################################################################
// Create ClusterRoleBindings for K10
############################################################################################

resource "kubernetes_cluster_role_binding" "k10_k10_cluster_admin" {
  depends_on = [kubernetes_service_account.k10_service_accounts]
  
  metadata {
    name = "kasten-io-k10-k10-cluster-admin"
    labels = {
      "app.kubernetes.io/name" = "k10"
      "app.kubernetes.io/instance" = "k10"
      "app.kubernetes.io/managed-by" = "Helm"
      "app" = "k10"
      "release" = "k10"
    }
    annotations = {
      "meta.helm.sh/release-name" = "k10"
      "meta.helm.sh/release-namespace" = "kasten-io"
    }
  }
  
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "ClusterRole"
    name = "cluster-admin"
  }
  
  subject {
    kind = "ServiceAccount"
    name = "k10-k10"
    namespace = "kasten-io"
  }
}

resource "kubernetes_cluster_role_binding" "k10_metering_cluster_admin" {
  depends_on = [kubernetes_service_account.k10_service_accounts]
  
  metadata {
    name = "kasten-io-k10-metering-cluster-admin"
    labels = {
      "app.kubernetes.io/name" = "k10"
      "app.kubernetes.io/instance" = "k10"
      "app.kubernetes.io/managed-by" = "Helm"
      "app" = "k10"
      "release" = "k10"
    }
    annotations = {
      "meta.helm.sh/release-name" = "k10"
      "meta.helm.sh/release-namespace" = "kasten-io"
    }
  }
  
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "ClusterRole"
    name = "cluster-admin"
  }
  
  subject {
    kind = "ServiceAccount"
    name = "k10-metering"
    namespace = "kasten-io"
  }
}

############################################################################################
// Create K10 Instance using kubectl_manifest
############################################################################################

# Get the OpenShift cluster domain
data "external" "cluster_domain" {
  program = ["bash", "-c", "echo '{\"domain\": \"'$(oc get ingress.config.openshift.io cluster -o jsonpath='{.spec.domain}')'\"}'"]
}

resource "kubectl_manifest" "k10_instance" {
  depends_on = [
    null_resource.kasten_subscription,
    null_resource.create_volumesnapshotclass,
    kubernetes_service_account.k10_service_accounts,
    null_resource.apply_scc_to_accounts,
    kubernetes_cluster_role_binding.k10_k10_cluster_admin,
    kubernetes_cluster_role_binding.k10_metering_cluster_admin
  ]
  
  yaml_body = <<YAML
apiVersion: apik10.kasten.io/v1alpha1
kind: K10
metadata:
  name: k10
  namespace: kasten-io
  annotations:
    helm.sdk.operatorframework.io/reconcile-period: "2m"
    helm.sdk.operatorframework.io/rollback-force: "false"
spec:
  auth:
    basicAuth:
      enabled: false
    tokenAuth:
      enabled: true
  global:
    persistence:
      storageClass: "ebs-csi-io2"
      metering:
        enabled: true
        storageClass: "ebs-csi-io2"
        size: "4Gi"
  route:
    enabled: true
    host: ""
    newHostName: "k10.apps.${data.external.cluster_domain.result.domain}"
    path: "/k10/"
    tls:
      enabled: true
      termination: "edge"
      insecureEdgeTerminationPolicy: "Redirect"
YAML

  # Add proper server-side apply to handle CRD not being available during planning
  server_side_apply = true
  force_conflicts = true
  wait = true
  wait_for_rollout = false
}

############################################################################################
// Create AWS Infrastructure Profile for K10
############################################################################################
resource "null_resource" "create_aws_infrastructure_profile" {
  depends_on = [kubectl_manifest.k10_instance]
  
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOT
      echo "Waiting for K10 platform to be fully ready before creating AWS profile..."
      
      # Wait for K10 to be fully ready
      for i in {1..20}; do
        STATUS=$(kubectl get k10 k10 -n ${var.kasten_namespace} -o jsonpath='{.status.phase}' 2>/dev/null)
        READY_CONDITION=$(kubectl get k10 k10 -n ${var.kasten_namespace} -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
        
        if [[ "$STATUS" == "Running" && "$READY_CONDITION" == "True" ]]; then
          echo "K10 platform is ready!"
          break
        fi
        echo "Waiting for K10 platform to be ready... ($i/20)"
        sleep 10
        
        if [ $i -eq 20 ]; then
          echo "WARNING: K10 platform not fully ready within timeout. Will attempt to create profile anyway."
          kubectl get k10 k10 -n ${var.kasten_namespace} -o yaml
        fi
      done
      
      # Wait additional time for API server to be fully operational
      echo "Waiting additional time for K10 API to stabilize..."
      sleep 30
      
      # First, extract AWS credentials from local AWS CLI configuration
      echo "Extracting AWS credentials from local AWS profile..."
      AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id)
      AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key)
      AWS_REGION=$(aws configure get region)
      
      if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
        echo "ERROR: Could not retrieve AWS credentials from AWS CLI configuration."
        echo "Please run 'aws configure' to set up your AWS credentials first."
        exit 1
      fi
      
      echo "Creating Kubernetes secret for AWS credentials..."
      # Create a fixed name with timestamp to avoid conflicts
      SECRET_NAME="k10aws-$(date +%s)"
      
      # Create the secret with AWS credentials
      cat <<EOF | kubectl apply -f -
      apiVersion: v1
      kind: Secret
      metadata:
        name: $SECRET_NAME
        namespace: ${var.kasten_namespace}
      type: Opaque
      stringData:
        aws_access_key_id: "$AWS_ACCESS_KEY_ID"
        aws_secret_access_key: "$AWS_SECRET_ACCESS_KEY"
        aws_region: "$AWS_REGION"
      EOF
      
      echo "Secret $SECRET_NAME created. Now creating AWS infrastructure profile..."
      
      # Save profile to file first for easy debugging
      cat > /tmp/aws-profile.yaml <<EOF
      apiVersion: config.kio.kasten.io/v1alpha1
      kind: Profile
      metadata:
        name: aws
        namespace: ${var.kasten_namespace}
      spec:
        type: Infra
        infra:
          type: AWS
          credential:
            secretType: AwsAccessKey
            secret:
              apiVersion: v1
              kind: Secret
              name: $SECRET_NAME
              namespace: ${var.kasten_namespace}
          aws:
            hasAccessForEBS: true
            hasAccessForEFS: true
            disableEBSDirectForBlockMode: true
      EOF
      
      # Apply the profile
      kubectl apply -f /tmp/aws-profile.yaml
      
      # Check if profile was created
      if ! kubectl get profile aws -n ${var.kasten_namespace} &>/dev/null; then
        echo "ERROR: Failed to create AWS profile. Please check K10 logs for more information."
        echo "Attempting to create using alternative method..."
        
        # Try using k10 CLI if available
        if command -v k10 &>/dev/null; then
          echo "Using k10 CLI to create profile..."
          k10 create profile infra --name aws --namespace ${var.kasten_namespace} \
            --aws-access-key "$AWS_ACCESS_KEY_ID" \
            --aws-secret-key "$AWS_SECRET_ACCESS_KEY" \
            --aws-region "$AWS_REGION"
        fi
      fi
      
      echo "Waiting for AWS infrastructure profile to be validated..."
      for i in {1..30}; do
        if ! kubectl get profile aws -n ${var.kasten_namespace} &>/dev/null; then
          echo "Profile does not exist yet. Waiting... ($i/30)"
          sleep 10
          continue
        fi
        
        VALIDATION=$(kubectl get profile aws -n ${var.kasten_namespace} -o jsonpath='{.status.validation}' 2>/dev/null)
        if [ "$VALIDATION" == "Success" ]; then
          echo "AWS infrastructure profile validation successful!"
          kubectl get profile aws -n ${var.kasten_namespace} -o yaml
          echo "======================="
          echo "AWS profile created and validated successfully."
          echo "If it's not visible in the K10 dashboard, try refreshing the page."
          echo "======================="
          break
        fi
        echo "Waiting for profile validation... ($i/30)"
        sleep 10
        
        if [ $i -eq 30 ]; then
          echo "Warning: Timeout waiting for profile validation. Current status:"
          kubectl get profile aws -n ${var.kasten_namespace} -o yaml
          echo "Check K10 logs for more information:"
          kubectl logs -n ${var.kasten_namespace} -l app=k10,component=jobs --tail=100
        fi
      done
      
      # Verify profile is listed in K10's internal storage
      echo "Verifying profile is listed in K10 profiles..."
      if kubectl exec -it -n ${var.kasten_namespace} deploy/catalog -- curl -s http://localhost:8000/profiles | grep -q "aws"; then
        echo "Profile 'aws' is found in K10's catalog service!"
      else
        echo "WARNING: Profile 'aws' not found in K10's internal catalog. This may indicate an issue."
        echo "Available profiles in K10 catalog:"
        kubectl exec -it -n ${var.kasten_namespace} deploy/catalog -- curl -s http://localhost:8000/profiles || echo "Unable to query K10 catalog"
      fi
    EOT
  }
}

