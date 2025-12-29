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

### 1. Install Git LFS

Git LFS is required to download the ML model and test resources:

### 2. Clone the Repository

git clone [repository-url]
cd TradeTrack-Frontend
Git LFS will automatically download large files during clone.

### 3. Configure Build Settings

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


### 4. Open in Xcode

open TradeTrack.xcodeproj

### 5. Select Configuration

- **Debug**: Uses Development.xcconfig (for local development)
- **Release**: Uses Production.xcconfig (for TestFlight/App Store)

Select in Xcode: Product → Scheme → Edit Scheme → Run → Build Configuration

## Running the App

### Simulator

1. Select a simulator
2. Press `Cmd + R` or Product → Run

**Note**: Face recognition requires a physical device with a camera. The simulator has limited camera support.

### Physical Device

1. Connect your iPhone via USB
2. Select your device in Xcode
3. Trust the developer certificate on your device
4. Press `Cmd + R`

## Project Structure
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

## Testing

### Unit Tests

# Run all unit tests
Cmd + U

# Run specific test target
# Product → Test → Select target### UI Tests

1. Select the `TradeTrackUITests` scheme
2. Press `Cmd + U`

**Note**: UI tests use mock networking and camera implementations.

## Building for TestFlight

### 1. Configure for Release

- Ensure `Production.xcconfig` has correct values
- Select "Release" build configuration
- Verify signing in Xcode (Signing & Capabilities)

### 2. Archive

1. Product → Destination → Any iOS Device
2. Product → Archive
3. Wait for archive to complete

### 3. Upload to App Store Connect

1. Window → Organizer
2. Select your archive
3. Click "Distribute App"
4. Choose "App Store Connect"
5. Follow the upload wizard

### 4. Configure TestFlight

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to your app → TestFlight
3. Add internal testers (immediate access)
4. Add external testers (requires App Review)

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

## Troubleshooting

### Build Errors

- **"Module 'TradeTrackCore' was not compiled for testing"**: Ensure you're building in Debug configuration, or remove `TradeTrackMocks` from Target Dependencies
- **"BASE_URL missing"**: Check that xcconfig files are properly configured and referenced in `Info.plist`

### Runtime Errors

- **Network errors**: Verify `BASE_URL` matches your backend URL
- **Face recognition fails**: Ensure you're testing on a physical device (simulator has limited camera support)
- **Camera permission denied**: Check Info.plist for `NSCameraUsageDescription`

### Git LFS Issues

- **Large files not downloading**: Ensure Git LFS is installed (`git lfs install`)
- **Files showing as pointers**: Run `git lfs pull` to download actual files

## License

Jon Snider
   
