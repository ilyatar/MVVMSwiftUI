//
//  CharacterEntity.swift
//  MVVMSwiftUI
//
//  Created by Ilya Tarasov on 16.11.2026.
//

import Foundation

struct CharacterEntity: Identifiable, Equatable, Sendable {
    struct Location: Equatable {
        let name: String?
        let url: URL?
    }
    
    let id: Int
    let name: String?
    let status: String?
    let species: String?
    let type: String?
    let gender: String?
    let origin: Location?
    let location: Location?
    let imageURL: URL?
    let episodeIDs: [Int]
    let url: URL?
    let createdAt: Date?
}
