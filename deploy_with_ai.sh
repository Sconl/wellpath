#!/bin/bash
# WellPath Deploy Script with AI Support
# Builds and deploys the app with Gemini AI enabled

echo "🔨 Building WellPath web app with AI support..."

# Load environment variables
if [ -f ".env" ]; then
  export $(grep -v '^#' .env | xargs)
fi

# Set default API key if not set
export GEMINI_API_KEY=${GEMINI_API_KEY:-"${GEMINI_API_KEY:?set GEMINI_API_KEY in your environment}"}

echo "GEMINI_API_KEY: ${GEMINI_API_KEY:0:20}..."

# Build web app with AI support
flutter build web --release --dart-define=GEMINI_API_KEY="$GEMINI_API_KEY"

if [ $? -eq 0 ]; then
  echo "✅ Build successful! Deploying to Firebase..."
  firebase deploy --only hosting
else
  echo "❌ Build failed!"
  exit 1
fi