# Scripts

This folder contains small helper scripts for local development and CI.

## `build_web.sh`

Builds the Flutter web production bundle using environment variables instead of hardcoded URLs.

It also installs the Flutter SDK locally inside the repository workspace when the SDK is missing, which is required on Vercel.

## `install_web.sh`

Downloads Flutter if needed and runs `flutter pub get` before the build step.

### Required environment variables

- `API_BASE_URL` - FastAPI base URL used by the frontend
- `ENVIRONMENT` - Build environment label such as `development`, `staging`, or `production`

### Example

```bash
API_BASE_URL=https://api.powerfit.com ENVIRONMENT=production bash scripts/build_web.sh
```