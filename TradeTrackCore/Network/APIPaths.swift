import Foundation

/// Central source of truth for all backend endpoint paths.
/// Using a shared enum or struct ensures that the App and the Mocks
/// are always calling the same paths.
public enum APIPaths {
    public static let search = "/employees/search"
    public static let verify = "/employees/verify"
    public static let register = "/employees/"
}
