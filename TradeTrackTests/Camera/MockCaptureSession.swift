// MockCaptureSession.swift
import AVFoundation
@testable import TradeTrack

final class MockCaptureSession: CaptureSessioning {

    // MARK: - Underlying session (for preview compatibility)
    // Not actually used in tests, but satisfies the protocol.
    let underlyingSession = AVCaptureSession()

    // MARK: - Stored state used by tests

    var inputsStorage: [AVCaptureInput] = []
    var outputsStorage: [AVCaptureOutput] = []
    var isRunningStorage: Bool = false

    var canAddInputResult: Bool = true
    var canAddOutputResult: Bool = true

    private(set) var beginConfigurationCalled = false
    private(set) var commitConfigurationCalled = false
    private(set) var startRunningCalled = false
    private(set) var stopRunningCalled = false

    // MARK: - CaptureSessioning

    var inputs: [AVCaptureInput] { inputsStorage }
    var outputs: [AVCaptureOutput] { outputsStorage }
    var isRunning: Bool { isRunningStorage }

    func canAddInput(_ input: AVCaptureInput) -> Bool {
        canAddInputResult
    }

    func addInput(_ input: AVCaptureInput) {
        inputsStorage.append(input)
    }

    func removeInput(_ input: AVCaptureInput) {
        inputsStorage.removeAll { $0 === input }
    }

    func canAddOutput(_ output: AVCaptureOutput) -> Bool {
        canAddOutputResult
    }

    func addOutput(_ output: AVCaptureOutput) {
        outputsStorage.append(output)
    }

    func beginConfiguration() {
        beginConfigurationCalled = true
    }

    func commitConfiguration() {
        commitConfigurationCalled = true
    }

    func startRunning() {
        startRunningCalled = true
        isRunningStorage = true
    }

    func stopRunning() {
        stopRunningCalled = true
        isRunningStorage = false
    }
}
