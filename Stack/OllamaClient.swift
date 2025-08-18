//
//  OllamaClient.swift
//  Compass
//
//  Lightweight client to call an Ollama server.
//

import Foundation

enum OllamaClientError: Error, LocalizedError {
    case invalidURL
    case httpError(Int)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Ollama host URL"
        case .httpError(let code):
            return "HTTP error code: \(code)"
        case .invalidResponse:
            return "Invalid response from Ollama"
        }
    }
}

struct OllamaClient {
    private struct GenerateRequest: Codable {
        let model: String
        let prompt: String
        let stream: Bool
    }

    private struct GenerateResponse: Codable {
        let response: String?
        let done: Bool?
    }

    static func generate(host: String, model: String, prompt: String) async throws -> String {
        let url = try makeURL(host: host, path: "/api/generate")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(GenerateRequest(model: model, prompt: prompt, stream: false))

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw OllamaClientError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else { throw OllamaClientError.httpError(http.statusCode) }

        // Try to decode as a single JSON object (stream: false)
        if let obj = try? JSONDecoder().decode(GenerateResponse.self, from: data), let text = obj.response {
            return text
        }

        // Fallback: handle NDJSON streaming concatenated in buffer
        let utf8String = String(data: data, encoding: .utf8) ?? ""
        var aggregated = ""
        for line in utf8String.split(whereSeparator: { $0 == "\n" || $0 == "\r" }) {
            if let lineData = line.data(using: .utf8),
               let part = try? JSONDecoder().decode(GenerateResponse.self, from: lineData),
               let chunk = part.response {
                aggregated += chunk
            }
        }
        if !aggregated.isEmpty { return aggregated }

        throw OllamaClientError.invalidResponse
    }

    private static func makeURL(host: String, path: String) throws -> URL {
        var normalized = host.trimmingCharacters(in: .whitespacesAndNewlines)
        if !normalized.lowercased().hasPrefix("http://") && !normalized.lowercased().hasPrefix("https://") {
            normalized = "http://" + normalized
        }
        guard var components = URLComponents(string: normalized) else { throw OllamaClientError.invalidURL }
        var p = components.path
        if !path.isEmpty {
            if p.hasSuffix("/") {
                p.removeLast()
            }
            components.path = p + path
        }
        guard let url = components.url else { throw OllamaClientError.invalidURL }
        return url
    }
}
