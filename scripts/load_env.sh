#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="$(pwd)/.env"

if [ ! -f "${ENV_FILE}" ]; then
  echo "ERROR: .env not found. Run ./scripts/generate_env.sh first."
  exit 1
fi

set -a
source "${ENV_FILE}"
set +a

# Required variables for your workflow
required_vars=(
  AZURE_SUBSCRIPTION_ID
  AZURE_RESOURCE_GROUP
  AZURE_ML_WORKSPACE
  AZURE_LOCATION
  ADLS_ACCOUNT_NAME
  ADLS_FILESYSTEM
  SYNAPSE_SQL_ADMIN_LOGIN
)

missing=0
for v in "${required_vars[@]}"; do
  if [ -z "${!v-}" ]; then
    echo "❌ Missing env var: $v"
    missing=1
  fi
done

if [ "$missing" -eq 1 ]; then
  echo
  echo "Fix: regenerate .env (recommended) or add the missing variables to .env manually."
  echo "Example:"
  echo "  AZURE_RESOURCE_GROUP=<your-rg>"
  exit 1
fi

echo "✅ Loaded environment from .env"
echo "AZURE_SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID}"
echo "AZURE_RESOURCE_GROUP=${AZURE_RESOURCE_GROUP}"
echo "AZURE_ML_WORKSPACE=${AZURE_ML_WORKSPACE}"
echo "AZURE_LOCATION=${AZURE_LOCATION}"
echo "ADLS_ACCOUNT_NAME=${ADLS_ACCOUNT_NAME}"
echo "ADLS_FILESYSTEM=${ADLS_FILESYSTEM}"
echo "SYNAPSE_SQL_ADMIN_LOGIN=${SYNAPSE_SQL_ADMIN_LOGIN}"
