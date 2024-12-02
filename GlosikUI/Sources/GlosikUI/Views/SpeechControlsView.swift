import SwiftUI

public struct SpeechControlsView: View {
  let errorMessage: String?
  let isGenerating: Bool
  let isPlaying: Bool
  let onGenerate: () -> Void
  let onPlayPause: () -> Void
  let text: String

  public init(
    errorMessage: String? = nil,
    isGenerating: Bool,
    isPlaying: Bool,
    text: String,
    onGenerate: @escaping () -> Void,
    onPlayPause: @escaping () -> Void
  ) {
    self.errorMessage = errorMessage
    self.isGenerating = isGenerating
    self.isPlaying = isPlaying
    self.text = text
    self.onGenerate = onGenerate
    self.onPlayPause = onPlayPause
  }

  public var body: some View {
    VStack(spacing: 16) {
      if let errorMessage {
        Text(errorMessage)
          .font(.callout)
          .foregroundStyle(.red)
          .multilineTextAlignment(.center)
      }

      HStack(spacing: 16) {
        Button(action: onGenerate) {
          Label("Generate Speech", systemImage: "waveform.circle.fill")
        }
        .buttonStyle(.prominent)
        .accentColor(.teal)
        .controlSize(.large)
        .disabled(isGenerating || text.isEmpty)

        if !isGenerating {
          Button(action: onPlayPause) {
            Label(
              isPlaying ? "Stop" : "Play",
              systemImage: isPlaying ? "stop.circle.fill" : "play.circle.fill"
            )
          }
          .buttonStyle(.prominent)
          .accentColor(.indigo)
          .controlSize(.large)
        }
      }
    }
  }
}

#Preview {
  VStack(spacing: 20) {
    SpeechControlsView(
      errorMessage: "An error occurred",
      isGenerating: false,
      isPlaying: false,
      text: "Hello",
      onGenerate: {},
      onPlayPause: {}
    )

    SpeechControlsView(
      isGenerating: true,
      isPlaying: false,
      text: "Hello",
      onGenerate: {},
      onPlayPause: {}
    )

    SpeechControlsView(
      isGenerating: false,
      isPlaying: true,
      text: "Hello",
      onGenerate: {},
      onPlayPause: {}
    )
  }
  .padding()
}
