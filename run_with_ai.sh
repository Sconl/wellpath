#!/bin/bash
# WellPath Development Launcher
# This script sets up environment variables and runs Flutter with AI support

# Load environment variables from .env file if it exists
if [ -f ".env" ]; then
  export $(grep -v '^#' .env | xargs)
fi

# Set default API key if not set
export GEMINI_API_KEY=${GEMINI_API_KEY:-"AIzaSyC4h6SP-wTxAzmclwLE2d73RVEicqgUC98"}

echo "🚀 Running Flutter with AI support..."
echo "GEMINI_API_KEY: ${GEMINI_API_KEY:0:20}..."

# Check if this is a flutter command that needs the API key
if [[ "$1" == "run" ]] || [[ "$1" == "build" ]] || [[ "$1" == "test" ]]; then
  # Add the dart-define for commands that support it
  flutter "$@" --dart-define=GEMINI_API_KEY="$GEMINI_API_KEY"
else
  # For other commands, just pass through
  flutter "$@"
fi