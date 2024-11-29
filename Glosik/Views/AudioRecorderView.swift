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
  @ObservedObject var viewModel: ReferenceAudioViewModel
  @State private var selectedAudioURL: URL?
  @State private var referenceText = ""
  @State private var alertMessage: String?

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
        Button("OK") { alertMessage = nil }
      } message: {
        if let message = alertMessage {
          Text(message)
        }
      }
      .task {
        viewModel.loadReferenceSamples()
      }
    }
  }

  private var recordingSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Record Audio Sample")
        .font(.headline)

      HStack(spacing: 16) {
        Button(action: {
          if viewModel.isRecording {
            selectedAudioURL = viewModel.stopRecording()
          } else {
            viewModel.startRecording()
          }
        }) {
          Label(
            viewModel.isRecording ? "Stop Recording" : "Start Recording",
            systemImage: viewModel.isRecording ? "stop.circle.fill" : "record.circle.fill"
          )
        }
        .buttonStyle(.prominent)
        .accentColor(.red)
        .controlSize(.large)

        if let url = selectedAudioURL {
          Button(action: {
            if viewModel.isPlaying {
              viewModel.stopPlayback()
            } else {
              viewModel.playAudio(url: url)
            }
          }) {
            Label(
              viewModel.isPlaying ? "Stop" : "Play",
              systemImage: viewModel.isPlaying ? "stop.circle.fill" : "play.circle.fill"
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
        do {
          try viewModel.saveReferenceAudio(url: url, text: referenceText)
          alertMessage = "Reference audio and text saved successfully"
          referenceText = ""
        } catch {
          alertMessage = "Failed to save reference: \(error.localizedDescription)"
        }
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
          ForEach(viewModel.referenceSamples, id: \.audio) { sample in
            ReferenceSampleRow(
              filename: sample.audio.lastPathComponent,
              text: sample.text,
              onPlay: { viewModel.playAudio(url: sample.audio) }
            )
          }
        }
      }
      .frame(maxHeight: 200)
    }
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
