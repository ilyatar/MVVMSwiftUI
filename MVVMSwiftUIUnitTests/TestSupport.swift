import Foundation
@testable import MVVMSwiftUI

enum TestError: Error {
    case expected
}

actor CharacterServiceStub: CharacterServiceProtocol {
    private var results: [Result<CharactersPage, TestError>]

    init(results: [Result<CharactersPage, TestError>]) {
        self.results = results
    }

    func fetchCharacters(from pageURL: URL?) async throws -> CharactersPage {
        guard !results.isEmpty else {
            throw TestError.expected
        }
        return try results.removeFirst().get()
    }
}

actor EpisodeServiceStub: EpisodeServiceProtocol {
    private var results: [Result<[EpisodeEntity], TestError>]

    init(result: Result<[EpisodeEntity], TestError>) {
        self.results = [result]
    }

    init(results: [Result<[EpisodeEntity], TestError>]) {
        self.results = results
    }

    func fetchEpisodes(ids: [Int]) async throws -> [EpisodeEntity] {
        guard !results.isEmpty else {
            throw TestError.expected
        }
        return try results.removeFirst().get()
    }
}

final class URLProtocolStub: URLProtocol, @unchecked Sendable {
    typealias Handler = @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)

    private static let lock = NSLock()
    nonisolated(unsafe) private static var requestHandler: Handler?

    static func setHandler(_ handler: @escaping Handler) {
        lock.lock()
        requestHandler = handler
        lock.unlock()
    }

    static func clearHandler() {
        lock.lock()
        requestHandler = nil
        lock.unlock()
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.lock.lock()
        let handler = Self.requestHandler
        Self.lock.unlock()

        guard let handler else {
            client?.urlProtocol(self, didFailWithError: TestError.expected)
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

func makeAPIClient() -> APIClient {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [URLProtocolStub.self]
    return APIClient(session: URLSession(configuration: configuration))
}

func makeCharacter(id: Int, name: String) -> CharacterEntity {
    CharacterEntity(
        id: id,
        name: name,
        status: "Alive",
        species: "Human",
        type: nil,
        gender: "Male",
        origin: nil,
        location: nil,
        imageURL: nil,
        episodeIDs: [],
        url: nil,
        createdAt: nil
    )
}

func makeEpisode(id: Int, name: String) -> EpisodeEntity {
    EpisodeEntity(
        id: id,
        name: name,
        airDate: nil,
        episode: "S01E01",
        characterURLs: [],
        url: nil,
        createdAt: nil
    )
}
