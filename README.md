# Habla iOS

Real-time phone call translation app for the Amazon Nova AI Hackathon. Habla lets English speakers make phone calls to Spanish phone numbers with live translation powered by Amazon Nova 2 Sonic.

## Architecture

Redux-like unidirectional data flow with SwiftUI:
- **AppState** — single source of truth (value type)
- **AppAction** — all possible state changes as an enum
- **AppReducer** — pure synchronous reducer function
- **Store** — `@MainActor ObservableObject`, dispatches through middleware then reduces
- **Middleware** — protocol for side effects (network, audio, WebSocket)

## Requirements

- iOS 17.0+
- Xcode 16.0+
- Swift 6.0 (strict concurrency)
- [habla-core](https://github.com/maximbilan/habla-core) backend running

## Setup

1. Clone and run the backend:
   ```bash
   cd habla-core
   pip install -r requirements.txt
   python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
   ```

2. Open `habla-ios.xcodeproj` in Xcode

3. Set the server URL in Settings to your Mac's local IP (e.g., `http://192.168.1.x:8000`)

4. Build and run on a real device (simulator doesn't support microphone)

## How It Works

1. User dials a Spanish phone number and taps Call
2. App calls `POST /call` to initiate a Twilio PSTN call
3. App opens a WebSocket to `/ws/{call_sid}`
4. Mic audio (PCM 16-bit, 16kHz, mono) streams to backend via WebSocket
5. Backend translates English→Spanish via Nova 2 Sonic and sends to phone
6. Phone person's Spanish audio is translated to English and streamed back
7. App plays translated English audio through speaker/earpiece

## Project Structure

```
Sources/
├── App/           — @main entry point
├── Actions/       — AppAction enum
├── Core/          — AppState, AppReducer, Store, Middleware protocol
├── Models/        — CallRecord, AppError, API models, SwiftData model
├── Middlewares/   — Network, WebSocket, Audio, CallTimer, CallHistory
├── UI/            — SwiftUI views (Dialer, ActiveCall, Settings, Components)
└── Extensions/    — Formatting and theme helpers
```

## Tech Stack

- Swift 6 with strict concurrency
- SwiftUI
- AVAudioEngine (mic capture + playback)
- URLSession (REST + WebSocket)
- SwiftData (call history)
- No third-party dependencies
