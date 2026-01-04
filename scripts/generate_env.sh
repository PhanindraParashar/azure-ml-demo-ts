#!/usr/bin/env bash
set -euo pipefail

# Repo root is the parent of this script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

INFRA_DIR="${REPO_ROOT}/infra"
ENV_FILE="${REPO_ROOT}/.env"

if [ ! -d "${INFRA_DIR}" ]; then
  echo "ERROR: infra/ directory not found at: ${INFRA_DIR}"
  exit 1
fi

cd "${INFRA_DIR}"
terraform init -input=false >/dev/null

# Required outputs (must exist in infra/outputs.tf)
SUB_ID="$(terraform output -raw subscription_id 2>/dev/null || true)"
RG="$(terraform output -raw resource_group_name 2>/dev/null || true)"
WS="$(terraform output -raw aml_workspace_name 2>/dev/null || true)"
LOC="$(terraform output -raw location 2>/dev/null || true)"

# Optional Synapse outputs
ADLS="$(terraform output -raw synapse_datalake_account_name 2>/dev/null || true)"
FS="$(terraform output -raw synapse_filesystem 2>/dev/null || true)"
SQL_LOGIN="$(terraform output -raw synapse_sql_admin_login 2>/dev/null || true)"

# Optional AML compute cluster outputs
COMPUTE_CLUSTER_NAME="$(terraform output -raw aml_compute_cluster_name 2>/dev/null || echo "")"
COMPUTE_CLUSTER_VM_SIZE="$(terraform output -raw aml_compute_cluster_vm_size 2>/dev/null || echo "")"
COMPUTE_CLUSTER_MIN_NODES="$(terraform output -raw aml_compute_cluster_min_nodes 2>/dev/null || echo "")"
COMPUTE_CLUSTER_MAX_NODES="$(terraform output -raw aml_compute_cluster_max_nodes 2>/dev/null || echo "")"
COMPUTE_CLUSTER_IDLE_TIME="$(terraform output -raw aml_compute_cluster_idle_time 2>/dev/null || echo "")"

cd "${REPO_ROOT}"

cat > "${ENV_FILE}" <<ENVEOF
# Auto-generated from Terraform outputs
# DO NOT EDIT MANUALLY - re-run: ./scripts/generate_env.sh
# Generated at: $(date)

AZURE_SUBSCRIPTION_ID=${SUB_ID}
AZURE_RESOURCE_GROUP=${RG}
AZURE_ML_WORKSPACE=${WS}
AZURE_LOCATION=${LOC}

ADLS_ACCOUNT_NAME=${ADLS}
ADLS_FILESYSTEM=${FS}

SYNAPSE_SQL_ADMIN_LOGIN=${SQL_LOGIN}
SYNAPSE_SQL_ADMIN_PASSWORD=********

# AML Compute Cluster (empty if disabled)
AZURE_ML_COMPUTE_CLUSTER=${COMPUTE_CLUSTER_NAME}
AZURE_ML_COMPUTE_VM_SIZE=${COMPUTE_CLUSTER_VM_SIZE}
AZURE_ML_COMPUTE_MIN_NODES=${COMPUTE_CLUSTER_MIN_NODES}
AZURE_ML_COMPUTE_MAX_NODES=${COMPUTE_CLUSTER_MAX_NODES}
AZURE_ML_COMPUTE_IDLE_TIME=${COMPUTE_CLUSTER_IDLE_TIME}

# NOTE: Do NOT store secrets here.
# Set this manually when needed:
# SYNAPSE_SQL_ADMIN_PASSWORD=********
ENVEOF

echo "✅ Wrote ${ENV_FILE}"
