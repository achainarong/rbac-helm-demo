#!/bin/bash

# Usage check
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <ServiceAccountName> <Namespace>"
    exit 1
fi

SERVICE_ACCOUNT_NAME=$1
NAMESPACE=$2

SECRET_NAME="${SERVICE_ACCOUNT_NAME}-token"

TOKEN=$(kubectl get secret "${SECRET_NAME}" -n "${NAMESPACE}" -o jsonpath="{.data.token}" | base64 --decode)

if [ -z "${TOKEN}" ]; then
    echo "Token for Secret '${SECRET_NAME}' in namespace '${NAMESPACE}' not found."
    exit 1
fi

CLUSTER_NAME=$(kubectl config current-context)

CA_CERT=$(kubectl get secret "${SECRET_NAME}" -n "${NAMESPACE}" -o jsonpath="{.data['ca\.crt']}")

API_SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')

KUBECONFIG_CONTENT=$(cat <<EOF
apiVersion: v1
kind: Config
clusters:
- name: ${CLUSTER_NAME}
  cluster:
    certificate-authority-data: ${CA_CERT}
    server: ${API_SERVER}
contexts:
- name: ${SERVICE_ACCOUNT_NAME}-${NAMESPACE}
  context:
    cluster: ${CLUSTER_NAME}
    namespace: ${NAMESPACE}
    user: ${SERVICE_ACCOUNT_NAME}
current-context: ${SERVICE_ACCOUNT_NAME}-${NAMESPACE}
users:
- name: ${SERVICE_ACCOUNT_NAME}
  user:
    token: ${TOKEN}
EOF
)

KUBECONFIG_FILE="${SERVICE_ACCOUNT_NAME}-${NAMESPACE}-kubeconfig.yaml"
echo "${KUBECONFIG_CONTENT}" > "${KUBECONFIG_FILE}"
echo "Kubeconfig for ServiceAccount '${SERVICE_ACCOUNT_NAME}' in namespace '${NAMESPACE}' created: ${KUBECONFIG_FILE}"
