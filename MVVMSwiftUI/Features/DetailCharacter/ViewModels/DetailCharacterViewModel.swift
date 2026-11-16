//
//  DetailCharacterViewModel.swift
//  MVVMSwiftUI
//
//  Created by Ilya Tarasov on 16.11.2026.
//

import Foundation
import Combine

@MainActor
final class DetailCharacterViewModel: ObservableObject {
    enum ViewState: Equatable {
        case idle
        case loading
        case loaded([EpisodeEntity])
        case error(String)
        case empty
    }
    
    @Published private(set) var state: ViewState = .idle
    
    private var service: EpisodeServiceProtocol
    private var isLoading = false
    private var lastRequestedIDs: [Int] = []

    init(service: EpisodeServiceProtocol) {
        self.service = service
    }
    
    public func loadIfNeeded(ids: [Int]) async {
        guard !isLoading else { return }
        lastRequestedIDs = ids
        switch state {
        case .idle, .error:
            await load(ids)
        case .loading, .loaded, .empty:
            return
        }
    }

    public func retry() async {
        guard case .error = state else { return }
        await load(lastRequestedIDs)
    }
}

private extension DetailCharacterViewModel {
    func load(_ ids: [Int]) async {
        isLoading = true
        state = .loading

        defer {
            isLoading = false
        }

        do {
            let episodes = try await service.fetchEpisodes(ids: ids)
            try Task.checkCancellation()
            apply(episodes: episodes)
        } catch is CancellationError {
            state = .idle
        } catch {
            guard !Task.isCancelled else { return }
            apply(error: error)
        }
    }
    
    func apply(episodes: [EpisodeEntity]) {
        guard !episodes.isEmpty else {
            state = .empty
            return
        }
        state = .loaded(episodes)
    }
    
    func apply(error: Error) {
        let message = UserFacingErrorMapper.message(for: error)
        state = .error(message)
    }
}
