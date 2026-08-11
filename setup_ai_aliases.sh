#!/bin/bash
# WellPath AI Setup Script
# Adds aliases to your shell profile for AI-enabled Flutter commands

SHELL_PROFILE=""
if [ -f "$HOME/.zshrc" ]; then
  SHELL_PROFILE="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
  SHELL_PROFILE="$HOME/.bashrc"
elif [ -f "$HOME/.bash_profile" ]; then
  SHELL_PROFILE="$HOME/.bash_profile"
fi

if [ -z "$SHELL_PROFILE" ]; then
  echo "❌ Could not find shell profile (.zshrc, .bashrc, or .bash_profile)"
  exit 1
fi

echo "🔧 Setting up AI-enabled Flutter aliases in $SHELL_PROFILE..."

# Check if aliases already exist
if grep -q "alias flutter=" "$SHELL_PROFILE"; then
  echo "⚠️  Flutter aliases already exist in $SHELL_PROFILE"
  echo "   Please remove existing flutter aliases before running this script"
  exit 1
fi

# Add aliases
cat >> "$SHELL_PROFILE" << 'EOF'

# WellPath AI-enabled Flutter commands
# These aliases automatically include the Gemini API key for AI chat support
alias flutter='~/wellpath-fitness/wellpath/run_with_ai.sh'
alias wellpath-run='~/wellpath-fitness/wellpath/run_with_ai.sh run -d chrome'
alias wellpath-build='~/wellpath-fitness/wellpath/run_with_ai.sh build web --release'
alias wellpath-deploy='~/wellpath-fitness/wellpath/deploy_with_ai.sh'

EOF

echo "✅ Aliases added! Please restart your terminal or run: source $SHELL_PROFILE"
echo ""
echo "🚀 Now you can use:"
echo "   flutter run -d chrome    # Runs with AI support"
echo "   flutter build web        # Builds with AI support"
echo "   wellpath-deploy          # Builds and deploys with AI support"
echo ""
echo "Or use the direct scripts:"
echo "   ./run_with_ai.sh run -d chrome"
echo "   ./run_with_ai.sh build web --release"
echo "   ./deploy_with_ai.sh"