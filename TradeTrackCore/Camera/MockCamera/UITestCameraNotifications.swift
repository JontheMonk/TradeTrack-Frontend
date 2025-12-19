import Foundation

extension Notification.Name {

    /// UI-test signal: camera running but no face detected.
    public static let uiTestCameraNoFace =
        Notification.Name("uiTestCamera.noFace")

    /// UI-test signal: face detected but failed validation.
    public static let uiTestCameraInvalidFace =
        Notification.Name("uiTestCamera.invalidFace")

    /// UI-test signal: valid face detected and matched.
    public static let uiTestCameraValidFace =
        Notification.Name("uiTestCamera.validFace")
}
