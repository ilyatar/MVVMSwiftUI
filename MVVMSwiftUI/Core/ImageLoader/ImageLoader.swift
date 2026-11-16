//
//  ImageLoader.swift
//  MVVMSwiftUI
//
//  Created by Ilya Tarasov on 16.11.2026.
//

import SwiftUI
import Combine

@MainActor
final class ImageLoader: ObservableObject {

    enum State {
        case idle
        case loading
        case success(UIImage)
        case failure
    }

    @Published private(set) var state: State = .idle

    func load(from url: URL?) async {
        guard let url else {
            state = .failure
            return
        }

        state = .loading

        do {
            let image = try await ImagePipeline.shared.image(
                for: url
            )

            try Task.checkCancellation()

            state = .success(image.value)

        } catch is CancellationError {
            // Ячейка больше не нуждается в изображении
        } catch {
            guard !Task.isCancelled else { return }
            state = .failure
        }
    }
}
