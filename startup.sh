#!/bin/sh
set -e

# Launch the application directly with uvicorn for better compatibility with Cloud Run.
# The --host 0.0.0.0 is crucial for the container to be accessible from outside.
# The --port ${PORT} uses the environment variable provided by Cloud Run.
exec uvicorn "langflow.main:setup_app" --factory --host 0.0.0.0 --port ${PORT} --workers 1 --loop asyncio
