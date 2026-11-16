//
//  CharactersFeature.swift
//  MVVMSwiftUI
//
//  Created by Ilya Tarasov on 16.11.2026.
//

import SwiftUI

@MainActor
enum CharactersFeature {
    static func make() -> some View {
        let apiClient = APIClient()
        let service = CharacterService(apiClient: apiClient)
        let viewModel = CharactersViewModel(service: service)
        return CharactersView(viewModel: viewModel)
    }
}
