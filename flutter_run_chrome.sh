#!/bin/bash
# Wrapper for flutter run -d chrome with AI support
cd "$(dirname "$0")"
./run_with_ai.sh run -d chrome "$@"