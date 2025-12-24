/// Defines the high-level states of the face verification lifecycle.
enum VerificationState: Equatable {
    /// The system is actively searching for a valid face in the camera feed.
    case detecting
    /// A face has been captured; the system is generating embeddings and communicating with the server.
    case processing
    /// Verification was successful for the specified employee.
    case matched(name: String)
}
