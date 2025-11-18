// CaptureSessioning.swift
import AVFoundation

protocol CaptureSessioning: AnyObject {
    /// The real AVCaptureSession to use for preview layers, etc.
    var underlyingSession: AVCaptureSession { get }

    var inputs: [AVCaptureInput] { get }
    var outputs: [AVCaptureOutput] { get }
    var isRunning: Bool { get }

    func canAddInput(_ input: AVCaptureInput) -> Bool
    func addInput(_ input: AVCaptureInput)
    func removeInput(_ input: AVCaptureInput)

    func canAddOutput(_ output: AVCaptureOutput) -> Bool
    func addOutput(_ output: AVCaptureOutput)

    func beginConfiguration()
    func commitConfiguration()
    func startRunning()
    func stopRunning()
}
