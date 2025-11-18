// MockCaptureSession.swift
import AVFoundation
@testable import TradeTrack

final class MockCaptureSession: CaptureSessioning {

    // MARK: - Stored state for tests

    var inputsStorage: [CaptureDeviceInputAbility] = []
    var outputsStorage: [VideoOutputting] = []
    var isRunningStorage: Bool = false

    var canAddInputResult: Bool = true
    var canAddOutputResult: Bool = true

    private(set) var beginConfigurationCalled = false
    private(set) var commitConfigurationCalled = false
    private(set) var startRunningCalled = false
    private(set) var stopRunningCalled = false


    // MARK: - CaptureSessioning conformance

    var inputs: [CaptureDeviceInputAbility] { inputsStorage }
    var outputs: [VideoOutputting] { outputsStorage }
    var isRunning: Bool { isRunningStorage }


    func canAddInput(_ input: CaptureDeviceInputAbility) -> Bool {
        canAddInputResult
    }

    func addInput(_ input: CaptureDeviceInputAbility) {
        inputsStorage.append(input)
    }

    func removeInput(_ input: CaptureDeviceInputAbility) {
        inputsStorage.removeAll { lhs in
            // identity comparison for reference types
            (lhs as AnyObject) === (input as AnyObject)
        }
    }


    func canAddOutput(_ output: VideoOutputting) -> Bool {
        canAddOutputResult
    }

    func addOutput(_ output: VideoOutputting) {
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
