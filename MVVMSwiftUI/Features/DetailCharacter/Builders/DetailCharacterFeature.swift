//
//  DetailCharacterFeature.swift
//  MVVMSwiftUI
//
//  Created by Ilya Tarasov on 16.11.2026.
//

import SwiftUI

@MainActor
enum DetailCharacterFeature {
    static func make(character: CharacterEntity) -> some View {
        let apiClient = APIClient()
        let service = EpisodeService(apiClient: apiClient)
        let viewModel = DetailCharacterViewModel(service: service)
        return DetailCharacterView(
            viewModel: viewModel,
            character: character
        )
    }
}
