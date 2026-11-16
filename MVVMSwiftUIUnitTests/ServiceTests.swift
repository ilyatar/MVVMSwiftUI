import Foundation
import Testing
@testable import MVVMSwiftUI

@Suite("Service tests", .serialized)
struct ServiceTests {
    @Test
    func `Character service maps page and next URL`() async throws {
        let expectedNextURL = try #require(
            URL(string: "https://rickandmortyapi.com/api/character?page=2")
        )
        let responseData = Data(
            """
            {
              "info": {
                "count": 1,
                "pages": 2,
                "next": "https://rickandmortyapi.com/api/character?page=2",
                "prev": null
              },
              "results": [
                {
                  "id": 1,
                  "name": "Rick Sanchez",
                  "status": "Alive",
                  "species": "Human",
                  "type": "",
                  "gender": "Male",
                  "origin": {"name": "Earth", "url": "https://example.com/origin/1"},
                  "location": {"name": "Citadel", "url": "https://example.com/location/1"},
                  "image": "https://example.com/rick.png",
                  "episode": ["https://rickandmortyapi.com/api/episode/1"],
                  "url": "https://rickandmortyapi.com/api/character/1",
                  "created": "2017-11-04T18:48:46.250Z"
                }
              ]
            }
            """.utf8
        )
        URLProtocolStub.setHandler { request in
            let url = try #require(request.url)
            #expect(url.absoluteString == "https://rickandmortyapi.com/api/character")
            let response = try #require(
                HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
            )
            return (response, responseData)
        }
        defer { URLProtocolStub.clearHandler() }

        let service = CharacterService(apiClient: makeAPIClient())
        let page = try await service.fetchCharacters(from: nil)

        #expect(page.characters.count == 1)
        #expect(page.characters.first?.name == "Rick Sanchez")
        #expect(page.characters.first?.episodeIDs == [1])
        #expect(page.nextPageURL == expectedNextURL)
    }

    @Test
    func `Episode service decodes a single object`() async throws {
        let responseData = Data(
            """
            {
              "id": 1,
              "name": "Pilot",
              "air_date": "December 2, 2013",
              "episode": "S01E01",
              "characters": [],
              "url": "https://rickandmortyapi.com/api/episode/1",
              "created": "2017-11-10T12:56:33.798Z"
            }
            """.utf8
        )
        let tvMazeData = Data(
            """
            [
              {
                "season": 1,
                "number": 1,
                "image": {
                  "medium": "https://static.tvmaze.com/pilot-medium.jpg",
                  "original": "https://static.tvmaze.com/pilot-original.jpg"
                }
              }
            ]
            """.utf8
        )
        URLProtocolStub.setHandler { request in
            let url = try #require(request.url)
            let data: Data
            if url.host == "api.tvmaze.com" {
                #expect(url.path == "/shows/216/episodes")
                data = tvMazeData
            } else {
                #expect(url.path == "/api/episode/1")
                data = responseData
            }
            let response = try #require(
                HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
            )
            return (response, data)
        }
        defer { URLProtocolStub.clearHandler() }

        let service = EpisodeService(apiClient: makeAPIClient())
        let episodes = try await service.fetchEpisodes(ids: [1])

        #expect(episodes.count == 1)
        #expect(episodes.first?.name == "Pilot")
        #expect(episodes.first?.episode == "S01E01")
        #expect(episodes.first?.airDate != nil)
        #expect(episodes.first?.imageURL?.absoluteString == "https://static.tvmaze.com/pilot-original.jpg")
    }

    @Test
    func `Episode service decodes an array`() async throws {
        let responseData = Data(
            """
            [
              {
                "id": 1,
                "name": "Pilot",
                "air_date": "December 2, 2013",
                "episode": "S01E01",
                "characters": [],
                "url": "https://rickandmortyapi.com/api/episode/1",
                "created": "2017-11-10T12:56:33.798Z"
              },
              {
                "id": 2,
                "name": "Lawnmower Dog",
                "air_date": "December 9, 2013",
                "episode": "S01E02",
                "characters": [],
                "url": "https://rickandmortyapi.com/api/episode/2",
                "created": "2017-11-10T12:56:33.916Z"
              }
            ]
            """.utf8
        )
        let tvMazeData = Data(
            """
            [
              {
                "season": 1,
                "number": 1,
                "image": {
                  "medium": "https://static.tvmaze.com/pilot-medium.jpg",
                  "original": null
                }
              },
              {
                "season": 1,
                "number": 2,
                "image": {
                  "medium": "https://static.tvmaze.com/episode-2-medium.jpg",
                  "original": "https://static.tvmaze.com/episode-2-original.jpg"
                }
              }
            ]
            """.utf8
        )
        URLProtocolStub.setHandler { request in
            let url = try #require(request.url)
            let data: Data
            if url.host == "api.tvmaze.com" {
                #expect(url.path == "/shows/216/episodes")
                data = tvMazeData
            } else {
                #expect(url.path == "/api/episode/1,2")
                data = responseData
            }
            let response = try #require(
                HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
            )
            return (response, data)
        }
        defer { URLProtocolStub.clearHandler() }

        let service = EpisodeService(apiClient: makeAPIClient())
        let episodes = try await service.fetchEpisodes(ids: [1, 2])

        #expect(episodes.map(\.id) == [1, 2])
        #expect(episodes[0].imageURL?.absoluteString == "https://static.tvmaze.com/pilot-medium.jpg")
        #expect(episodes[1].imageURL?.absoluteString == "https://static.tvmaze.com/episode-2-original.jpg")
    }
}
