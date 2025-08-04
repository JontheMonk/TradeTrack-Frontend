import Foundation

class FaceAPI {

    func matchFace(embedding: FaceEmbedding) async throws -> String? {
        let url = try validatedURL("https://tradetrack-backend.onrender.com/match-face")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = ["embedding": embedding.normalized]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            try handleBackendError(data)
        }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let name = json["match"] as? String {
            return name
        }

        return nil
    }

    func addFace(employeeID: String, name: String, embedding: FaceEmbedding) async throws {
        let url = try validatedURL("https://tradetrack-backend.onrender.com/add-face")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "employee_id": employeeID,
            "name": name,
            "embedding": embedding.normalized
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            try handleBackendError(data)
        }
    }

    private func validatedURL(_ string: String) throws -> URL {
        guard let url = URL(string: string) else {
            throw URLError(.badURL)
        }
        return url
    }

    private func handleBackendError(_ data: Data) throws -> Never {
        let backendError = try? JSONDecoder().decode(BackendErrorDetail.self, from: data)
        throw AppError(code: AppErrorCode(fromBackend: backendError?.code ?? "UNKNOWN"))
    }
}
