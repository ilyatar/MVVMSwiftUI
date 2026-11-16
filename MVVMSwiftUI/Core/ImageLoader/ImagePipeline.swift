//
//  ImagePipeline.swift
//  MVVMSwiftUI
//
//  Created by Ilya Tarasov on 16.11.2026.
//


@preconcurrency import UIKit

struct SendableImage: @unchecked Sendable {
    let value: UIImage
}

actor ImagePipeline {

    static let shared = ImagePipeline()

    private let cache = NSCache<NSURL, UIImage>()
    private let session: URLSession

    private struct Request {
        let task: Task<Data, Error>
        var consumers: Set<UUID>
    }

    private var inFlight: [URL: Request] = [:]

    init(session: URLSession = .shared, cacheCountLimit: Int = 1000) {
        self.session = session
        cache.countLimit = cacheCountLimit
    }

    func image(for url: URL) async throws -> SendableImage {
        // 1. Проверяем кеш
        if let image = cache.object(forKey: url as NSURL) {
            return SendableImage(value: image)
        }

        let consumerID = UUID()
        let task: Task<Data, Error>

        // 2. Подключаемся к существующему запросу
        if var request = inFlight[url] {
            request.consumers.insert(consumerID)
            inFlight[url] = request
            task = request.task
        } else {
            // 3. Создаём единственный запрос для URL
            task = Task { [session] in
                let (data, response) =
                    try await session.data(from: url)

                try Task.checkCancellation()

                guard let http = response as? HTTPURLResponse,
                      (200...299).contains(http.statusCode) else {
                    throw URLError(.badServerResponse)
                }

                return data
            }

            inFlight[url] = Request(
                task: task,
                consumers: [consumerID]
            )
        }

        defer {
            removeConsumer(consumerID, from: url)
        }

        // 4. Ожидаем общий результат
        let data = try await withTaskCancellationHandler {
            try await task.value
        } onCancel: {
            Task {
                await self.removeConsumer(consumerID, from: url)
            }
        }

        try Task.checkCancellation()

        // Другой потребитель мог уже заполнить кеш
        if let image = cache.object(forKey: url as NSURL) {
            return SendableImage(value: image)
        }

        guard let image = UIImage(data: data) else {
            throw ImageError.invalidData
        }

        // 5. Сохраняем результат
        cache.setObject(image, forKey: url as NSURL)

        return SendableImage(value: image)
    }

    private func removeConsumer(
        _ id: UUID,
        from url: URL
    ) {
        guard var request = inFlight[url],
              request.consumers.remove(id) != nil else {
            return
        }

        if request.consumers.isEmpty {
            request.task.cancel()
            inFlight.removeValue(forKey: url)
        } else {
            inFlight[url] = request
        }
    }
}

enum ImageError: Error {
    case invalidData
}
