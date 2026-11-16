import SwiftUI

struct EpisodesSectionView: View {
    let state: DetailCharacterViewModel.ViewState
    let retry: () -> Void

    @ViewBuilder
    var body: some View {
        switch state {
        case .idle, .loading:
            ProgressView("Загрузка эпизодов…")
                .frame(maxWidth: .infinity, minHeight: 140)

        case .loaded(let episodes):
            VStack(alignment: .leading, spacing: 6) {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(episodes) { episode in
                            EpisodeCard(episode: episode)
                        }
                    }
                }
                .frame(height: 260)

                if let tvMazeURL = URL(string: "https://www.tvmaze.com/shows/216/rick-and-morty") {
                    Link("Изображения: TVmaze", destination: tvMazeURL)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

        case .empty:
            Text("Эпизоды не найдены")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 80)

        case .error(let message):
            VStack(spacing: 12) {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Повторить", action: retry)
                    .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity, minHeight: 100)
        }
    }
}

private struct EpisodeCard: View {
    let episode: EpisodeEntity

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            CachedAsyncImage(url: episode.imageURL)
                .frame(maxWidth: .infinity)
                .padding(0)
                .frame(height: 96)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .accessibilityLabel("Кадр из эпизода")

            Text(value(episode.episode))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(value(episode.name))
                .font(.headline)
                .lineLimit(2)

            Spacer(minLength: 0)

            Label(formatted(episode.airDate), systemImage: "calendar")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(14)
        .frame(width: 220, height: 240, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
    }

    private func value(_ value: String?) -> String {
        guard let value, !value.isEmpty else { return "Неизвестно" }
        return value
    }

    private func formatted(_ date: Date?) -> String {
        date?.formatted(date: .long, time: .omitted) ?? "Неизвестно"
    }
}
