struct APIResponse<T: Decodable>: Decodable {
    let success: Bool
    let data: T?
    let code: String?
    let message: String?
}

struct Empty: Decodable {}
