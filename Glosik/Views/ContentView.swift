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
    @State private var text =
        "Hello! This is a test of the F5 text to speech system."

    /// A flag indicating whether speech generation is in progress.
    @State private var isGenerating = false

    /// Any error message that occurred during the process.
    @State private var errorMessage: String?

    /// The logger instance for tracking view-related events.
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.glosik",
        category: "ContentView"
    )

    @State private var isModelDownloaded = false

    var body: some View {
        Group {
            if !isModelDownloaded {
                ModelDownloadView(isDownloadComplete: $isModelDownloaded)
            } else {
                mainView
            }
        }
    }

    private var mainView: some View {
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
                        let outputURL =
                            documentsDirectory.appendingPathComponent(
                                "output.wav")
                        viewModel.playAudio(from: outputURL)
                    }
                },
                onDownload: { url in
                    do {
                        let documentsDirectory = FileManager.default.urls(
                            for: .documentDirectory, in: .userDomainMask)[0]
                        let sourceURL =
                            documentsDirectory.appendingPathComponent(
                                "output.wav")
                        try FileManager.default.copyItem(at: sourceURL, to: url)
                    } catch {
                        logger.error(
                            "Failed to save audio file: \(error.localizedDescription)"
                        )
                        errorMessage =
                            "Failed to save audio file: \(error.localizedDescription)"
                    }
                }
            )

            referenceSampleSection
        }
        .padding()
        .task {
            try? await viewModel.initialize()
            referenceViewModel.loadReferenceSamples()
        }
    }

    private var referenceSampleSection: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 16) {
                if let reference = referenceViewModel.selectedReference {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .center, spacing: 8) {
                            Image(systemName: "waveform")
                                .foregroundStyle(.teal)

                            Text(reference.audio.lastPathComponent)
                                .font(.system(.body, design: .monospaced))
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Reference Text:")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text(reference.text)
                                .font(.callout)
                                .foregroundStyle(.primary)
                                .lineLimit(3)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(textBackgroundColor)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        Button(
                            role: .destructive,
                            action: {
                                referenceViewModel.selectedReference = nil
                                viewModel.selectedReference = nil
                            }
                        ) {
                            Label(
                                "Remove Reference",
                                systemImage: "xmark.circle.fill")
                        }
                        .buttonStyle(.borderless)
                        .controlSize(.small)
                        .help("Remove the current reference sample")
                    }
                    .padding(12)
                    .background(windowBackgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                } else {
                    VStack(alignment: .center, spacing: 12) {
                        Image(systemName: "waveform.badge.plus")
                            .font(.system(size: 32))
                            .foregroundStyle(.teal)
                            .symbolEffect(.bounce, value: showReferencePicker)

                        Text("No Reference Sample Selected")
                            .font(.headline)

                        Text(
                            "Select a reference sample to guide the voice style."
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                        Button(action: { showReferencePicker = true }) {
                            Text("Choose Reference Sample")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.teal)
                        .controlSize(.regular)
                        .keyboardShortcut("r", modifiers: [.command])
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(windowBackgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                }
            }
            .frame(maxHeight: 200)
        } label: {
            Label("Reference Sample", systemImage: "waveform.circle")
                .font(.headline)
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
            .frame(minWidth: 400, minHeight: 300)
        }
        .onChange(of: referenceViewModel.selectedReference) {
            oldValue, newValue in
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
            logger.error(
                "Speech generation failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }

        isGenerating = false
    }

    private var textBackgroundColor: Color {
        #if os(iOS) || os(visionOS)
            return Color(UIColor.systemBackground)
        #else
            return Color(NSColor.textBackgroundColor)
        #endif
    }

    private var windowBackgroundColor: Color {
        #if os(iOS) || os(visionOS)
            return Color(UIColor.secondarySystemBackground)
        #else
            return Color(NSColor.windowBackgroundColor)
        #endif
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
