//
//  CharactersViewModel.swift
//  MVVMSwiftUI
//
//  Created by Ilya Tarasov on 16.11.2026.
//

import Foundation
import Combine

@MainActor
final class CharactersViewModel: ObservableObject {
    enum ContentState: Equatable {
        case idle
        case loading
        case content
        case error(String)
        case empty
    }

    enum PaginationState: Equatable {
        case idle
        case loading
        case error(String)
    }

    struct State: Equatable {
        var characters: [CharacterEntity] = []
        var content: ContentState = .idle
        var pagination: PaginationState = .idle
        var nextPageURL: URL?
    }

    @Published private(set) var state = State()

    private let service: CharacterServiceProtocol
    
    init(service: CharacterServiceProtocol) {
        self.service = service
    }
    
    public func loadIfNeeded() async {
        guard !isLoading else { return }
        guard state.characters.isEmpty || state.nextPageURL != nil else { return }
        await load()
    }

    public func retry() async {
        await loadIfNeeded()
    }
    
    public func shouldLoadNextPage(for character: CharacterEntity) -> Bool {
        state.nextPageURL != nil && state.characters.suffix(5).contains { $0.id == character.id }
    }
}

private extension CharactersViewModel {
    var isLoading: Bool {
        state.content == .loading || state.pagination == .loading
    }

    func load() async {
        let isInitialLoad = state.characters.isEmpty
        if isInitialLoad {
            state.content = .loading
        } else {
            state.pagination = .loading
        }

        do {
            let page = try await service.fetchCharacters(from: isInitialLoad ? nil : state.nextPageURL)
            try Task.checkCancellation()
            apply(page: page)
        } catch is CancellationError {
            if isInitialLoad {
                state.content = .idle
            } else {
                state.pagination = .idle
            }
        } catch {
            guard !Task.isCancelled else { return }
            apply(error: error, isInitialLoad: isInitialLoad)
        }
    }
    
    func apply(page: CharactersPage) {
        state.nextPageURL = page.nextPageURL
        state.pagination = .idle

        guard !page.characters.isEmpty else {
            state.content = state.characters.isEmpty ? .empty : .content
            return
        }

        state.characters.append(contentsOf: page.characters)
        state.content = .content
    }
    
    func apply(error: Error, isInitialLoad: Bool) {
        let message = UserFacingErrorMapper.message(for: error)
        if isInitialLoad {
            state.content = .error(message)
        } else {
            state.pagination = .error(message)
        }
    }
}
