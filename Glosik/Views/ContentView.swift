//
//  ContentView.swift
//  Glosik
//
//  Created by Rudrank Riyam on 11/29/24.
//

import SwiftUI
import GlosikUI
import MLX
import os

struct ContentView: View {
  /// The view model that manages speech generation.
  @StateObject private var viewModel = SpeechGeneratorViewModel()
  @ObservedObject var referenceViewModel: ReferenceAudioViewModel
  @State private var showReferencePicker = false

  /// Environment object to monitor device stats
  @Environment(DeviceStat.self) private var deviceStat

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
        deviceStatsSection
        timingInfoSection
        textInputSection

        if isGenerating {
          progressSection
        }

        controlSection
        referenceSampleSection
      }
      .padding()
      .navigationTitle("Glosik")
      .task {
        await viewModel.initialize()
        referenceViewModel.loadReferenceSamples()
      }
    }
  }

  private var deviceStatsSection: some View {
    HStack {
      Label(
        "Memory: \(deviceStat.gpuUsage.activeMemory.formatted(.byteCount(style: .memory)))",
        systemImage: "memorychip"
      )
      .font(.caption)
      .foregroundStyle(.secondary)
      .help(
        """
        Active Memory: \(deviceStat.gpuUsage.activeMemory.formatted(.byteCount(style: .memory)))/\(GPU.memoryLimit.formatted(.byteCount(style: .memory)))
        Cache Memory: \(deviceStat.gpuUsage.cacheMemory.formatted(.byteCount(style: .memory)))/\(GPU.cacheLimit.formatted(.byteCount(style: .memory)))
        Peak Memory: \(deviceStat.gpuUsage.peakMemory.formatted(.byteCount(style: .memory)))
        """
      )
    }
    .frame(maxWidth: .infinity, alignment: .trailing)
    .padding(.horizontal)
  }

  private var timingInfoSection: some View {
    HStack {
      if let generationTime = viewModel.generationTime {
        Text("Generation: \(String(format: "%.2fs", generationTime))")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      if let saveTime = viewModel.saveTime {
        Text("Save: \(String(format: "%.2fs", saveTime))")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .trailing)
    .padding(.horizontal)
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
      if viewModel.generationProgress > 0 {
        ProgressView(
          "Generating Speech... \(Int(viewModel.generationProgress * 100))%",
          value: viewModel.generationProgress,
          total: 1.0
        )
        .progressViewStyle(.linear)
        .padding()
      }
    }
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
        let documentsDirectory = FileManager.default.urls(
          for: .documentDirectory, in: .userDomainMask)[0]
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

  private var referenceSampleSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Reference Sample")
        .font(.headline)

      if let reference = referenceViewModel.selectedReference {
        VStack(alignment: .leading, spacing: 4) {
          Text(reference.audio.lastPathComponent)
            .font(.subheadline)
          Text(reference.text)
            .font(.caption)
            .foregroundStyle(.secondary)

          Button("Clear Reference") {
            referenceViewModel.selectedReference = nil
            viewModel.selectedReference = nil
          }
          .buttonStyle(.borderless)
          .foregroundStyle(.red)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
      } else {
        Button("Select Reference Sample") {
          showReferencePicker = true
        }
        .buttonStyle(.bordered)
      }
    }
    .task {
      referenceViewModel.loadReferenceSamples()
    }
    .sheet(isPresented: $showReferencePicker) {
      ReferencePickerView(
        viewModel: referenceViewModel,
        onSelect: { sample in
          referenceViewModel.selectedReference = sample
          showReferencePicker = false
        }
      )
    }
    .onChange(of: referenceViewModel.selectedReference) { newValue in
      viewModel.selectedReference = newValue
    }
  }

  /// Generates speech from the current text input.
  private func generateSpeech() async {
    isGenerating = true
    errorMessage = nil

    do {
      try await viewModel.generateSpeech(text: text)
    } catch SpeechGeneratorError.notInitialized {
      errorMessage = "Please wait for initialization to complete"
    } catch {
      logger.error("Speech generation failed: \(error.localizedDescription)")
      errorMessage = error.localizedDescription
    }

    isGenerating = false
  }
}

struct ReferencePickerView: View {
  @Environment(\.dismiss) var dismiss
  @ObservedObject var viewModel: ReferenceAudioViewModel
  let onSelect: (ReferenceSample) -> Void

  var body: some View {
    NavigationStack {
      ScrollView {
        ForEach(viewModel.referenceSamples, id: \.audio) { sample in
          Button(action: { onSelect(sample) }) {
            VStack(alignment: .leading, spacing: 4) {
              Text(sample.audio.lastPathComponent)
                .font(.subheadline)
              Text(sample.text)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
        }
      }
      .navigationTitle("Select Reference")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
      }
    }
  }
}
