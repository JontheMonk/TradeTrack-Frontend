import AVFoundation

class CameraManager {
    let session = AVCaptureSession()
    let output = AVCaptureVideoDataOutput()

    func setupCamera(delegate: AVCaptureVideoDataOutputSampleBufferDelegate) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
                  let input = try? AVCaptureDeviceInput(device: device) else { return }

            self.session.beginConfiguration()
            self.session.addInput(input)
            self.output.setSampleBufferDelegate(delegate, queue: DispatchQueue(label: "videoQueue"))
            self.session.addOutput(self.output)
            self.session.commitConfiguration()
            self.session.startRunning()
        }
    }

    func stop() {
        if session.isRunning {
            session.stopRunning()
        }
    }
}
