import Foundation

class EmployeeAPI {

    func verifyFace(embedding: FaceEmbedding, employeeID: String) async throws -> Bool {
        let url = try validatedURL("https://tradetrack-backend.onrender.com/verify-face")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let verifyRequest = embedding.toVerifyRequest(employeeId: employeeID)
        request.httpBody = try JSONEncoder().encode(verifyRequest)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            try handleBackendError(data)
        }

        return true
    }

    func addEmployee(employee: EmployeeInput) async throws {
        let url = try validatedURL("https://tradetrack-backend.onrender.com/add-employee")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        request.httpBody = try JSONEncoder().encode(employee)

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
