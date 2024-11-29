import AVFoundation
import SwiftUI

/// A view that provides audio recording functionality and manages reference audio samples.
///
/// This view allows users to:
/// - Record audio samples
/// - Play recorded audio
/// - Save recorded audio as reference samples
/// - View and manage saved reference samples
struct AudioRecorderView: View {
  /// The audio recorder instance
  @StateObject private var audioRecorder = AudioRecorder()

  /// The currently selected audio file URL
  @State private var selectedAudioURL: URL?

  /// Text for the reference audio
  @State private var referenceText = ""

  /// Alert message to show
  @State private var alertMessage: String?

  /// List of saved reference samples
  @State private var referenceSamples: [(audio: URL, text: String)] = []

  var body: some View {
    NavigationStack {
      VStack(spacing: 24) {
        recordingSection

        if let url = selectedAudioURL {
          referenceSection(url: url)
        }

        referenceSamplesSection

        Spacer()
      }
      .padding()
      .navigationTitle("Reference Audio")
      .alert("Save Result", isPresented: .constant(alertMessage != nil)) {
        Button("OK") {
          alertMessage = nil
        }
      } message: {
        if let message = alertMessage {
          Text(message)
        }
      }
      .task {
        loadReferenceSamples()
      }
    }
  }

  private var recordingSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Record Audio Sample")
        .font(.headline)

      HStack(spacing: 16) {
        Button(action: {
          if audioRecorder.isRecording {
            audioRecorder.stopRecording()
            selectedAudioURL = audioRecorder.recordedFileURL
          } else {
            audioRecorder.startRecording()
          }
        }) {
          Label(
            audioRecorder.isRecording ? "Stop Recording" : "Start Recording",
            systemImage: audioRecorder.isRecording ? "stop.circle.fill" : "record.circle.fill"
          )
        }
        .buttonStyle(.prominent)
        .accentColor(.red)
        .controlSize(.large)

        if let url = selectedAudioURL {
          Button(action: {
            if audioRecorder.isPlaying {
              audioRecorder.stopPlayback()
            } else {
              audioRecorder.playRecording(url: url)
            }
          }) {
            Label(
              audioRecorder.isPlaying ? "Stop" : "Play",
              systemImage: audioRecorder.isPlaying ? "stop.circle.fill" : "play.circle.fill"
            )
          }
          .buttonStyle(.prominent)
          .accentColor(.indigo)
          .controlSize(.large)
        }
      }
    }
  }

  private func referenceSection(url: URL) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Reference Text")
        .font(.headline)

      TextEditor(text: $referenceText)
        .frame(minHeight: 120)
        .padding(.vertical, 12)
        .clipShape(RoundedRectangle(cornerRadius: 12))

      Button(action: {
        saveReferenceAudio(url: url)
      }) {
        Label("Save as Reference", systemImage: "square.and.arrow.down.fill")
      }
      .buttonStyle(.prominent)
      .accentColor(.teal)
      .controlSize(.large)
      .disabled(referenceText.isEmpty)
    }
  }

  private var referenceSamplesSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Saved References")
        .font(.headline)

      ScrollView {
        LazyVStack(spacing: 12) {
          ForEach(referenceSamples, id: \.audio) { sample in
            ReferenceSampleRow(
              filename: sample.audio.lastPathComponent,
              text: sample.text,
              onPlay: { audioRecorder.playRecording(url: sample.audio) }
            )
          }
        }
      }
      .frame(maxHeight: 200)
    }
  }

  /// Saves the reference audio and text
  private func saveReferenceAudio(url: URL) {
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let referencesPath = documentsPath.appendingPathComponent("References", isDirectory: true)

    do {
      try FileManager.default.createDirectory(at: referencesPath, withIntermediateDirectories: true)

      let timestamp = ISO8601DateFormatter().string(from: Date())
      let audioURL = referencesPath.appendingPathComponent("\(timestamp).wav")
      let textURL = referencesPath.appendingPathComponent("\(timestamp).txt")

      try FileManager.default.copyItem(at: url, to: audioURL)
      try referenceText.write(to: textURL, atomically: true, encoding: .utf8)

      alertMessage = "Reference audio and text saved successfully"
      referenceText = ""
    } catch {
      alertMessage = "Failed to save reference: \(error.localizedDescription)"
    }
  }

  /// Loads all reference samples from the References directory
  private func loadReferenceSamples() {
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let referencesPath = documentsPath.appendingPathComponent("References")

    do {
      let files = try FileManager.default.contentsOfDirectory(
        at: referencesPath,
        includingPropertiesForKeys: nil
      )

      referenceSamples =
        try files
        .filter { $0.pathExtension == "wav" }
        .compactMap { audioURL -> (URL, String)? in
          let textURL = audioURL.deletingPathExtension().appendingPathExtension("txt")
          guard let text = try? String(contentsOf: textURL, encoding: .utf8) else { return nil }
          return (audioURL, text)
        }
    } catch {
      print("Failed to load references: \(error.localizedDescription)")
    }
  }

  /// Gets all reference samples
  /// - Returns: Array of tuples containing audio URLs and their corresponding text
  func getReferenceSamples() -> [(audio: URL, text: String)] {
    return referenceSamples
  }

  /// Gets a specific reference sample by index
  /// - Parameter index: Index of the desired reference sample
  /// - Returns: Tuple containing audio URL and text, or nil if index is invalid
  func getReferenceSample(at index: Int) -> (audio: URL, text: String)? {
    guard index >= 0 && index < referenceSamples.count else { return nil }
    return referenceSamples[index]
  }
}

struct ReferenceSampleRow: View {
  let filename: String
  let text: String
  let onPlay: () -> Void

  var body: some View {
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

#Preview {
  AudioRecorderView()
}
