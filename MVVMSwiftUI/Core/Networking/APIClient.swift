//
//  APIClient.swift
//  MVVMSwiftUI
//
//  Created by Ilya Tarasov on 16.11.2026.
//

import Foundation

nonisolated protocol APIClientProtocol: Sendable {
    func get<Response: Decodable & Sendable>(_ type: Response.Type, from url: URL) async throws -> Response
}

struct APIClient: APIClientProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
    }

    func get<Response: Decodable & Sendable>(_ type: Response.Type, from url: URL) async throws -> Response {
        do {
            let (data, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.unacceptableStatusCode(httpResponse.statusCode)
            }
            do {
                return try decoder.decode(Response.self, from: data)
            } catch {
                throw NetworkError.decodingFailed(String(describing: error))
            }
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as NetworkError {
            throw error
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch {
            if Task.isCancelled {
                throw CancellationError()
            }
            throw NetworkError.transport(error.localizedDescription)
        }
    }
}
