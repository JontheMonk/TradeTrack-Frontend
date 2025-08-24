import Foundation

// MARK: - Error Codes

enum AppErrorCode: String, Equatable {
    // Camera & Session
    case cameraNotAuthorized = "CAMERA_NOT_AUTHORIZED"
    case cameraUnavailable   = "CAMERA_UNAVAILABLE"
    case cameraInputFailed   = "CAMERA_INPUT_FAILED"
    case cameraOutputFailed  = "CAMERA_OUTPUT_FAILED"
    case cameraStartFailed   = "CAMERA_START_FAILED"

    // Camera & Model
    case pixelBufferMissingBaseAddress = "PIXEL_BUFFER_MISSING"
    case modelOutputMissing            = "MODEL_OUTPUT_MISSING"
    case modelFailedToLoad             = "MODEL_LOAD_FAILURE"
    
    // Face
    case faceValidationFailed = "FACE_VALIDATION_FAILED"
    
    // Image
    case imageFailedToLoad = "IMAGE_LOAD_FAILED"

    // Preprocessing
    case facePreprocessingFailedResize = "FACE_PREPROCESSING_RESIZE_FAILED"
    case facePreprocessingFailedRender = "FACE_PREPROCESSING_RENDER_FAILED"

    // Backend
    case employeeAlreadyExists = "EMPLOYEE_ALREADY_EXISTS"
    case employeeNotFound      = "EMPLOYEE_NOT_FOUND"
    case faceConfidenceTooLow  = "FACE_CONFIDENCE_TOO_LOW"
    case noEmployeesFound      = "NO_EMPLOYEES_FOUND"
    case dbError               = "DB_ERROR"

    // Network / Transport
    case networkUnavailable = "NETWORK_UNAVAILABLE"
    case requestTimedOut    = "REQUEST_TIMED_OUT"
    case badURL             = "BAD_URL"
    case invalidResponse    = "INVALID_RESPONSE"
    case decodingFailed     = "DECODING_FAILED"

    // Fallback
    case unknown = "UNKNOWN"

    init(fromBackend code: String) {
        self = AppErrorCode(rawValue: code) ?? .unknown
    }
}



// MARK: - User Message Mapper

func userMessage(for code: AppErrorCode) -> String {
    switch code {
    // Camera & Session
    case .cameraNotAuthorized:
        return "Camera access is not allowed. Enable it in Settings > Privacy > Camera."
    case .cameraUnavailable:
        return "The front camera isn’t available on this device."
    case .cameraInputFailed:
        return "Couldn’t configure the camera input."
    case .cameraOutputFailed:
        return "Couldn’t configure the video output."
    case .cameraStartFailed:
        return "Failed to start the camera. Please try again."

    // Camera & Model
    case .pixelBufferMissingBaseAddress, .modelOutputMissing, .modelFailedToLoad:
        return "The face recognition system had a problem starting. Please restart the app or try again."
      
    // Face
    case .faceValidationFailed:
        return "Face was recgonized. Try again."
        
    // Image
    case .imageFailedToLoad:
        return "Image failed to load"
        
    // Preprocessing
    case .facePreprocessingFailedResize, .facePreprocessingFailedRender:
        return "There was a problem processing the face image. Try using a clearer photo."

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

    case .unknown:
        return "Something went wrong. Please try again."
    }
}
