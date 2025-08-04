import Foundation

// MARK: - Error Codes

enum AppErrorCode: String, Equatable {
    // Camera & Model
    case pixelBufferMissingBaseAddress = "PIXEL_BUFFER_MISSING"
    case modelOutputMissing = "MODEL_OUTPUT_MISSING"
    case modelFailedToLoad = "MODEL_LOAD_FAILURE"

    // Detection
    case faceDetectionFailed = "FACE_DETECTION_FAILED"
    case noFaceFound = "NO_FACE_FOUND"

    // Preprocessing
    case facePreprocessingFailedResize = "FACE_PREPROCESSING_RESIZE_FAILED"
    case facePreprocessingFailedRender = "FACE_PREPROCESSING_RENDER_FAILED"

    // Validation
    case faceValidationMissingLandmarks = "FACE_VALIDATION_MISSING_LANDMARKS"
    case faceValidationIncompleteLandmarks = "FACE_VALIDATION_INCOMPLETE_LANDMARKS"
    case faceValidationBadRoll = "FACE_VALIDATION_BAD_ROLL"
    case faceValidationBadYaw = "FACE_VALIDATION_BAD_YAW"
    case faceValidationBadBrightness = "FACE_VALIDATION_BAD_BRIGHTNESS"
    case faceValidationBlurry = "FACE_VALIDATION_BLURRY"
    case faceValidationQualityUnavailable = "FACE_VALIDATION_QUALITY_UNAVAILABLE"

    // Backend
    case employeeAlreadyExists = "EMPLOYEE_ALREADY_EXISTS"
    case employeeNotFound = "EMPLOYEE_NOT_FOUND"
    case faceConfidenceTooLow = "FACE_CONFIDENCE_TOO_LOW"
    case noEmployeesFound = "NO_EMPLOYEES_FOUND"
    case dbError = "DB_ERROR"

    // Fallback
    case unknown = "UNKNOWN"

    // Convert backend string to AppErrorCode
    init(fromBackend code: String) {
        self = AppErrorCode(rawValue: code) ?? .unknown
    }
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

    // Camera & Model
    case .pixelBufferMissingBaseAddress, .modelOutputMissing, .modelFailedToLoad:
        return "The face recognition system had a problem starting. Please restart the app or try again."

    // Face Detection
    case .faceDetectionFailed, .noFaceFound:
        return "No face was detected. Make sure your face is clearly visible and try again."

    // Preprocessing
    case .facePreprocessingFailedResize, .facePreprocessingFailedRender:
        return "There was a problem processing the face image. Try using a clearer photo."

    // Validation
    case .faceValidationMissingLandmarks,
         .faceValidationIncompleteLandmarks,
         .faceValidationBadRoll,
         .faceValidationBadYaw,
         .faceValidationBadBrightness,
         .faceValidationBlurry,
         .faceValidationQualityUnavailable:
        return "The image didn’t meet the quality requirements. Try facing the camera directly with good lighting."

    // Backend Errors
    case .employeeAlreadyExists:
        return "This employee already exists in the system."

    case .employeeNotFound:
        return "Employee not found. Please check the details."

    case .faceConfidenceTooLow:
        return "Face not recognized. Try again with better lighting and angle."

    case .noEmployeesFound:
        return "No employees are registered in the system."

    case .dbError:
        return "Server error. Please try again later."

    // Fallback
    case .unknown:
        return "Something went wrong. Please try again."
    }
}

// MARK: - Backend Error Struct

struct BackendErrorDetail: Decodable {
    let message: String
    let code: String
}
