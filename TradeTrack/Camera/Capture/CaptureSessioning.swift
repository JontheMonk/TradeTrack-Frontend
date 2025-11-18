// CaptureSessioning.swift
import AVFoundation

protocol CaptureSessioning: AnyObject {

    var inputs: [CaptureDeviceInputAbility] { get }
    var outputs: [VideoOutputting] { get }
    var isRunning: Bool { get }
    
    func canAddInput(_ input: CaptureDeviceInputAbility) -> Bool
    func addInput(_ input: CaptureDeviceInputAbility)
    func removeInput(_ input: CaptureDeviceInputAbility)

    func canAddOutput(_ output: VideoOutputting) -> Bool
    func addOutput(_ output: VideoOutputting)

    func beginConfiguration()
    func commitConfiguration()
    func startRunning()
    func stopRunning()
}
