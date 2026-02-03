# Deploy Checklist

## Pre-build
- [ ] Verify `lib/firebase_options.dart` exists with REAL credentials (NOT placeholder)
- [ ] Verify on correct branch/commit: `git log --oneline -1`
- [ ] Run `flutter analyze` — zero errors

## Build
```bash
export PATH="$HOME/flutter/bin:$PATH"
flutter build web --base-href="/vault-app/"
```

## Deploy gh-pages
```bash
# Save build, switch branch, deploy
rm -rf /tmp/vault-web-deploy
cp -r build/web /tmp/vault-web-deploy
rm -rf /tmp/vault-web-deploy/.dart_tool /tmp/vault-web-deploy/.last_build_id /tmp/vault-web-deploy/web

git checkout gh-pages
find . -maxdepth 1 -not -name '.git' -not -name '.' -exec rm -rf {} +
cp -r /tmp/vault-web-deploy/* .
git add -A && git commit -m "deploy: <description> (<commit>)"
git push origin gh-pages
git checkout main
```

## Post-deploy
- [ ] Verify `lib/firebase_options.dart` still exists (hook should restore it)
- [ ] Test login on https://antoradecb.github.io/vault-app/

## Cloud Functions deploy
```bash
cd functions && npm run build && firebase deploy --only functions
```

## ⚠️ Known gotchas
- `firebase_options.dart` is in `.gitignore` → gets deleted on branch switch
  - Git hook auto-restores from `~/.vault-app-firebase-options.dart`
  - If missing: recreate from `.dart.example` with real Firebase credentials
- GitHub Pages CDN can be slow to propagate (2-5 min)
