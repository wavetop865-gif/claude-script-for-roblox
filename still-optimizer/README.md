# Still — phone optimizer

Minimalist Android app that measures device calm (RAM, storage, cache) and runs a one-tap optimize flow.

## Design

- Brand: **Still**
- Atmosphere: cool mist blues with sage accent
- Type: Fraunces (display) + Outfit (UI)
- Motion: breathing calm ring, drifting mist, status transitions

## Build APK

```bash
export ANDROID_HOME=/path/to/android-sdk
cd still-optimizer
./gradlew assembleRelease
```

Signed release APK (ready to install):

`dist/Still-optimizer.apk`

Debug APK:

`dist/Still-optimizer-debug.apk`

## Install

```bash
adb install -r dist/Still-optimizer.apk
```

Demo signing keystore: `app/still-release.keystore` (password `stillpass`, alias `still`).
Replace before any public store release.