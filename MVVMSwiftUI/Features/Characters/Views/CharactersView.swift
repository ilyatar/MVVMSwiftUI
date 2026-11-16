//
//  CharactersView.swift
//  MVVMSwiftUI
//
//  Created by Ilya Tarasov on 16.11.2026.
//

import SwiftUI

@MainActor
struct CharactersView: View {
    @StateObject private var viewModel: CharactersViewModel

    init(viewModel: CharactersViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            content
                .navigationTitle("Персонажи")
        }
        .task {
            await viewModel.loadIfNeeded()
        }
    }
    
    @ViewBuilder
    private var content: some View {
        switch viewModel.state.content {
        case .idle, .loading:
            ProgressView("Загрузка…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .content:
            List {
                ForEach(viewModel.state.characters) { character in
                    NavigationLink {
                        DetailCharacterFeature.make(character: character)
                    } label: {
                        CharacterRow(character: character)
                            .task {
                                if viewModel.shouldLoadNextPage(for: character) {
                                    await viewModel.loadIfNeeded()
                                }
                            }
                    }
                }

                switch viewModel.state.pagination {
                case .loading:
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                case .error(let message):
                    VStack(spacing: 8) {
                        Text(message)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Button("Повторить", action: requestLoad)
                    }
                    .frame(maxWidth: .infinity)
                case .idle:
                    EmptyView()
                }
            }
        case .empty:
            StatusView(systemImage: "tray", title: "Персонажей нет", message: "Обновите экран, чтобы проверить ещё раз.", actionTitle: "Повторить", action: requestLoad)
        case .error(let message):
            StatusView(systemImage: "exclamationmark.triangle", title: "Ошибка загрузки", message: message, actionTitle: "Повторить", action: requestLoad)
        }
    }

    private func requestLoad() {
        Task {
            await viewModel.retry()
        }
    }
}

private struct CharacterRow: View {
    let character: CharacterEntity
    
    var body: some View {
        HStack(spacing: 12) {
            CachedAsyncImage(url: character.imageURL)
                .frame(width: 64, height: 64)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading) {
                Text(character.name ?? "Unknown name")
                    .font(.headline)
                    .lineLimit(2)
                Text(character.status ?? "Unknown status")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
    }
}

private struct StatusView: View {
    let systemImage: String
    let title: LocalizedStringKey
    let message: String
    let actionTitle: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 44))
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
            Text(title)
                .font(.title2.bold())
            Text(message)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button(actionTitle, action: action)
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
