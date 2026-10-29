# Interval — Made by Sura

A native SwiftUI interval timer for iPhone and iPad (iOS 17+).
The app lives on `interval-timer-ios`; the website's `master` branch is separate.

## Version 1.2.1

- Separate three-beep skip preparation track: immediate higher beep on the first tap, then two countdown beeps. Voice mode retains spoken counting. The second tap stops preparation audio and advances immediately.
- Live Activity requests happen while the app is visible, before audio preparation. Orphan cleanup completes before the new activity starts.
- Visible Live Activity status, actual iOS request errors, retry, Settings shortcut, and installed widget-extension check.
- Optional local notifications at interval boundaries and completion, rescheduled after pause/skip/restart. iOS caps pending notifications; long workouts reserve one completion alert and the next 59 boundaries.
- Keep and sign the embedded widget extension when sideloading. Start a workout, allow notifications, then go Home or lock the phone. Dynamic Island requires a compatible iPhone; Lock Screen Live Activities do not require Dynamic Island.
- Build and unit tests validate source and packaging. Signing and appearance on the user's device still require on-device verification.

## Version 1.2

- Optional 3-second preparation after tapping Skip. A second tap bypasses the countdown. Paused sessions skip immediately.

- Live Activity for Lock Screen and compact, minimal, and expanded Dynamic Island.
- Countdown, phase, round/set, pause and completion state; tap to reopen the timer.
- Live Activities can be disabled in Settings. The widget is embedded in the IPA.
- Search and duplicate favorites; update a selected favorite without creating duplicates.
- Restart the current interval without ending the session.
- In silent mode, if iOS suspends the app, stale phase information is replaced by an overall countdown and an open-timer prompt. Force-quitting ends audio; reopening clears any orphaned activity.

## Version 1.1

- Refined interface with charcoal surfaces, soft phase accents, rounded panels, and a pinned Start button.
- Dark, Light, and System appearance options. Dark is the initial default; your selection persists.
- Timer, Favorites, and Settings tabs.
- No history screen or automatic workout logging.
- Existing saved favorites and countdown preferences continue to load.

## Timer features

Warm-up, work, rest, rounds, sets, recovery between sets, and cool-down.
Tap a time to edit it, or drag horizontally in five-second steps.
Name exercises, save multiple favorite timers, and choose a countdown warning
from 1–10 seconds (including 3 or 5), or off. Each favorite saves its own warning.

The full-screen timer supports pause, resume, skip, voice/beep guidance, haptics,
and audio that mixes with music. Calls pause the session.
Everything runs on-device, with no account, ads, or subscriptions.

## IPA

Download [Downloads/Interval-unsigned.ipa](Downloads/Interval-unsigned.ipa), or the
`Interval-unsigned-IPA` artifact from the latest successful **Build Interval IPA** run.
The file is a real arm64 iPhone build, unsigned. Sign it with your own identity
through a compatible sideloading tool before installation.

## Build on a Mac

Install Xcode and XcodeGen, then run:

```sh
swift scripts/GenerateIcon.swift
xcodegen generate
open Interval.xcodeproj
```

Use the Interval scheme. For a device, enable signing and choose your team in Xcode.

The CI build runs XCTest, captures dark and light simulator previews, builds an arm64
device app, verifies the archive, and uses official `rea-agents@6.8.0` to inspect the IPA
and compiled Info.plist. Logs, tests, previews, and REA evidence are uploaded separately.

## Timing

A continuous monotonic clock drives phase selection; UI ticks do not accumulate timing drift.
No rest is inserted after the last round of a set. Set recovery applies only between sets.
Skipping advances the schedule without counting skipped time as time trained.

With audio enabled, a pre-rendered cue track schedules actual audible interval/countdown sounds
while locked. Voice guidance runs on the same audio session.
Silent mode catches the UI up when you return. Force-quitting ends playback.
Workouts are capped at 3 hours; temporary audio can use about 173 MB and is removed when closed.

## Reference and REA

Reference: https://apps.apple.com/nl/app/interval-timer-hiit-timer/id1124297113
REA: https://github.com/morluto/rea

This is an independent implementation with original UI and assets. The source app's
IPA was not supplied, so it was not decompiled. REA inspects this app's built package;
that static inventory does not certify runtime behaviour.
