# Play Store Release Checklist (PowerFit)

Date generated: 2026-03-24
App ID: com.netfull.powerfit
Release artifact: build/app/outputs/bundle/clientRelease/app-client-release.aab

## 1) Build identity checks

- [x] App label is PowerFit
- [x] Application ID is com.netfull.powerfit
- [x] Version is 1.0.0 (versionCode 2)
- [x] Release AAB generated
- [x] AAB contains signature files in META-INF (UPLOAD.SF / UPLOAD.RSA)

## 2) Permissions found in merged release manifest

The final merged manifest includes:

- android.permission.CAMERA
- android.permission.POST_NOTIFICATIONS
- android.permission.USE_BIOMETRIC
- android.permission.USE_FINGERPRINT
- android.permission.INTERNET
- android.permission.WAKE_LOCK
- android.permission.ACCESS_NETWORK_STATE
- com.google.android.c2dm.permission.RECEIVE

## 3) Play Console declarations to complete

Complete these sections before rollout:

- App content > Privacy policy: publish a valid URL.
- App content > Data safety: declare data collection/sharing and security practices.
- App content > App access: provide test credentials if login is required.
- App content > Content rating: complete questionnaire.
- App content > Ads: declare if app contains ads.

Because CAMERA and POST_NOTIFICATIONS are present, ensure your Data safety form and store listing explain their purpose clearly.

## 4) Upload steps

1. Open Play Console > Your app > Release > Production.
2. Create new release.
3. Upload AAB: build/app/outputs/bundle/clientRelease/app-client-release.aab
4. Add release notes.
5. Review policy warnings (if any) and submit for review.

## 5) Optional pre-production sanity

- Upload to Internal testing first and verify:
  - Push notifications work
  - Camera/QR flows work
  - Biometric login works
  - Login and core screens open without crashes
