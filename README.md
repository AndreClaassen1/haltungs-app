# Haltungs-App

A small macOS menu bar app that reminds you to change your posture while working at a desk: switch between sitting and standing, take a micro break, rest your eyes, do a short mobility exercise.

It lives in the menu bar only (no Dock icon), shows a countdown to the next reminder and presents each reminder as a small floating panel or a notification.

> **Language:** the user interface is German. The code, documentation and issues are in English.

## Features

- **Independent reminders**, each with its own interval: sit/stand switch, posture cue, micro break, eye break (20-20-20 rule), mobility exercise, plus your own custom reminders.
- **Sit/stand phases:** while standing, the sit/stand reminder uses its own (shorter) interval.
- **Quiet by design:** a rest period after every interruption, so reminders that are due at the same time are played one after another instead of all at once.
- **Work window:** reminders only fire inside your working hours (overnight windows work too).
- **Snooze, skip and mute:** postpone a single reminder, restart it without doing the exercise, or mute everything for a while.
- **Daily statistics:** sit/stand switches, time spent standing, completed and snoozed reminders.
- **Editable defaults:** every reminder can be changed, disabled or reset in the settings.

The default intervals follow the German occupational safety guidance on screen work (DGUV Information 215-410 and BAuA) and the common "60-30-10" rule of thumb (about 60 % dynamic sitting, 30 % standing, 10 % moving).

**This app is not medical advice.** If you have back or joint problems, ask a doctor or physiotherapist which routine fits you.

## Requirements

- macOS 26 or later
- Xcode 26 or later (the app uses the macOS 26 SDK)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

## Build and run

The Xcode project is generated from `project.yml` and is not checked in.

```bash
git clone https://github.com/AndreClaassen1/haltungs-app.git
cd haltungs-app
xcodegen generate
open HaltungApp.xcodeproj
```

In Xcode, select the `HaltungApp` scheme, choose your own team under *Signing & Capabilities* (or "Sign to Run Locally") and run.

From the command line, an ad-hoc signed build that runs on your own Mac:

```bash
xcodegen generate
xcodebuild -project HaltungApp.xcodeproj -scheme HaltungApp -configuration Release \
  -derivedDataPath build \
  CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY=- DEVELOPMENT_TEAM= \
  build
open build/Build/Products/Release/HaltungApp.app
```

### Your own team and bundle identifier

`project.yml` contains the author's team ID and bundle identifier. To sign with your own Apple Developer team, either change `DEVELOPMENT_TEAM` and `PRODUCT_BUNDLE_IDENTIFIER` in `project.yml` before running `xcodegen generate`, or pass them to `xcodebuild`:

```bash
xcodebuild ... DEVELOPMENT_TEAM=<YOUR_TEAM_ID> PRODUCT_BUNDLE_IDENTIFIER=com.example.haltungs-app build
```

## Tests

All scheduling logic lives in the `HaltungCore` Swift package and is covered by unit tests (Swift Testing):

```bash
swift test
```

## Architecture in short

- **`HaltungCore`** (`Sources/HaltungCore`): pure, stateless logic without UI or persistence. The `ReminderScheduler` decides which reminder is due, respecting intervals, snooze, work window, mute and the rest period.
- **`HaltungApp`** (`HaltungApp/`): SwiftUI menu bar app. A `ReminderEngine` ticks every 10 seconds, asks the scheduler and presents the reminder. Reminders and the event log are stored with SwiftData in `~/Library/Application Support/HaltungApp/`, settings in `UserDefaults`.

## Contributing

Issues and pull requests are welcome; see [CONTRIBUTING.md](CONTRIBUTING.md). This is a personal project, so there is no guaranteed support.

## License

Haltungs-App is licensed under the [Functional Source License, Version 1.1, MIT Future License](LICENSE.md) (FSL-1.1-MIT).

In short: you may use, study, modify and share the app for any purpose **except** building a competing commercial product or service from it. Each released version automatically becomes available under the MIT license two years after its release.

The name "Haltungs-App" and the app icon are not covered by the license.
