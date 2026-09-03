#!/bin/bash
# Wrapper for flutter build web with AI support
cd "$(dirname "$0")"
./run_with_ai.sh build web "$@"