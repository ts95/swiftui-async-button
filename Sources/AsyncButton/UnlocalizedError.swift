import Foundation

struct UnlocalizedError: LocalizedError, Codable {
    let errorDescription: String?

    init(error: Error) {
        self.errorDescription = error.localizedDescription
    }
}

