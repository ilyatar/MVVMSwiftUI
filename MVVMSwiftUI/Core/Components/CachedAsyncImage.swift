//
//  CachedAsyncImage.swift
//  MVVMSwiftUI
//
//  Created by Ilya Tarasov on 16.11.2026.
//


import SwiftUI

struct CachedAsyncImage: View {
    let url: URL?

    @StateObject private var loader = ImageLoader()

    var body: some View {
        Group {
            switch loader.state {
            case .idle, .loading:
                ProgressView()

            case .success(let image):
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()

            case .failure:
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            }
        }
        .task(id: url) {
            await loader.load(from: url)
        }
    }
}
