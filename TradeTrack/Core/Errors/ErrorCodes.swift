import Foundation

// MARK: - Error Codes

enum AppErrorCode: String, Equatable {
    case pixelBufferMissingBaseAddress = "PIXEL_BUFFER_MISSING"
    case modelOutputMissing = "MODEL_OUTPUT_MISSING"
    case modelFailedToLoad = "MODEL_LOAD_FAILURE"
    case unknown = "UNKNOWN"
    case faceDetectionFailed = "FACE_DETECTION_FAILED"
    case noFaceFound = "NO_FACE_FOUND"
}

// MARK: - App-Wide Error Struct

struct AppError: Error, LocalizedError, Equatable {
    let code: AppErrorCode

    var errorDescription: String? {
        userMessage(for: code)
    }
}


// MARK: - User Message Mapper

func userMessage(for code: AppErrorCode) -> String {
    switch code {
    case .pixelBufferMissingBaseAddress:
        return "There was a problem accessing the camera input."
    case .modelOutputMissing:
        return "Face recognition failed. Please try again."
    case .modelFailedToLoad:
        return "The face system failed to start. Try restarting the app."
    case .faceDetectionFailed:
        return "Face detection failed. Please try again."
    case .noFaceFound:
        return "No face was detected in the image. Try a different one."
    case .unknown:
        return "Something went wrong. Please try again."
    }
}
