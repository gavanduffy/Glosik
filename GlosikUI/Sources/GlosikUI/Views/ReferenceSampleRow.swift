import SwiftUI

public struct ReferenceSampleRow: View {
  let filename: String
  let text: String
  let onPlay: () -> Void

  public init(
    filename: String,
    text: String,
    onPlay: @escaping () -> Void
  ) {
    self.filename = filename
    self.text = text
    self.onPlay = onPlay
  }

  public var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text(filename)
          .font(.subheadline)
        Text(text)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer()

      Button(action: onPlay) {
        Image(systemName: "play.circle")
          .font(.title2)
      }
    }
    .padding()
    .background(Color.secondary.opacity(0.1))
    .clipShape(RoundedRectangle(cornerRadius: 8))
  }
}
