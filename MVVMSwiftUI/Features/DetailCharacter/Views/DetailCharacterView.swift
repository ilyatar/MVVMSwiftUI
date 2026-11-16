//
//  DetailCharacterView.swift
//  MVVMSwiftUI
//
//  Created by Ilya Tarasov on 16.11.2026.
//

import SwiftUI

@MainActor
struct DetailCharacterView: View {
    @StateObject private var viewModel: DetailCharacterViewModel
    let character: CharacterEntity

    init(
        viewModel: DetailCharacterViewModel,
        character: CharacterEntity
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.character = character
    }
    
    var body: some View {
        List {
            Section {
                CharacterHeaderView(character: character)
            }

            Section("Основная информация") {
                DetailRow(title: "Статус", value: value(character.status))
                DetailRow(title: "Вид", value: value(character.species))
                DetailRow(title: "Тип", value: value(character.type))
                DetailRow(title: "Пол", value: value(character.gender))
                DetailRow(title: "Создан", value: formatted(character.createdAt))
            }

            Section("Местоположение") {
                DetailRow(title: "Происхождение", value: value(character.origin?.name))
                DetailRow(title: "Последняя локация", value: value(character.location?.name))
            }

            Section("Эпизоды \(character.episodeIDs.count)") {
                EpisodesSectionView(
                    state: viewModel.state,
                    retry: {
                        Task {
                            await viewModel.retry()
                        }
                    }
                )
            }
        }
        .task {
            await viewModel.loadIfNeeded(ids: character.episodeIDs)
        }
        .navigationTitle("Персонаж")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func value(_ value: String?, fallback: String = "Неизвестно") -> String {
        guard let value, !value.isEmpty else { return fallback }
        return value
    }

    private func formatted(_ date: Date?) -> String {
        date?.formatted(date: .long, time: .omitted) ?? "Неизвестно"
    }
}
