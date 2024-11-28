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
      VStack(spacing: 20) {
        textInputView
        
        if isGenerating {
          progressView
        }
        
        controlButtons
      }
      .navigationTitle("Glosik")
      .task {
        await viewModel.initialize()
      }
    }
  }
  
  /// The text input view where users can enter their text.
  private var textInputView: some View {
    TextEditor(text: $text)
      .frame(height: 100)
      .padding(8)
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .stroke(Color.gray.opacity(0.2), lineWidth: 1)
      )
      .padding(.horizontal)
  }
  
  /// The progress view shown during speech generation.
  private var progressView: some View {
    HStack {
      Text("Generating speech...")
      ProgressView()
    }
    .padding()
  }
  
  /// The control buttons for generating speech and managing playback.
  private var controlButtons: some View {
    HStack {
      generateButton
      
      if let errorMessage {
        Text(errorMessage)
          .foregroundColor(.red)
          .padding()
      }
      
      if !isGenerating {
        playbackButton
      }
    }
  }
  
  /// The button for initiating speech generation.
  private var generateButton: some View {
    Button(action: {
      Task {
        await generateSpeech()
      }
    }) {
      Label {
        Text("Generate Speech")
      } icon: {
        Image(systemName: "waveform")
      }
    }
    .buttonStyle(.borderedProminent)
    .tint(.teal)
    .disabled(isGenerating || text.isEmpty)
  }
  
  /// The button for controlling audio playback.
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
      Label {
        Text(viewModel.isPlaying ? "Stop Playback" : "Play Generated Audio")
      } icon: {
        Image(systemName: viewModel.isPlaying ? "stop.fill" : "play.fill")
      }
    }
    .buttonStyle(.borderedProminent)
    .tint(.indigo)
    .padding()
  }
  
  /// Generates speech from the current text input.
  private func generateSpeech() async {
    guard viewModel.isInitialized else {
      logger.error("Attempted to generate speech before initialization")
      return
    }
    
    logger.info("Starting speech generation process")
      isGenerating = true
      errorMessage = nil
    
    do {
      let startTime = CFAbsoluteTimeGetCurrent()
      let audio = try await viewModel.generateSpeech(text: text)

      let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      let outputURL = documentsDirectory.appendingPathComponent("output.wav")
      try viewModel.saveAudio(audio: audio, to: outputURL)
      
      let duration = CFAbsoluteTimeGetCurrent() - startTime
      logger.info("Complete speech generation process finished in \(String(format: "%.2f", duration))s")
      
      viewModel.playAudio(from: outputURL)
      
    } catch {
      logger.error("Speech generation failed: \(error.localizedDescription)")
      await MainActor.run {
        errorMessage = "Failed to generate speech: \(error.localizedDescription)"
      }
    }
    
      isGenerating = false
  }
}

#Preview {
  ContentView()
} 
