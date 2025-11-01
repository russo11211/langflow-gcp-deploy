#!/usr/bin/env bash
set -euo pipefail

# setup_gcloud.sh
# Pequeno helper para instalar (quando necessário) e verificar o Google Cloud SDK,
# autenticar e definir projeto/region padrão.

usage() {
  cat <<EOF
Usage: $0 [-p PROJECT_ID] [-r REGION]

Options:
  -p PROJECT_ID   Projeto GCP (ex: clean-art-334716)
  -r REGION       Região padrão para deploy (ex: us-central1)

Examples:
  $0 -p clean-art-334716 -r us-central1
EOF
}

PROJECT=""
REGION=""

while getopts ":p:r:h" opt; do
  case ${opt} in
    p ) PROJECT="$OPTARG" ;;
    r ) REGION="$OPTARG" ;;
    h ) usage; exit 0 ;;
    \? ) echo "Invalid option: -$OPTARG" >&2; usage; exit 1 ;;
  esac
done

# Checa se gcloud está instalado
if ! command -v gcloud >/dev/null 2>&1; then
  echo "gcloud não encontrado — instalando... (requer sudo)"
  sudo apt-get update
  sudo apt-get install -y apt-transport-https ca-certificates gnupg curl
  sudo curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
  sudo bash -lc 'cat >/etc/apt/sources.list.d/google-cloud-sdk.list <<EOF\ndeb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main\nEOF'
  sudo apt-get update
  sudo apt-get install -y google-cloud-sdk
fi

echo "gcloud instalado: $(gcloud --version | head -n1)"

# Autenticação no gcloud (abre o fluxo com URL + código)
echo "Iniciando autenticação (modo sem navegador). Siga o link e cole o código quando solicitado."
gcloud auth login --no-launch-browser

if [ -n "$PROJECT" ]; then
  echo "Definindo projeto: $PROJECT"
  gcloud config set project "$PROJECT"
fi

if [ -n "$REGION" ]; then
  echo "Definindo region padrão: $REGION"
  gcloud config set run/region "$REGION"
fi

echo "Pronto. Configuração atual:"
gcloud config list
