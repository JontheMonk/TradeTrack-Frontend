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

# Install Git LFS (one time, per machine)
git lfs install### 2. Clone the Repository

git clone [repository-url]
cd TradeTrack-FrontendGit LFS will automatically download large files during clone.

### 3. Configure Build Settings

The app uses xcconfig files for environment-specific configuration:

1. **Copy template files:**
   cp Config/Development.xcconfig.template Config/Development.xcconfig
   cp Config/Production.xcconfig.template Config/Production.xcconfig
   2. **Edit `Config/Development.xcconfig`:**
   
