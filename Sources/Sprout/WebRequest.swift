import Foundation
import NIOHTTP1

enum ParameterError: Error {
    case unsupportedContentType
    case invalidEncoding
}

struct WebRequest {
    let head: HTTPRequestHead
    let body: Data

    var method: HTTPMethod { head.method }
    var target: String { head.uri }

    func query() throws -> [(String, String)] {
        let parts = target.split(
            separator: "?", maxSplits: 1, omittingEmptySubsequences: false
        )

        return parts.count == 2 ? try Self.decodePairs(String(parts[1])) : []
    }

    func form() throws -> [(String, String)] {
        let raw = head.headers.first(name: "content-type") ?? ""
        let mediaType = raw.split(separator: ";", maxSplits: 1)
            .first.map(String.init)?.trimmingCharacters(in: .whitespaces)
            .lowercased()
        guard mediaType == "application/x-www-form-urlencoded" else {
            throw ParameterError.unsupportedContentType
        }
        guard let text = String(data: body, encoding: .utf8) else {
            throw ParameterError.invalidEncoding
        }

        return try Self.decodePairs(text)
    }

    private static func decodePairs(_ text: String) throws -> [(String, String)] {
        if text.isEmpty { return [] }
        return try text.split(separator: "&", omittingEmptySubsequences: false)
            .map { field in 
                let pair = field.split(
                    separator: "=", maxSplits: 1, omittingEmptySubsequences: false
                )
                func decode(_ raw: Substring) throws -> String {
                    let spaced = String(raw).replacingOccurrences(of: "+", with: " ")
                    guard let value = spaced.removingPercentEncoding else {
                        throw ParameterError.invalidEncoding
                    }

                    return value
                }

                return try (decode(pair[0]), decode(pair.count == 2 ? pair[1] : ""))
            }
    }
}

final class RequestState {
    private var values: [String: String] = [:]
    subscript(_ key: String) -> String? {
        get { values[key] }
        set { values[key] = newValue }
    }
}
