//
//  CharacterService.swift
//  MVVMSwiftUI
//
//  Created by Ilya Tarasov on 16.11.2026.
//
import Foundation

nonisolated struct CharactersPage: Equatable, Sendable {
    let characters: [CharacterEntity]
    let nextPageURL: URL?
}

nonisolated protocol CharacterServiceProtocol: Sendable {
    func fetchCharacters(from pageURL: URL?) async throws -> CharactersPage
}

struct CharacterService: CharacterServiceProtocol {
    let apiClient: APIClientProtocol
    private let initialPageURL = URL(string: "https://rickandmortyapi.com/api/character")
    
    func fetchCharacters(from pageURL: URL?) async throws -> CharactersPage {
        guard let url = pageURL ?? initialPageURL else {
            throw NetworkError.invalidResponse
        }

        let result = try await apiClient.get(CharactersDTO.self, from: url)
        return CharactersPage(
            characters: result.results.map { $0.toDomain() },
            nextPageURL: result.info.next.flatMap(URL.init(string:))
        )
    }
}
