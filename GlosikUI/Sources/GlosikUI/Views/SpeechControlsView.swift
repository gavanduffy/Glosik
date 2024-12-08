import SwiftUI
import UniformTypeIdentifiers

public struct SpeechControlsView: View {
  let errorMessage: String?
  let isGenerating: Bool
  let isPlaying: Bool
  let onGenerate: () -> Void
  let onPlayPause: () -> Void
  let onDownload: (URL) -> Void
  let text: String
  @State private var showingSaveDialog = false

  public init(
    errorMessage: String? = nil,
    isGenerating: Bool,
    isPlaying: Bool,
    text: String,
    onGenerate: @escaping () -> Void,
    onPlayPause: @escaping () -> Void,
    onDownload: @escaping (URL) -> Void
  ) {
    self.errorMessage = errorMessage
    self.isGenerating = isGenerating
    self.isPlaying = isPlaying
    self.text = text
    self.onGenerate = onGenerate
    self.onPlayPause = onPlayPause
    self.onDownload = onDownload
  }

  public var body: some View {
    VStack(spacing: 16) {
      if let errorMessage {
        Text(errorMessage)
          .font(.callout)
          .foregroundStyle(.red)
          .multilineTextAlignment(.center)
          .padding(.horizontal)
          .padding(.vertical, 8)
          .background(Color.red.opacity(0.1))
          .clipShape(RoundedRectangle(cornerRadius: 8))
      }

      HStack(spacing: 12) {
        Button(action: onGenerate) {
          Label {
            Text("Generate Speech")
              .fontWeight(.medium)
          } icon: {
            Image(systemName: "waveform.circle.fill")
              .imageScale(.large)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .tint(.teal)
        .controlSize(.large)
        .disabled(isGenerating || text.isEmpty)
        .help("Generate speech from the entered text")

        if !isGenerating {
          Button(action: onPlayPause) {
            Label {
              Text(isPlaying ? "Stop" : "Play")
                .fontWeight(.medium)
            } icon: {
              Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                .imageScale(.large)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
          }
          .buttonStyle(.borderedProminent)
          .tint(.indigo)
          .controlSize(.large)
          .help(isPlaying ? "Stop playback" : "Play generated speech")

          Button(action: { showingSaveDialog = true }) {
            Label {
              Text("Save Audio")
                .fontWeight(.medium)
            } icon: {
              Image(systemName: "square.and.arrow.down.fill")
                .imageScale(.large)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
          }
          .buttonStyle(.borderedProminent)
          .tint(.blue)
          .controlSize(.large)
          .help("Save generated audio to a file")
          .disabled(text.isEmpty)
          .fileExporter(
            isPresented: $showingSaveDialog,
            document: AudioFile(initialText: text),
            contentType: .wav,
            defaultFilename: "generated_speech.wav"
          ) { result in
            if case .success(let url) = result {
              onDownload(url)
            }
          }
        }
      }
      .padding(.top, 4)
    }
  }
}

private struct AudioFile: FileDocument {
  let initialText: String
  
  static var readableContentTypes: [UTType] { [.wav] }
  
  init(initialText: String) {
    self.initialText = initialText
  }
  
  init(configuration: ReadConfiguration) throws {
    initialText = ""
  }
  
  func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
    return FileWrapper(regularFileWithContents: Data())
  }
}

#Preview {
  VStack(spacing: 20) {
    SpeechControlsView(
      errorMessage: "An error occurred during speech generation. Please try again.",
      isGenerating: false,
      isPlaying: false,
      text: "Hello",
      onGenerate: {},
      onPlayPause: {},
      onDownload: { _ in }
    )

    SpeechControlsView(
      isGenerating: true,
      isPlaying: false,
      text: "Hello",
      onGenerate: {},
      onPlayPause: {},
      onDownload: { _ in }
    )

    SpeechControlsView(
      isGenerating: false,
      isPlaying: true,
      text: "Hello",
      onGenerate: {},
      onPlayPause: {},
      onDownload: { _ in }
    )
  }
  .padding()
  .frame(width: 500)
}
