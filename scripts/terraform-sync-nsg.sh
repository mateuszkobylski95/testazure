#!/usr/bin/env bash
set -euo pipefail

VM_IP="${VM_IP:?VM_IP is required}"
SSH_USER="${SSH_USER:-azureuser}"
TERRAFORM_DIR="${TERRAFORM_DIR:-terraform}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

PUBLIC_PORTS="$(
  ssh -o StrictHostKeyChecking=no \
    "${SSH_USER}@${VM_IP}" \
    "bash -s" < "${SCRIPT_DIR}/collect-public-ports.sh"
)"

DEPLOYMENT_MODE="$(
  ssh -o StrictHostKeyChecking=no \
    "${SSH_USER}@${VM_IP}" \
    'BOOTSTRAP_FILE=""
     for candidate in /opt/*/.bootstrap.env; do
       if [ -f "$candidate" ]; then
         BOOTSTRAP_FILE="$candidate"
         break
       fi
     done
     if [ -z "$BOOTSTRAP_FILE" ]; then
       echo single
     else
       grep "^DEPLOYMENT_MODE=" "$BOOTSTRAP_FILE" | cut -d"=" -f2
     fi'
)"

if [ -n "${SINGLE_DOMAIN_MODE_OVERRIDE:-}" ]; then
  SINGLE_DOMAIN_MODE="${SINGLE_DOMAIN_MODE_OVERRIDE}"
elif [ "$DEPLOYMENT_MODE" = "single" ]; then
  SINGLE_DOMAIN_MODE=true
else
  SINGLE_DOMAIN_MODE=false
fi

echo "Public ports: ${PUBLIC_PORTS}"
echo "Single domain mode: ${SINGLE_DOMAIN_MODE}"

pushd "$TERRAFORM_DIR" >/dev/null

terraform apply \
  -auto-approve \
  -var="resource_group_name=$(terraform output -raw resource_group_name)" \
  -var="vm_name=$(terraform output -raw vm_name)" \
  -var="ssh_public_key=${SSH_PUBLIC_KEY:?SSH_PUBLIC_KEY is required}" \
  -var="single_domain_mode=${SINGLE_DOMAIN_MODE}" \
  -var="public_ports=${PUBLIC_PORTS}"

popd >/dev/null
