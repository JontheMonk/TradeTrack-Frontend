import Foundation

class FaceAPI {
    func matchFace(embedding: FaceEmbedding) async throws -> String? {
        guard let url = URL(string: "http://192.168.1.138:8000/match-face") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = ["embedding": embedding.normalized]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, _) = try await URLSession.shared.data(for: request)

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let name = json["match"] as? String {
            return name
        }

        return nil
    }

    func addFace(employeeID: String, name: String, embedding: FaceEmbedding) async throws {
        guard let url = URL(string: "http://192.168.1.138:8000/add-face") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "employee_id": employeeID,
            "name": name,
            "embedding": embedding.normalized
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw NSError(domain: "FaceAPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        }
    }
}
