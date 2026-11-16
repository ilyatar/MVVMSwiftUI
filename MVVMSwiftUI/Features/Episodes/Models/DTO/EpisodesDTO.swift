//
//  EpisodesDTO.swift
//  MVVMSwiftUI
//
//  Created by Ilya Tarasov on 16.11.2026.
//

import Foundation

nonisolated struct EpisodesDTO: Decodable, Sendable {
    struct Info: Decodable {
        let count: Int?
        let pages: Int?
        let next: String?
        let prev: String?
    }
    
    struct Result: Decodable {
        var id: Int
        var name: String?
        var airDate: String?
        var episode: String?
        var characters: [String]?
        var url: String?
        var created: String?
        
        enum CodingKeys: String, CodingKey {
            case id
            case name
            case airDate = "air_date"
            case episode
            case characters
            case url
            case created
        }
    }
    
    let info: Info
    let results: [Result]
}

nonisolated extension EpisodesDTO.Result {
    func toDomain() -> EpisodeEntity {
        EpisodeEntity(
            id: id,
            name: name,
            airDate: airDate.flatMap(Self.parseAirDate),
            episode: episode,
            characterURLs: characters?.compactMap(URL.init(string:)) ?? [],
            url: url.flatMap(URL.init(string:)),
            createdAt: created.flatMap(Self.parseISO8601Date)
        )
    }

    private static func parseAirDate(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.date(from: value)
    }

    private static func parseISO8601Date(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: value)
    }
}
