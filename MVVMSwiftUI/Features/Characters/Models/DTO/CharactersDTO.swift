//
//  CharactersDTO.swift
//  MVVMSwiftUI
//
//  Created by Ilya Tarasov on 16.11.2026.
//
import Foundation

nonisolated struct CharactersDTO: Decodable, Sendable {
    struct Info: Decodable {
        let count: Int?
        let pages: Int?
        let next: String?
        let prev: String?
    }
    
    struct Location: Decodable {
        let name: String?
        let url: String?
    }
    
    struct Result: Decodable {
        let id: Int
        let name: String?
        let status: String?
        let species: String?
        let type: String?
        let gender: String?
        let origin: Location?
        let location: Location?
        let image: String?
        let episode: [String]?
        let url: String?
        let created: String?
    }
    
    let info: Info
    let results: [Result]
}

nonisolated extension CharactersDTO.Result {
    func toDomain() -> CharacterEntity {
        CharacterEntity(
            id: id,
            name: name,
            status: status,
            species: species,
            type: type,
            gender: gender,
            origin: CharacterEntity.Location(
                name: origin?.name,
                url: origin?.url.flatMap(URL.init(string:))
            ),
            location: CharacterEntity.Location(
                name: location?.name,
                url: location?.url.flatMap(URL.init(string:))
            ),
            imageURL: image.flatMap(URL.init(string:)),
            episodeIDs: episode?.compactMap { episodeURL in
                URL(string: episodeURL).flatMap { Int($0.lastPathComponent) }
            } ?? [],
            url: url.flatMap(URL.init(string:)),
            createdAt: created.flatMap(Self.parseISO8601Date)
        )
    }

    private static func parseISO8601Date(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: value)
    }
}
