# Interval — Made by Sura

A native SwiftUI interval-training app with a simple light interface, stacked color-coded interval controls, and a large full-color countdown for iPhone and iPad (iOS 17+).
This branch is an independent app project. The website on `master` is unchanged.

## Features

- Warm-up, work, rest, rounds, sets, recovery between sets, and cool-down.
- Tap a duration to edit it, or drag it horizontally in five-second steps.
- Custom names for each round, with repeatable sets.
- Full-screen, colour-coded countdown with pause, resume, and skip.
- Voice, beep, or silent guidance. Audio mixes with music.
- Adjustable countdown warning: 1–10 seconds before the next interval (including 3 or 5), or off. Each favorite remembers its own warning duration.
- Pre-rendered audible cue track for interval sounds while the screen is locked.
- Phone-call interruptions pause the session; resume manually afterward.
- Multiple named favorite timers, starter presets, local history, and weekly training totals.
- No account, network service, advertising, or subscription.

## Download the IPA

Open **Actions → Build Interval IPA → latest successful run → Artifacts → Interval-unsigned-IPA**.
A direct IPA is also saved in [Downloads/Interval-unsigned.ipa](Downloads/Interval-unsigned.ipa) on this branch after a successful build.

Extract the artifact ZIP to get `Interval-unsigned.ipa`.

This is a real arm64 device build, **unsigned**. It must be signed with your own
Apple identity/provisioning through a compatible sideloading tool before installation.
It cannot be installed by tapping the IPA, and it is not a TestFlight/App Store build.
No signing credentials are stored in this project.

## Build on a Mac

1. Install Xcode, select it with `xcode-select`, and install XcodeGen.
2. Run `swift scripts/GenerateIcon.swift` then `xcodegen generate`.
3. Open `Interval.xcodeproj`, select the Interval scheme, and run on a simulator.
4. For a physical device, select your development team and enable signing in Xcode.

The GitHub workflow generates the icon/project, runs XCTest on an iPhone simulator,
builds for generic iOS/arm64, verifies the ZIP and executable, and uploads the IPA.
A failed test or build stops packaging.

## Timing and background behaviour

The UI derives phase position from a continuous monotonic clock; it does not
count timer ticks. Pausing freezes elapsed time. Skipping advances the timeline
without adding skipped time to training statistics.
There is no rest after the final round of a set; separate set recovery applies
between sets.

When audio is enabled, a temporary mono PCM track contains the actual transition
and countdown beeps across the session. This keeps audio cues scheduled independently
of UI timer delivery. Voice guidance is layered on the audio session. With audio off,
no background audio is played; returning to the app catches the screen up.
Force-quitting the app ends playback; active workouts are not restored after termination.
Workouts are limited to 3 hours; the temporary track may use up to about 173 MB and
is removed when the workout is closed. History/presets use atomic on-device JSON writes.

## REA

Official project: https://github.com/morluto/rea
The build pins `rea-agents@6.8.0` and uses its CLI to inspect the resulting IPA
and compiled Info.plist. Evidence files are included in the build-evidence artifact.
These are static package inspections, not runtime or behavioural certification.

The only reference supplied was the public App Store listing:
https://apps.apple.com/nl/app/interval-timer-hiit-timer/id1124297113

No original IPA/source was supplied, so the original native app was not decompiled.
This is an independent implementation of the described timer features with original
UI and assets. It does not reproduce the reference app's cloud service, subscriptions,
localisations, or proprietary internals.

## Verification

XCTest covers phase ordering, set boundaries, zero-length optional phases,
exact transition times, delayed updates, duration totals, names, validation,
JSON round trips, and time formatting. The macOS build verifies SwiftUI compilation
and produces the real device executable.
