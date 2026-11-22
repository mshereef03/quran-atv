# Quran — tvOS

A native SwiftUI tvOS app for streaming Quran recitation, ayah by ayah, on the Apple TV. Browse by surah or juz', follow along with highlighted Arabic text and an optional English translation, bookmark favorites, and resume where you left off.

## Features

- Ayah-by-ayah streaming using each reciter's single continuous surah recording (no stitched-together clips, so playback is naturally gapless)
- Live Arabic text highlighting synced to playback, with adjustable font and size
- Optional English translation
- Browse by surah, by juz', or search; bookmark and resume in-progress surahs
- Multiple reciters, switchable mid-playback
- Siri Remote-first design: focus-driven navigation, auto-hiding transport controls, Now Playing integration

## Requirements

- Xcode 16+
- tvOS 17+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Getting started

```sh
git clone <this-repo-url>
cd quran-atv
xcodegen generate
open Quran.xcodeproj
```

The Xcode project itself is generated from `project.yml` and is not committed — run `xcodegen generate` any time you pull changes that touch `project.yml` or add/remove files.

## Architecture notes

- Data comes from the [Quran Foundation API](https://api-docs.quran.foundation) (`QuranAPIClient`).
- Each surah is streamed as one continuous audio file per reciter, with per-ayah timestamps used to drive highlighting and seeking — not separate per-ayah clips.
- `PlayerViewModel` owns playback state and is kept alive by `RootView` across navigation, so leaving the player screen pauses the UI, not the audio.

## Attribution & licensing

This project's own source code is MIT-licensed (see [LICENSE](LICENSE)). It depends on third-party content and assets under their own terms:

- **Quran text, translations, and recitation audio** are provided by the [Quran Foundation API](https://api-docs.quran.foundation) and displayed as part of the app's experience, per their [Developer Terms of Service](https://api-docs.quran.foundation/legal/developer-terms/). Quran data provided by Quran Foundation. Rights holders vary by individual recitation recording.
- **Arabic typefaces** (Amiri Quran, Scheherazade New, Harmattan) are licensed under the [SIL Open Font License 1.1](https://openfontlicense.org/) — see `Quran/Fonts/*-LICENSE.txt`.
- **Background photography** is sourced from [Unsplash](https://unsplash.com), used under the [Unsplash License](https://unsplash.com/license) (free for commercial use, no attribution required).

If you fork this project to publish your own app, you are responsible for registering your own app with Quran Foundation's Developer Console and complying with their current terms.

## Privacy Policy & Terms of Use

[Privacy Policy & Terms of Use](https://claude.ai/code/artifact/cf1fa7b9-6412-4b36-82f8-1045401c4c02) — required reading before submitting to the App Store; this is the URL to use in App Store Connect's Privacy Policy field. This link must be shared publicly (not just accessible to the owner) before submission, since App Review needs to open it. If you later move this content to your own domain, update this link and the App Store Connect listing accordingly.

## Contributing

Issues and pull requests are welcome. A few guidelines:

- Keep the player's core playback logic simple — it's intentionally built around one continuous audio file per surah rather than per-ayah clips; please don't reintroduce that complexity.
- Match the existing SwiftUI/MVVM structure (`Views/`, `ViewModels/`, `Models/`, `Networking/`).
- Test on a real Apple TV where possible — some behaviors (focus navigation, remote input) don't fully reproduce in the Simulator.

## License

MIT — see [LICENSE](LICENSE). Third-party content and assets are licensed separately as noted above.
