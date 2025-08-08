import Foundation

// MARK: - Error Codes

enum AppErrorCode: String, Equatable {
    // Camera & Model
    case pixelBufferMissingBaseAddress = "PIXEL_BUFFER_MISSING"
    case modelOutputMissing = "MODEL_OUTPUT_MISSING"
    case modelFailedToLoad = "MODEL_LOAD_FAILURE"

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
    
    // Network / Transport
    case networkUnavailable = "NETWORK_UNAVAILABLE" 
    case requestTimedOut = "REQUEST_TIMED_OUT"
    case badURL = "BAD_URL"
    case invalidResponse = "INVALID_RESPONSE"
    case decodingFailed = "DECODING_FAILED"

    

    // Fallback
    case unknown = "UNKNOWN"

    // Convert backend string to AppErrorCode
    init(fromBackend code: String) {
        self = AppErrorCode(rawValue: code) ?? .unknown
    }
}

// MARK: - App-Wide Error Struct

struct AppError: Error, LocalizedError {
    let code: AppErrorCode
    let underlyingError: Error?

    init(code: AppErrorCode, underlyingError: Error? = nil) {
        self.code = code
        self.underlyingError = underlyingError
    }

    var errorDescription: String? {
        userMessage(for: code)
    }
}

// MARK: - User Message Mapper

func userMessage(for code: AppErrorCode) -> String {
    switch code {
    case .pixelBufferMissingBaseAddress, .modelOutputMissing, .modelFailedToLoad:
        return "The face recognition system had a problem starting. Please restart the app or try again."

    case .facePreprocessingFailedResize, .facePreprocessingFailedRender:
        return "There was a problem processing the face image. Try using a clearer photo."

    case .faceValidationMissingLandmarks,
         .faceValidationIncompleteLandmarks,
         .faceValidationBadRoll,
         .faceValidationBadYaw,
         .faceValidationBadBrightness,
         .faceValidationBlurry,
         .faceValidationQualityUnavailable:
        return "The image didn’t meet the quality requirements. Try facing the camera directly with good lighting."

    // Backend-specific
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

    // Network / Transport
    case .networkUnavailable:
        return "No internet connection. Please check your network settings and try again."

    case .requestTimedOut:
        return "The request took too long. Please try again."

    case .badURL:
        return "There was an internal app error (invalid request URL). Please contact support."

    case .invalidResponse:
        return "Received an invalid response from the server. Please try again later."

    case .decodingFailed:
        return "The server returned unexpected data. Please try again later."

    // Fallback
    case .unknown:
        return "Something went wrong. Please try again."
    }
}


