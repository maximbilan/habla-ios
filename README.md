# Habla iOS

Real-time phone call translation app for the Amazon Nova AI Hackathon. Habla lets callers dial international phone numbers with live bidirectional translation powered by Amazon Nova 2 Sonic.

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

3. Configure backend URL and optional request auth token generation:
   - Copy `.env.example` to `.env`
   - Set `HABLA_BACKEND_URL` (example: `http://192.168.1.x:8000`)
   - Optional but recommended for protected backend routes:
     - Set `HABLA_SECRET`
     - Set `HABLA_APP_BUNDLE_ID` (default: `com.maximbilan.habla-ios`)
   - For Xcode Cloud, set the same environment variables in workflow settings
   - `ci_scripts/ci_post_clone.sh` generates `Sources/Config/Config.swift` from these values

4. Build and run on a real device (simulator doesn't support microphone)

## How It Works

1. User selects a destination country code (or `Any Country (+)`) in the dialer
2. User selects translation languages in Settings (`I speak` and `They speak`)
3. User dials a phone number and taps Call
4. App calls `POST /call` with `source_language` and `target_language`
5. App opens a WebSocket to `/ws/{call_sid}`
6. Mic audio (PCM 16-bit, 16kHz, mono) streams to backend via WebSocket
7. Backend translates source→target via Nova 2 Sonic and sends to phone
8. Phone audio is translated target→source and streamed back
9. App plays translated audio through speaker/earpiece

When backend auth is enabled (`HABLA_SECRET` configured on backend), iOS sends `Authorization` on REST and iOS WebSocket requests using:

`HMAC-SHA256(HABLA_SECRET, HABLA_APP_BUNDLE_ID)`

Supported translation language codes:

- `en-US`, `en-GB`, `en-AU`, `en-IN`
- `es-US`, `fr-FR`, `de-DE`, `it-IT`, `pt-BR`, `hi-IN`

The backend is the source of truth for supported languages (`GET /translation/languages`).

## Previous Flow (EN↔ES default)

The app still defaults to `en-US → es-US`, so existing behavior is unchanged until users change the language settings.

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
