# WellPath AI Chat Setup

This guide shows how to run WellPath with AI chat support enabled.

## 🚀 Quick Commands

### Development
```bash
# Run in Chrome with AI support
./flutter_run_chrome.sh

# Or use the universal script
./run_with_ai.sh run -d chrome
```

### Building
```bash
# Build web app with AI support
./flutter_build_web.sh

# Or use the universal script
./run_with_ai.sh build web --release
```

### Deployment
```bash
# Build and deploy with AI support
./deploy_with_ai.sh
```

## 🔧 Manual Commands

If you prefer manual commands:

```bash
# Run
flutter run -d chrome --dart-define=GEMINI_API_KEY=<YOUR_GEMINI_API_KEY>

# Build
flutter build web --release --dart-define=GEMINI_API_KEY=<YOUR_GEMINI_API_KEY>

# Deploy
flutter build web --release --dart-define=GEMINI_API_KEY=<YOUR_GEMINI_API_KEY>
firebase deploy --only hosting

```

## ⚙️ VS Code Setup

Use the pre-configured launch configurations:
1. Open VS Code
2. Go to Run & Debug (Ctrl+Shift+D)
3. Select "WellPath (Chrome) - With AI"
4. Press F5

## � CI/CD Deployment

GitHub Actions workflows automatically deploy with AI support:

### Dev Branch (`.github/workflows/wellpath_firebase_dev.yml`)
- Triggers on push to `dev` branch
- Deploys to Firebase Hosting dev environment

### Production Branch (`.github/workflows/wellpath_firebase_prod.yml`)
- Triggers on push to `main`/`master` branch
- Deploys to Firebase Hosting production environment

## 🔑 GitHub Secrets Setup

To enable AI in CI/CD deployments:

1. **Go to your GitHub repository**
2. **Navigate to Settings → Secrets and variables → Actions**
3. **Add the following secrets:**

   | Secret Name | Value |
   |-------------|-------|
   | `GEMINI_API_KEY` | `<YOUR_GEMINI_API_KEY>` |
   | `WELLPATH_FIREBASE_DEPLOY_DEV` | Your Firebase CI token for dev |
   | `WELLPATH_FIREBASE_DEPLOY_PROD` | Your Firebase CI token for prod |

4. **Get Firebase CI tokens:**
   ```bash
   firebase login:ci  # For dev token
   firebase use --add  # Switch to prod project
   firebase login:ci  # For prod token
   ```

## 🔒 Security Best Practices

- ✅ **GitHub Secrets**: API keys stored securely, not in code
- ✅ **Environment Variables**: Keys only available during build
- ✅ **No Version Control**: Secrets never committed to git
- ✅ **Scoped Access**: Different keys for dev/prod environments
- ⚠️ **Production Consideration**: For high-traffic apps, consider Firebase Cloud Functions to proxy AI requests

## 📁 Files Created

- `run_with_ai.sh` - Universal Flutter wrapper with AI support
- `flutter_run_chrome.sh` - Quick Chrome runner
- `flutter_build_web.sh` - Quick web builder
- `deploy_with_ai.sh` - Build and deploy script
- `setup_ai_aliases.sh` - Optional shell aliases setup
- `.env` - Environment variables (contains API key)
- `.env.example` - Template for environment variables