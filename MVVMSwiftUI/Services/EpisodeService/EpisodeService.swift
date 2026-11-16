//
//  EpisodeService.swift
//  MVVMSwiftUI
//
//  Created by Ilya Tarasov on 16.11.2026.
//

import Foundation

nonisolated protocol EpisodeServiceProtocol: Sendable {
    func fetchEpisodes(ids: [Int]) async throws -> [EpisodeEntity]
}

struct EpisodeService: EpisodeServiceProtocol {
    let apiClient: APIClientProtocol
    private let episodeURL = URL(string: "https://rickandmortyapi.com/api/episode")
    
    func fetchEpisodes(ids: [Int]) async throws -> [EpisodeEntity] {
        let idsString = ids.map(String.init).joined(separator: ",")
        guard !idsString.isEmpty,
              let url = episodeURL?.appendingPathComponent(idsString)
        else {
            return []
        }

        if ids.count == 1 {
            let result = try await apiClient.get(EpisodesDTO.Result.self, from: url)
            return [result.toDomain()]
        }

        let results = try await apiClient.get([EpisodesDTO.Result].self, from: url)
        return results.map { $0.toDomain() }
    }
}
