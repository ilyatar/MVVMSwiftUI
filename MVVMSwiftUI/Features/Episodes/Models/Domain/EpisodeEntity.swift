//
//  EpisodeEntity.swift
//  MVVMSwiftUI
//
//  Created by Ilya Tarasov on 16.11.2026.
//

import Foundation

struct EpisodeEntity: Identifiable, Equatable, Sendable {
    var id: Int
    var name: String?
    var airDate: Date?
    var episode: String?
    var characterURLs: [URL]
    var url: URL?
    var createdAt: Date?
}
