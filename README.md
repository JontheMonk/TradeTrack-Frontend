# TradeTrack iOS

iOS application for employee time tracking with face recognition.

## Features

- **Employee Lookup**: Search employees by ID or name
- **Face Verification**: Verify employee identity using device camera
- **Time Tracking**: Clock in/out and view time entries
- **Employee Registration**: Register new employees (admin only)

## Tech Stack

- **Language**: Swift
- **Framework**: SwiftUI
- **Architecture**: MVVM
- **Face Recognition**: Vision Framework + CoreML (InsightFace w600k_r50)
- **Networking**: URLSession with custom HTTP client
- **Testing**: XCTest (Unit, Integration, UI Tests)

## Prerequisites

- Xcode 15.0+
- iOS 17.0+
- Apple Developer Account (for device testing and TestFlight)
- Python backend running (see [TradeTrack Backend](../TradeTrack-Backend))
- **Git LFS** (for downloading large files - see Setup below)

## Setup

### Configure Build Settings

The app uses xcconfig files for environment-specific configuration:

1. **Copy template files:**
   cp Config/Development.xcconfig.template Config/Development.xcconfig
   cp Config/Production.xcconfig.template Config/Production.xcconfig
   2. **Edit `Config/Development.xcconfig`:**
  
2. **Edit `Config/Development.xcconfig`:**
   BASE_URL = http://localhost:8000
   ADMIN_API_KEY = your-dev-admin-key-here


3. **Edit `Config/Production.xcconfig`:**
   BASE_URL = https://tradetrack-backend.onrender.com
   ADMIN_API_KEY = your-production-admin-key-here


## Project Structure
```
TradeTrack-Frontend/
├── TradeTrack/              # Main app target
│   ├── Features/            # Feature modules
│   │   ├── Dashboard/       # Time tracking dashboard
│   │   ├── Lookup/          # Employee search
│   │   ├── Register/        # Employee registration
│   │   └── Verification/    # Face verification
│   ├── DI/                  # Dependency injection
│   └── ...
├── TradeTrackCore/          # Core framework
│   ├── Camera/              # Camera management
│   ├── Face/                # Face recognition pipeline
│   ├── Network/             # HTTP client and API wrappers
│   └── ...
├── TradeTrackMocks/         # Mock implementations (Debug only)
├── TradeTrackCoreTests/     # Framework unit tests
├── TradeTrackTests/         # App unit tests
└── TradeTrackUITests/       # UI tests
```

## Configuration

### Environment Variables (via xcconfig)

The app reads configuration from `Info.plist`, which pulls values from xcconfig files:

- `BASE_URL`: Backend API base URL
- `ADMIN_API_KEY`: Admin API key for employee registration

These are set in:
- `Config/Development.xcconfig` (Debug builds)
- `Config/Production.xcconfig` (Release builds)

### Build Configurations

- **Debug**: Includes mock implementations, test code, and debug logging
- **Release**: Production build with optimizations, no debug code

## Architecture

### MVVM Pattern

- **View**: SwiftUI views (`*View.swift`)
- **ViewModel**: Observable objects managing state (`*ViewModel.swift`)
- **Model**: Data models and business logic

### Dependency Injection

`AppContainer` manages all dependencies:
- Camera services
- Face recognition pipeline
- Network services
- Error handling

### Core Framework

`TradeTrackCore` provides:
- **Camera**: Device management and capture
- **Face**: Detection, validation, and embedding extraction
- **Network**: HTTP client and API service wrappers
- **Navigation**: Type-safe routing

## Development

### Adding a New Feature

1. Create feature folder in `TradeTrack/Features/`
2. Add `*View.swift` and `*ViewModel.swift`
3. Register route in `TradeTrackCore/Navigation/Routes.swift`
4. Add navigation in `AppCoordinator.swift`

### Debug vs Release

Code wrapped in `#if DEBUG` blocks:
- Mock implementations
- Test utilities
- Preview code
- Debug logging

These are automatically excluded from Release builds.

## License

Jon Snider
   
