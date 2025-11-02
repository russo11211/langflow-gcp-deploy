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

# Configure LangFlow to load flows and custom components from the mounted directories
export LANGFLOW_LOAD_FLOWS_ON_STARTUP=true
export LANGFLOW_FLOWS_PATH=/app/flows
export LANGFLOW_CUSTOM_COMPONENTS_PATH=/app/custom_components

echo "[INFO] Configuration:"
echo "  LANGFLOW_FLOWS_PATH: $LANGFLOW_FLOWS_PATH"
echo "  LANGFLOW_CUSTOM_COMPONENTS_PATH: $LANGFLOW_CUSTOM_COMPONENTS_PATH"
echo "  LANGFLOW_LOAD_FLOWS_ON_STARTUP: $LANGFLOW_LOAD_FLOWS_ON_STARTUP"
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
