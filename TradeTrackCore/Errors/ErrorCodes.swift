import Foundation

// MARK: - Error Codes

/// A strongly-typed list of all error categories used throughout the app.
///
/// `AppErrorCode` is intentionally broad enough to cover:
/// - Camera configuration failures
/// - Face recognition pipeline issues
/// - Image preprocessing errors
/// - Backend / API problems
/// - Network / decoding / transport issues
///
/// Each case maps to a stable string code so:
/// - the backend can send structured errors,
/// - the UI can show appropriate user-facing messages,
/// - logging/debugging can rely on consistent identifiers.
public enum AppErrorCode: String, Equatable {

    // MARK: Camera & Session
    /// User denied camera permissions, or permissions not yet granted.
    case cameraNotAuthorized = "CAMERA_NOT_AUTHORIZED"

    /// No usable front camera exists (e.g., iPad simulator, certain hardware).
    case cameraUnavailable   = "CAMERA_UNAVAILABLE"

    /// Failed to create or attach a device input.
    case cameraInputFailed   = "CAMERA_INPUT_FAILED"

    /// Failed to create or attach an AVCaptureVideoDataOutput.
    case cameraOutputFailed  = "CAMERA_OUTPUT_FAILED"

    /// The session failed to start running.
    case cameraStartFailed   = "CAMERA_START_FAILED"


    // MARK: Camera & Model
    /// PixelBuffer did not expose a base address (extremely rare).
    case pixelBufferMissingBaseAddress = "PIXEL_BUFFER_MISSING"

    /// Model output did not contain the expected embedding array.
    case modelOutputMissing            = "MODEL_OUTPUT_MISSING"

    /// The CoreML model could not be loaded or initialized.
    case modelFailedToLoad             = "MODEL_LOAD_FAILURE"


    // MARK: Face
    /// Face validation rejected the detected face (bad angle, blur, mismatch).
    case faceValidationFailed = "FACE_VALIDATION_FAILED"


    // MARK: Image
    /// A user-selected or loaded image could not be decoded.
    case imageFailedToLoad = "IMAGE_LOAD_FAILED"


    // MARK: Preprocessing
    /// Image resize operation failed during face preprocessing.
    case facePreprocessingFailedResize = "FACE_PREPROCESSING_RESIZE_FAILED"

    /// Render-to-buffer step failed while building model input.
    case facePreprocessingFailedRender = "FACE_PREPROCESSING_RENDER_FAILED"


    // MARK: Backend
    case employeeAlreadyExists = "EMPLOYEE_ALREADY_EXISTS"
    case employeeNotFound      = "EMPLOYEE_NOT_FOUND"
    case faceConfidenceTooLow  = "FACE_CONFIDENCE_TOO_LOW"
    case noEmployeesFound      = "NO_EMPLOYEES_FOUND"
    case dbError               = "DB_ERROR"


    // MARK: Network / Transport
    case networkUnavailable = "NETWORK_UNAVAILABLE"
    case requestTimedOut    = "REQUEST_TIMED_OUT"
    case badURL             = "BAD_URL"
    case invalidResponse    = "INVALID_RESPONSE"
    case decodingFailed     = "DECODING_FAILED"


    // MARK: Misc
    /// Catch-all for unknown or unmapped backend error codes.
    case unknown = "UNKNOWN"

    /// Initializes an `AppErrorCode` from a backend string.
    /// Any unrecognized value maps to `.unknown`.
    init(fromBackend code: String) {
        self = AppErrorCode(rawValue: code) ?? .unknown
    }
}



// MARK: - User Message Mapper

/// Maps internal `AppErrorCode` values to friendly, user-facing messages.
///
/// These strings should stay:
/// - simple
/// - actionable
/// - non-technical
///
/// The UI always calls this instead of using error codes directly, allowing
/// you to localize or revise messages later without touching the rest of the app.
func userMessage(for code: AppErrorCode) -> String {
    switch code {

    // MARK: Camera & Session
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


    // MARK: Camera & Model
    case .pixelBufferMissingBaseAddress,
         .modelOutputMissing,
         .modelFailedToLoad:
        return "The face recognition system had a problem starting. Please restart the app or try again."


    // MARK: Face
    case .faceValidationFailed:
        return "Face was not recognized. Try again."


    // MARK: Image
    case .imageFailedToLoad:
        return "Image failed to load."


    // MARK: Preprocessing
    case .facePreprocessingFailedResize,
         .facePreprocessingFailedRender:
        return "There was a problem processing the face image. Try using a clearer photo."


    // MARK: Backend
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


    // MARK: Network / Transport
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


    // MARK: Fallback
    case .unknown:
        return "Something went wrong. Please try again."
    }
}
