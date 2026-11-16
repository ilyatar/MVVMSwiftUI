import SwiftUI

struct CharacterHeaderView: View {
    let character: CharacterEntity

    var body: some View {
        VStack(spacing: 16) {
            CachedAsyncImage(url: character.imageURL)
                .frame(maxWidth: .infinity)
                .frame(height: 280)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .accessibilityLabel("Изображение персонажа")

            Text(character.name.nonEmpty ?? "Имя неизвестно")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

private extension Optional where Wrapped == String {
    var nonEmpty: String? {
        guard let self, !self.isEmpty else { return nil }
        return self
    }
}
