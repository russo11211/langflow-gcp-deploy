#!/usr/bin/env bash
set -euo pipefail

# build_and_deploy.sh
# Script para construir a imagem com Cloud Build (gcloud builds submit)
# e em seguida fazer deploy no Cloud Run.

usage() {
  cat <<EOF
Usage: $0 -p PROJECT_ID -t IMAGE_TAG [-r REGION] [-s SERVICE]

Options:
  -p PROJECT_ID   Projeto GCP (ex: clean-art-334716)
  -t IMAGE_TAG    Tag da imagem (ex: 1.6.9)
  -r REGION       Região para o deploy (default: us-central1)
  -s SERVICE      Nome do serviço Cloud Run (default: langflow)
  -T TIMEOUT      Timeout do build (ex: 2400s) (default: 2400s)

Example:
  $0 -p clean-art-334716 -t 1.6.9 -r southamerica-east1 -s langflow
EOF
}

PROJECT=""
TAG=""
REGION="us-central1"
SERVICE="langflow"
TIMEOUT="2400s"

while getopts ":p:t:r:s:T:h" opt; do
  case ${opt} in
    p ) PROJECT="$OPTARG" ;;
    t ) TAG="$OPTARG" ;;
    r ) REGION="$OPTARG" ;;
    s ) SERVICE="$OPTARG" ;;
    T ) TIMEOUT="$OPTARG" ;;
    h ) usage; exit 0 ;;
    \? ) echo "Invalid option: -$OPTARG" >&2; usage; exit 1 ;;
  esac
done

if [ -z "$PROJECT" ] || [ -z "$TAG" ]; then
  echo "Missing required args." >&2
  usage
  exit 1
fi

IMAGE="gcr.io/${PROJECT}/langflow:${TAG}"

echo "Iniciando build -> ${IMAGE} (timeout=${TIMEOUT})"
gcloud builds submit --tag "${IMAGE}" --timeout="${TIMEOUT}" .

echo "Build concluído. Fazendo deploy no Cloud Run: service=${SERVICE} region=${REGION}"
gcloud run deploy "${SERVICE}" \
  --image "${IMAGE}" \
  --platform managed \
  --region "${REGION}" \
  --allow-unauthenticated \
  --port 7860 \
  --memory 2Gi \
  --cpu-boost

echo "Deploy finalizado. Verifique a URL fornecida pelo comando acima."
