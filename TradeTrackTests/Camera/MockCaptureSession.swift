// MockCaptureSession.swift
import AVFoundation
@testable import TradeTrack

final class MockCaptureSession: CaptureSessioning {

    // MARK: - Stored state for tests

    var canAddInputResult: Bool = true
    var canAddOutputResult: Bool = true
    
    var shouldStartRunningSucceed: Bool = true

    private(set) var beginConfigurationCalled = false
    private(set) var commitConfigurationCalled = false
    private(set) var startRunningCalled = false
    private(set) var stopRunningCalled = false


    // MARK: - CaptureSessioning conformance

    var inputs: [CaptureDeviceInputAbility] = []
    var outputs: [VideoOutputting] = []
    var isRunning: Bool = false


    func canAddInput(_ input: CaptureDeviceInputAbility) -> Bool {
        canAddInputResult
    }

    func addInput(_ input: CaptureDeviceInputAbility) {
        inputs.append(input)
    }

    func removeInput(_ input: CaptureDeviceInputAbility) {
        inputs.removeAll { lhs in
            (lhs as AnyObject) === (input as AnyObject)
        }
    }


    func canAddOutput(_ output: VideoOutputting) -> Bool {
        canAddOutputResult
    }

    func addOutput(_ output: VideoOutputting) {
        outputs.append(output)
    }


    func beginConfiguration() {
        beginConfigurationCalled = true
    }

    func commitConfiguration() {
        commitConfigurationCalled = true
    }

    func startRunning() {
        startRunningCalled = true

        if shouldStartRunningSucceed {
            isRunning = true
        } else {
            isRunning = false
        }
    }

    func stopRunning() {
        stopRunningCalled = true
    }
}
