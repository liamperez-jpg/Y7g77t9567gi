# Kernel Panic Mimic

A prank iOS app: shows a fake iPad home screen mockup → flashes black twice →
plays a 3-second high-pitch tone → shows a fake kernel panic log screen →
shows the Apple boot logo → exits.

## What's in this repo

```
project.yml                          # XcodeGen spec (generates the .xcodeproj — no Xcode needed)
codemagic.yaml                       # Codemagic CI config
Sources/KernelPanicMimic/
  KernelPanicMimicApp.swift          # App entry point
  ContentView.swift                  # State machine driving all the visual phases
  ToneGenerator.swift                # Sine-wave tone generator (AVAudioEngine, no audio files)
  Info.plist                         # Base Info.plist (XcodeGen merges properties into it)
```

## How the sequence works

`ContentView.swift` drives everything through a `Phase` enum and an async
`Task`, so timing is just a sequential list you can tweak:

1. `mockup` — fake iPad home screen (2s)
2. `flashBlackOn/Off` ×2 — black screen blinks twice (0.25s/0.2s each)
3. `tone` — 3s sine tone at 15.5kHz over a black screen
4. `panic` — fake kernel panic log text
5. `appleLogo` — Apple logo (SF Symbol `apple.logo`) on black, like a boot screen
6. `exit(0)` — closes the app

Change durations/frequency directly in `runSequence()` and `KernelPanicView`'s
`logLines` array.

**Note:** `exit(0)` is fine for a personal/sideloaded build but Apple's App
Store review guidelines prohibit apps from force-quitting themselves, so
don't submit this one to the App Store as-is.

## Setting up Codemagic

1. Push this folder to a GitHub/GitLab/Bitbucket repo and connect it in Codemagic.
2. **Signing** — you have two options; the `codemagic.yaml` here uses manual signing:
   - **Manual (what's configured):** In Codemagic → your app → Code signing
     identities, upload your `.p12` certificate and `.mobileprovision` profile,
     naming them `kernel_panic_mimic_cert` and `kernel_panic_mimic_profile`
     (or edit those names in `codemagic.yaml` to match whatever you call them).
   - **Automatic (simpler if you have an App Store Connect API key):** Replace
     the `ios_signing` block with an `app_store_connect` integration and use
     `xcode-project use-profiles` with automatic signing — Codemagic's docs
     walk through this under "iOS code signing."
3. Set `TEAM_ID` to your actual Apple Developer Team ID (found in
   developer.apple.com → Membership) in Codemagic's environment variables,
   overriding the placeholder in `codemagic.yaml`.
4. For **ad hoc** distribution (installing directly on your own iPad without
   TestFlight), make sure your device's UDID is registered in your Apple
   Developer account and included in the provisioning profile.
5. Push to trigger a build. The `.ipa` shows up in the build's Artifacts tab —
   install via Apple Configurator, a service like Diawi, or TestFlight if you
   switch to an App Store/ad hoc distribution profile there instead.

## Tweaking the mockup

`MockupHomeScreenView` in `ContentView.swift` is a generic grid of SF Symbol
icons + a fake dock — swap `iconNames` for whatever apps you want visible, or
add real screenshots as image assets and swap in `Image("your_asset")` instead
of the SF Symbols if you want it to look more convincing.
