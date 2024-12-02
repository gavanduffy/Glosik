//
//  ContentView.swift
//  Glosik
//
//  Created by Rudrank Riyam on 11/29/24.
//

import GlosikUI
import MLX
import SwiftUI
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

        TimingInfoView(
          generationTime: viewModel.generationTime,
          saveTime: viewModel.saveTime
        )

        TextInputView(text: $text)

        if isGenerating {
          GenerationProgressView(progress: viewModel.generationProgress)
        }

        SpeechControlsView(
          errorMessage: errorMessage,
          isGenerating: isGenerating,
          isPlaying: viewModel.isPlaying,
          text: text,
          onGenerate: {
            Task { await generateSpeech() }
          },
          onPlayPause: {
            if viewModel.isPlaying {
              viewModel.stopPlayback()
            } else {
              let documentsDirectory = FileManager.default.urls(
                for: .documentDirectory, in: .userDomainMask)[0]
              let outputURL = documentsDirectory.appendingPathComponent("output.wav")
              viewModel.playAudio(from: outputURL)
            }
          }
        )

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
