// RealCaptureSession.swift
import AVFoundation

final class RealCaptureSession: CaptureSessioning {

    let underlyingSession = AVCaptureSession()

    // MARK: - CaptureSessioning

    var inputs: [AVCaptureInput] {
        underlyingSession.inputs
    }

    var outputs: [AVCaptureOutput] {
        underlyingSession.outputs
    }

    var isRunning: Bool {
        underlyingSession.isRunning
    }

    func canAddInput(_ input: AVCaptureInput) -> Bool {
        underlyingSession.canAddInput(input)
    }

    func addInput(_ input: AVCaptureInput) {
        underlyingSession.addInput(input)
    }

    func removeInput(_ input: AVCaptureInput) {
        underlyingSession.removeInput(input)
    }

    func canAddOutput(_ output: AVCaptureOutput) -> Bool {
        underlyingSession.canAddOutput(output)
    }

    func addOutput(_ output: AVCaptureOutput) {
        underlyingSession.addOutput(output)
    }

    func beginConfiguration() {
        underlyingSession.beginConfiguration()
    }

    func commitConfiguration() {
        underlyingSession.commitConfiguration()
    }

    func startRunning() {
        underlyingSession.startRunning()
    }

    func stopRunning() {
        underlyingSession.stopRunning()
    }
}
