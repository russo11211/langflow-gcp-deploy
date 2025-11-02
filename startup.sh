#!/bin/bash
set -e

echo "================================"
echo "LangFlow Cloud Run Startup"
echo "================================"

# Display environment info
echo "Container startup - PID: $$"
echo "Port: ${PORT:-7860}"
echo "Host: 0.0.0.0"
echo ""

# Optional: Sync with Git repository if available and credentials exist
# (Useful if LangFlow saves flows to this repo with auto-commit)
if [ -d ".git" ]; then
  echo "[INFO] Git repository detected."
  if [ -n "$GIT_TOKEN" ]; then
    echo "[INFO] GIT_TOKEN found - attempting to sync with remote..."
    git pull origin main || echo "[WARN] Git sync failed (may be expected in read-only mode)"
  else
    echo "[INFO] No GIT_TOKEN - skipping git sync (flows will be local-only)"
  fi
  echo ""
fi

# Configure LangFlow to load flows and custom components
# The standard location for LangFlow data is ~/.langflow/
# Since we're running as root, HOME=/root

echo "[INFO] Setting up LangFlow flows and custom components..."

# Ensure the .langflow directory exists
mkdir -p /root/.langflow/flows
mkdir -p /root/.langflow/custom_components

# Copy flows and custom components from /app to ~/.langflow/
# (The Dockerfile already copied them, but we ensure they're in the right place)
if [ -d "/app/flows" ] && [ "$(ls -A /app/flows)" ]; then
  echo "[INFO] Copying flows to ~/.langflow/flows..."
  cp -r /app/flows/* /root/.langflow/flows/ 2>/dev/null || true
  echo "[INFO] Flows copied: $(ls /root/.langflow/flows | wc -l) files"
else
  echo "[WARN] No flows found in /app/flows"
fi

if [ -d "/app/custom_components" ] && [ "$(ls -A /app/custom_components)" ]; then
  echo "[INFO] Copying custom components to ~/.langflow/custom_components..."
  cp -r /app/custom_components/* /root/.langflow/custom_components/ 2>/dev/null || true
  echo "[INFO] Custom components copied: $(ls /root/.langflow/custom_components | wc -l) items"
else
  echo "[WARN] No custom components found in /app/custom_components"
fi

echo "[INFO] LangFlow data directory prepared at ~/.langflow/"
ls -la /root/.langflow/ || true
echo ""

# Export configuration so LangFlow knows where to look for flows/components
export LANGFLOW_CONFIG_DIR=/root/.langflow
export LANGFLOW_LOAD_FLOWS_PATH=/root/.langflow/flows
export LANGFLOW_COMPONENTS_PATH=/root/.langflow/custom_components
export LANGFLOW_SAVE_DB_IN_CONFIG_DIR=true

echo "[INFO] LangFlow environment configuration:"
echo "  LANGFLOW_CONFIG_DIR: ${LANGFLOW_CONFIG_DIR}"
echo "  LANGFLOW_LOAD_FLOWS_PATH: ${LANGFLOW_LOAD_FLOWS_PATH}"
echo "  LANGFLOW_COMPONENTS_PATH: ${LANGFLOW_COMPONENTS_PATH}"
echo "  LANGFLOW_SAVE_DB_IN_CONFIG_DIR: ${LANGFLOW_SAVE_DB_IN_CONFIG_DIR}"
echo ""

# Launch the application directly with uvicorn for better compatibility with Cloud Run.
# The --host 0.0.0.0 is crucial for the container to be accessible from outside.
# The --port ${PORT:-7860} uses the environment variable provided by Cloud Run, or defaults to 7860.
# The --loop asyncio ensures compatibility with nest_asyncio used by LangFlow.
echo "[INFO] Starting uvicorn server..."
exec uvicorn "langflow.main:setup_app" \
  --factory \
  --host 0.0.0.0 \
  --port ${PORT:-7860} \
  --workers 1 \
  --loop asyncio \
  --log-level info
