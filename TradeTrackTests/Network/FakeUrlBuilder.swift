import Foundation

struct FakeFailingURLBuilder: URLBuildProtocol {
    func makeURL(from base: URL, path: String, query: [String : String?]) -> URL? {
        return nil   // simulate URL failure
    }
}
