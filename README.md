# claw-chat (claw_chat)

A lightweight cross-platform AI chat mobile client for [OpenClaw](https://github.com/openclaw/openclaw). Connect directly to your OpenClaw Gateway via LAN/Tailscale, no cloud backend required.

## Features

- 🔌 **Direct Connection** - Connect to your own OpenClaw Gateway via LAN/Tailscale, no middleman
- 💬 **Full Chat Experience** - Multiple chat sessions, streaming AI responses, Markdown rendering
- 📎 **File Attachments** - Support for images, videos, audio, PDF files - preview directly in app
- 🔍 **Session Search** - Quickly find past conversations
- 🎨 **Theme Support** - Light / Dark / System theme
- 💾 **Local Persistence** - All conversations stored locally on your device
- ⚙️ **Settings** - Theme switching, clear data, reconnect

## Architecture

Following Clean Architecture principles:

```
lib/
├── core/             # Core constants, theme, utilities
├── data/             # Data sources & repositories
│   ├── datasource/
│   │   ├── local/    # Hive local storage
│   │   └── remote/   # OpenClaw WebSocket client
│   └── repository/
├── domain/           # Entities & business logic
└── presentation/     # UI & state management (Riverpod)
    ├── pages/
    ├── widgets/
    └── providers/
```

## Screenshots

*(Coming soon)*

## Build

### Prerequisites

- Flutter 3.x (stable channel)
- Dart 3.x

### Get Started

```bash
# Clone
git clone https://github.com/MQpeng/claw-chat.git
cd claw-chat

# Get dependencies
flutter pub get

# Build APK
flutter build apk --release --split-per-abi
```

The APK files will be generated at `build/app/outputs/flutter-apk/`.

### GitHub Actions

This project includes automatic APK building via GitHub Actions:

1. Tag a release:
```bash
git tag v1.0.0
git push origin v1.0.0
```

2. GitHub Action will automatically:
   - Build split-ABI APKs
   - Create a GitHub Release
   - Upload APKs to the release

## How to Use

1. **Pairing** - Scan QR code from your OpenClaw Gateway or enter connection info manually
2. **Create Session** - Tap + to create a new chat session
3. **Chat** - Send messages, attach files, receive streaming responses
4. **Manage Sessions** - Swipe to delete/rename/pin sessions
5. **Search** - Use search to quickly find sessions by name
6. **Settings** - Change theme, clear all data, reconnect

## Requirements

- Android 8.0 (API 26) or newer
- OpenClaw Gateway v0.1.0+ with exposed API endpoint

## Permissions

- Camera - For QR code scanning and taking photos
- Storage - For accessing and saving files
- Internet - For connecting to your OpenClaw Gateway

## Credits

- [Flutter](https://flutter.dev/) - Cross-platform UI framework
- [Riverpod](https://riverpod.dev/) - State management
- [Hive](https://docs.hivedb.dev/) - Local storage
- [flutter_markdown](https://pub.dev/packages/flutter_markdown) - Markdown rendering
- [mobile_scanner](https://pub.dev/packages/mobile_scanner) - QR code scanning
- [audioplayers](https://pub.dev/packages/audioplayers) - Audio playback
- [video_player](https://pub.dev/packages/video_player) - Video playback
- [flutter_pdfview](https://pub.dev/packages/flutter_pdfview) - PDF preview
- [image_picker](https://pub.dev/packages/image_picker) - Image picking
- [file_picker](https://pub.dev/packages/file_picker) - File picking

## License

MIT License - see [LICENSE](LICENSE) for details.

## Author

MQpeng

## Related Projects

- [OpenClaw](https://github.com/openclaw/openclaw) - Your AI agent gateway
