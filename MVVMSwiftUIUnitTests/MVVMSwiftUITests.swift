import Foundation
import Testing
@testable import MVVMSwiftUI

@Suite("ViewModel tests")
struct ViewModelTests {
    @Test
    @MainActor
    func `Characters initial page is loaded`() async throws {
        let nextURL = try #require(URL(string: "https://example.com/character?page=2"))
        let characters = [makeCharacter(id: 1, name: "Rick")]
        let service = CharacterServiceStub(
            results: [.success(CharactersPage(characters: characters, nextPageURL: nextURL))]
        )
        let viewModel = CharactersViewModel(service: service)

        await viewModel.loadIfNeeded()

        #expect(viewModel.state.characters == characters)
        #expect(viewModel.state.content == .content)
        #expect(viewModel.state.pagination == .idle)
        #expect(viewModel.state.nextPageURL == nextURL)
    }

    @Test
    @MainActor
    func `Characters next page is appended`() async throws {
        let nextURL = try #require(URL(string: "https://example.com/character?page=2"))
        let firstCharacter = makeCharacter(id: 1, name: "Rick")
        let secondCharacter = makeCharacter(id: 2, name: "Morty")
        let service = CharacterServiceStub(
            results: [
                .success(CharactersPage(characters: [firstCharacter], nextPageURL: nextURL)),
                .success(CharactersPage(characters: [secondCharacter], nextPageURL: nil))
            ]
        )
        let viewModel = CharactersViewModel(service: service)

        await viewModel.loadIfNeeded()
        await viewModel.loadIfNeeded()

        #expect(viewModel.state.characters == [firstCharacter, secondCharacter])
        #expect(viewModel.state.content == .content)
        #expect(viewModel.state.pagination == .idle)
        #expect(viewModel.state.nextPageURL == nil)
    }

    @Test
    @MainActor
    func `Pagination error preserves loaded characters`() async throws {
        let nextURL = try #require(URL(string: "https://example.com/character?page=2"))
        let character = makeCharacter(id: 1, name: "Rick")
        let service = CharacterServiceStub(
            results: [
                .success(CharactersPage(characters: [character], nextPageURL: nextURL)),
                .failure(.expected)
            ]
        )
        let viewModel = CharactersViewModel(service: service)

        await viewModel.loadIfNeeded()
        await viewModel.loadIfNeeded()

        #expect(viewModel.state.characters == [character])
        #expect(viewModel.state.content == .content)
        guard case .error = viewModel.state.pagination else {
            Issue.record("Expected pagination error")
            return
        }
    }

    @Test
    @MainActor
    func `Characters retry repeats failed initial request`() async {
        let character = makeCharacter(id: 1, name: "Rick")
        let service = CharacterServiceStub(
            results: [
                .failure(.expected),
                .success(CharactersPage(characters: [character], nextPageURL: nil))
            ]
        )
        let viewModel = CharactersViewModel(service: service)

        await viewModel.loadIfNeeded()
        await viewModel.retry()

        #expect(viewModel.state.characters == [character])
        #expect(viewModel.state.content == .content)
    }

    @Test
    @MainActor
    func `Detail loads episodes`() async {
        let episodes = [makeEpisode(id: 1, name: "Pilot")]
        let viewModel = DetailCharacterViewModel(
            service: EpisodeServiceStub(result: .success(episodes))
        )

        await viewModel.loadIfNeeded(ids: [1])

        #expect(viewModel.state == .loaded(episodes))
    }

    @Test
    @MainActor
    func `Detail exposes loading error`() async {
        let viewModel = DetailCharacterViewModel(
            service: EpisodeServiceStub(result: .failure(.expected))
        )

        await viewModel.loadIfNeeded(ids: [1])

        guard case .error(let message) = viewModel.state else {
            Issue.record("Expected detail loading error")
            return
        }
        #expect(!message.isEmpty)
    }

    @Test
    @MainActor
    func `Detail retry uses identifiers from failed request`() async {
        let episodes = [makeEpisode(id: 1, name: "Pilot")]
        let viewModel = DetailCharacterViewModel(
            service: EpisodeServiceStub(
                results: [
                    .failure(.expected),
                    .success(episodes)
                ]
            )
        )

        await viewModel.loadIfNeeded(ids: [1])
        await viewModel.retry()

        #expect(viewModel.state == .loaded(episodes))
    }
}
