//
//  ContentView.swift
//  Glosik
//
//  Created by Rudrank Riyam on 11/29/24.
//

/// The main content view of the Glosik app.
///
/// This view provides the user interface for text-to-speech generation,
/// including text input, generation controls, and playback functionality.
import SwiftUI
import os

struct ContentView: View {
  /// The view model that manages speech generation.
  @StateObject private var viewModel = SpeechGeneratorViewModel()

  /// The text to be converted to speech.
  @State private var text = "Hello! This is a test of the F5 text to speech system."

  /// A flag indicating whether speech generation is in progress.
  @State private var isGenerating = false

  /// Any error message that occurred during the process.
  @State private var errorMessage: String?

  /// The logger instance for tracking view-related events.
  private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "com.glosik",
    category: "ContentView"
  )

  var body: some View {
    NavigationStack {
      VStack(spacing: 24) {
        textInputSection

        if isGenerating {
          progressSection
        }

        controlSection
      }
      .padding()
      .navigationTitle("Glosik")
      .task {
        await viewModel.initialize()
      }
    }
  }

  private var textInputSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Enter Text")
        .font(.headline)

      TextEditor(text: $text)
        .frame(minHeight: 120)
        .padding(.vertical, 12)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
  }

  private var progressSection: some View {
    VStack {
      ProgressView()
        .controlSize(.large)

      Text("Generating speech...")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .padding(.vertical)
  }

  private var controlSection: some View {
    VStack(spacing: 16) {
      if let errorMessage {
        Text(errorMessage)
          .font(.callout)
          .foregroundStyle(.red)
          .multilineTextAlignment(.center)
      }

      HStack(spacing: 16) {
        generateButton
        if !isGenerating {
          playbackButton
        }
      }
    }
  }

  private var generateButton: some View {
    Button(action: {
      Task {
        await generateSpeech()
      }
    }) {
      Label("Generate Speech", systemImage: "waveform.circle.fill")
    }
    .buttonStyle(.prominent)
    .accentColor(.teal)
    .controlSize(.large)
    .disabled(isGenerating || text.isEmpty)
  }

  private var playbackButton: some View {
    Button(action: {
      if viewModel.isPlaying {
        viewModel.stopPlayback()
      } else {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let outputURL = documentsDirectory.appendingPathComponent("output.wav")
        viewModel.playAudio(from: outputURL)
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

  /// Generates speech from the current text input.
  private func generateSpeech() async {
    isGenerating = true
    errorMessage = nil
    
    do {
      try await viewModel.generateSpeech(text: text)
    } catch {
      logger.error("Speech generation failed: \(error.localizedDescription)")
      errorMessage = "Failed to generate speech: \(error.localizedDescription)"
    }
    
    isGenerating = false
  }
}

extension ButtonStyle where Self == ProminentButtonStyle {
  static var prominent: ProminentButtonStyle {
    ProminentButtonStyle()
  }
}

struct ProminentButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.headline)
      .frame(maxWidth: .infinity)
      .padding()
      .background(configuration.isPressed ? Color.accentColor.opacity(0.8) : Color.accentColor)
      .foregroundStyle(.white)
      .clipShape(RoundedRectangle(cornerRadius: 12))
  }
}

#Preview {
  ContentView()
}
