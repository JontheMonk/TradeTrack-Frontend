import Foundation
import SwiftUI
import Vision
import CoreML

class FaceRecognitionManager {

    private let embedder: FaceEmbedder
    private let validator = FaceValidator()

    init() throws {
        self.embedder = try FaceEmbedder()
    }

    func preprocessFace(from image: CIImage, face: VNFaceObservation) -> CVPixelBuffer? {
        let cropped = FaceCropper.crop(from: image, using: face)
        guard let resized = ImageResizer.resize(cropped, to: CGSize(width: 112, height: 112)) else {
            return nil
        }
        return PixelBufferConverter.renderToPixelBuffer(resized, size: CGSize(width: 112, height: 112))
    }
    

    func runModel(on pixelBuffer: CVPixelBuffer) -> [Float]? {
        try? embedder.embed(from: pixelBuffer)
    }

    func isFaceValid(pixelBuffer: CVPixelBuffer, face: VNFaceObservation) -> Bool {
        validator.passesValidation(buffer: pixelBuffer, face: face)
    }

    func matchFace(embedding: [Float]) async throws -> String? {
        guard let url = URL(string: "http://192.168.1.138:8000/match-face") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = ["embedding": embedding]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, _) = try await URLSession.shared.data(for: request)

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let name = json["match"] as? String {
            return name
        }

        return nil
    }

    func addFace(employeeID: String, name: String, embedding: [Float]) async throws {
        guard let url = URL(string: "http://192.168.1.138:8000/add-face") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "employee_id": employeeID,
            "name": name,
            "embedding": embedding
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw NSError(domain: "FaceAPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        }
    }

}
