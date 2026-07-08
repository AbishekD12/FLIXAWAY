# FLIXAWAY 🎬

Welcome to **FLIXAWAY** — a stunning, native macOS streaming application built entirely in SwiftUI. Forget paying for subscriptions and dealing with cluttered, ad-heavy websites. FLIXAWAY provides a seamless, premium, Netflix-like experience right on your Mac.

## Features ✨

*   **Native SwiftUI Interface:** Built with macOS design guidelines in mind, featuring glassmorphism, smooth animations, and a gorgeous dark mode.
*   **Multiple Streaming Providers:** Watch your favorite movies and TV shows using powerful built-in scraping networks like **VidKing** (Primary) and **VidFast/VidSrc** (Secondary/Fallback).
*   **Continue Watching:** Automatically saves your progress so you can pick up exactly where you left off. Easily remove items from your history with a single click.
*   **Bypass Anti-Hotlinking:** We use native `WKWebView` magic with injected Referer headers and custom User-Agents to seamlessly bypass CDN blocks and CORS tracking issues.
*   **Beautiful Media Metadata:** Fetches rich metadata, cast information, backdrops, and posters via the TMDB API.
*   **Custom App Icon:** Packaged as a fully native macOS `.app` bundle with a custom, high-resolution `.icns` file.

## Requirements 💻
*   macOS 12.0 or later (Tested extensively on macOS Sonoma)
*   Xcode 15+ (If you wish to build from source)
*   Swift 5.9+

## Installation 🚀

You can easily install FLIXAWAY by grabbing the pre-compiled DMG, or by building it from source.

### Option 1: Using the DMG (Recommended)
1. Navigate to the **Releases** tab on GitHub.
2. Download `FLIXAWAY.dmg`.
3. Open the DMG and drag **FLIXAWAY.app** into your `/Applications` folder.
4. Launch it and enjoy!

### Option 2: Build from Source
1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/flixaway.git
   ```
2. Open the project directory:
   ```bash
   cd flixaway/StreamMac
   ```
3. Open `Package.swift` in Xcode.
4. Hit **Product > Build** (`Cmd+B`) and **Product > Run** (`Cmd+R`).

## Under the Hood 🛠️

FLIXAWAY uses the following technologies:
- **SwiftUI** & **Combine** for reactive UI state.
- **WKWebView** tailored specifically to spoof headers and inject IFrames to fetch streams securely without browser security limitations.
- **TMDB API** for movie and TV show data fetching.

## Developer Notes 📝
This project was built to show how powerful and beautiful native macOS apps can be when fetching streaming APIs. It includes custom workarounds for `NSAppTransportSecurity` to enable HTTP streams from third-party CDNs to play natively without hitting macOS ATS blocks.

---
*Created by ABISHEK. Because I was bored and streaming websites suck.*
# FLIXAWAY
