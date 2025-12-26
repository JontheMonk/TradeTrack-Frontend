//
//  MockURLProtocol.swift
//  TradeTrackTests
//
//  A URLProtocol subclass used to intercept *all* network traffic in tests.
//  It lets tests fully control:
//    - the incoming URLRequest (captured before URLSession mutates it)
//    - the returned Data + HTTPURLResponse
//    - thrown URLError / custom errors
//
//  This avoids hitting the real network and gives complete determinism
//  for testing HTTPClient and related code.
//

import Foundation

final class MockURLProtocol: URLProtocol {

    // MARK: - Test Inspection Hooks

    /// The exact URLRequest that URLSession sends.
    ///
    /// Captured inside startLoading() because:
    ///   - URLRequest is a struct and can be copied/mutated by Foundation
    ///   - the request passed into the requestHandler closure is often
    ///     a bridged Objective-C copy with missing httpBody
    ///
    /// Tests should read this to assert headers, body, URL, method, etc.
    static var lastRequest: URLRequest?

    /// Closure supplied by each test to define how the mock responds.
    ///
    /// Receives the *bridged* request and must return:
    ///   - Data (response body)
    ///   - URLResponse (usually HTTPURLResponse)
    ///
    /// Or can throw to simulate URLError or custom failures.
    static var requestHandler: ((URLRequest) throws -> (Data, URLResponse))?

    // MARK: - URLProtocol Overrides

    /// Intercept *every* request for sessions that use this protocol.
    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    /// Required for async/await compatibility.
    ///
    /// Modern URLSession uses the task-based version internally when bridging
    /// async/await calls, so without this override, the mock may never run.
    override class func canInit(with task: URLSessionTask) -> Bool {
        true
    }

    /// No canonicalization needed — just return the request unchanged.
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    /// Entry point when URLSession starts loading a request.
    ///
    /// This method:
    ///   - captures the *real* outgoing request (with correct body & headers)
    ///   - forwards the request into the test-provided handler
    ///   - injects the mock response back into URLSession
    override func startLoading() {
        // Try to get the fully rewritten request
        let rewritten = URLProtocol.property(
            forKey: "NSURLSessionKeyActualURLRequest",
            in: request
        ) as? URLRequest

        let finalRequest = rewritten ?? request

        // Save it for tests
        MockURLProtocol.lastRequest = finalRequest

        guard let handler = MockURLProtocol.requestHandler else {
            fatalError("MockURLProtocol.requestHandler must be set before making requests.")
        }

        do {
            let (data, response) = try handler(finalRequest)

            client?.urlProtocol(self,
                                didReceive: response,
                                cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)

        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }


    /// Required override — no cleanup needed.
    override func stopLoading() {}
}
