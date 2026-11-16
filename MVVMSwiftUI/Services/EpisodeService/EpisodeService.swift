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
    private let tvMazeEpisodesURL = URL(string: "https://api.tvmaze.com/shows/216/episodes")
    
    func fetchEpisodes(ids: [Int]) async throws -> [EpisodeEntity] {
        let idsString = ids.map(String.init).joined(separator: ",")
        guard !idsString.isEmpty,
              let url = episodeURL?.appendingPathComponent(idsString)
        else {
            return []
        }

        let episodes: [EpisodeEntity]
        if ids.count == 1 {
            let result = try await apiClient.get(EpisodesDTO.Result.self, from: url)
            episodes = [result.toDomain()]
        } else {
            let results = try await apiClient.get([EpisodesDTO.Result].self, from: url)
            episodes = results.map { $0.toDomain() }
        }

        guard let tvMazeEpisodesURL,
              let tvMazeEpisodes = try? await apiClient.get(
                  [TVMazeEpisodeDTO].self,
                  from: tvMazeEpisodesURL
              )
        else {
            return episodes
        }

        let imagePairs: [(EpisodeNumber, URL)] = tvMazeEpisodes.compactMap { episode in
            guard let number = episode.number,
                  let imageURL = episode.image?.original ?? episode.image?.medium else {
                return nil
            }
            return (EpisodeNumber(season: episode.season, number: number), imageURL)
        }
        let images = Dictionary(uniqueKeysWithValues: imagePairs)

        return episodes.map { episode in
            guard let code = episode.episode,
                  let number = EpisodeNumber(code: code) else {
                return episode
            }
            var enrichedEpisode = episode
            enrichedEpisode.imageURL = images[number]
            return enrichedEpisode
        }
    }
}

nonisolated private struct EpisodeNumber: Hashable {
    let season: Int
    let number: Int

    init(season: Int, number: Int) {
        self.season = season
        self.number = number
    }

    init?(code: String) {
        guard code.first == "S" else { return nil }
        let components = code.dropFirst().split(separator: "E", maxSplits: 1)
        guard components.count == 2,
              let season = Int(components[0]),
              let number = Int(components[1]) else {
            return nil
        }
        self.init(season: season, number: number)
    }
}
