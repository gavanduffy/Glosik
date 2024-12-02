//
//  SpeechGeneratorViewModel.swift
//  Glosik
//
//  Created by Rudrank Riyam on 11/29/24.
//

import AVFoundation
import F5TTS
import MLX
/// A view model that manages speech generation and playback functionality.
///
/// This class handles the initialization of the F5TTS model, speech generation,
/// and audio playback operations.
import SwiftUI
import Vocos
import os

/// Errors that can occur during speech generation operations.
enum SpeechGeneratorError: LocalizedError {
  case notInitialized
  case generationFailed(String)
  case audioSaveFailed(String)

  var errorDescription: String? {
    switch self {
    case .notInitialized:
      return "Speech generator is not initialized"
    case .generationFailed(let message):
      return "Failed to generate speech: \(message)"
    case .audioSaveFailed(let message):
      return "Failed to save audio: \(message)"
    }
  }
}

final class SpeechGeneratorViewModel: ObservableObject {
  /// The F5TTS model instance used for speech generation.
  private var f5tts: F5TTS?

  /// The audio player for playing generated speech.
  private var player: AVPlayer?

  /// A flag indicating whether the F5TTS model is initialized.
  @Published private(set) var isInitialized = false

  /// Any error message that occurred during speech generation.
  @Published var errorMessage: String?

  /// A flag indicating whether audio is currently playing.
  @Published private(set) var isPlaying = false

  /// The logger instance for tracking speech generation events.
  private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "com.glosik",
    category: "SpeechGeneration"
  )

  /// The current progress of speech generation, from 0 to 1
  @Published private(set) var generationProgress: Double = 0

  /// Time taken for speech generation in seconds
  @Published private(set) var generationTime: Double?

  /// Time taken for audio saving in seconds
  @Published private(set) var saveTime: Double?

  /// Currently selected reference sample
  @Published var selectedReference: ReferenceSample?

  /// Initializes the F5TTS model.
  func initialize() async {
    logger.info("Initializing F5TTS model...")
    do {
      let startTime = CFAbsoluteTimeGetCurrent()
      f5tts = try await F5TTS.fromPretrained(repoId: "lucasnewman/f5-tts-mlx")
      let duration = CFAbsoluteTimeGetCurrent() - startTime
      logger.info("F5TTS model initialized successfully in \(String(format: "%.2f", duration))s")
      isInitialized = true
    } catch {
      logger.error("Failed to initialize F5TTS: \(error.localizedDescription)")
      errorMessage = error.localizedDescription
    }
  }

  /// Generates raw speech audio data from the provided text.
  /// - Parameter text: The text to convert to speech.
  /// - Returns: An MLXArray containing the generated audio data.
  /// - Throws: An error if speech generation fails.
  func generateSpeechAudio(text: String) async throws -> MLXArray {
    generationProgress = 0

    logger.info("Starting speech generation for text: \(text.prefix(50))...")

    if f5tts == nil {
      await initialize()
    }

    let startTime = CFAbsoluteTimeGetCurrent()
    let result: MLXArray

    if let reference = selectedReference {
      logger.info("Using reference audio: \(reference.audio.lastPathComponent)")
      result =
        try await f5tts?.generate(
          text: text,
          referenceAudioURL: reference.audio,
          referenceAudioText: reference.text
        ) { progress in
          Task { @MainActor in
            self.generationProgress = progress
            self.logger.debug("Generation progress: \(progress * 100)%")
          }
        } ?? []
    } else {
      result =
        try await f5tts?.generate(text: text) { progress in
          Task { @MainActor in
            self.generationProgress = progress
            self.logger.debug("Generation progress: \(progress * 100)%")
          }
        } ?? []
    }

    resetF5TTS()

    let duration = CFAbsoluteTimeGetCurrent() - startTime
    logger.info("Speech generation completed in \(String(format: "%.2f", duration))s")
    return result
  }

  /// Saves the generated audio to a file.
  /// - Parameters:
  ///   - audio: The MLXArray containing the audio data.
  ///   - outputURL: The URL where the audio file should be saved.
  /// - Throws: An error if the save operation fails.
  func saveAudio(audio: MLXArray, to outputURL: URL) throws {
    logger.info("Saving audio to \(outputURL.path)")
    let startTime = CFAbsoluteTimeGetCurrent()

    try AudioUtilities.saveAudioFile(url: outputURL, samples: audio)

    let duration = CFAbsoluteTimeGetCurrent() - startTime
    logger.info("Audio saved successfully in \(String(format: "%.2f", duration))s")
  }

  /// Plays audio from the specified URL.
  /// - Parameter url: The URL of the audio file to play.
  func playAudio(from url: URL) {
    logger.info("Starting audio playback from \(url.lastPathComponent)")
    // Stop any existing playback
    player?.pause()
    player = nil

    // Create new player with the audio file
    let playerItem = AVPlayerItem(url: url)
    player = AVPlayer(playerItem: playerItem)

    // Add observer for playback completion
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(playerDidFinishPlaying),
      name: .AVPlayerItemDidPlayToEndTime,
      object: playerItem
    )

    isPlaying = true
    player?.play()
  }

  /// Stops the current audio playback.
  /// This method pauses the audio player, sets the player to nil,
  /// and updates the playback state to indicate that audio is no longer playing.
  func stopPlayback() {
    logger.info("Stopping audio playback")
    player?.pause()  // Safely unwrap the optional player
    player = nil
    isPlaying = false
  }

  /// Handles the completion of audio playback.
  @objc private func playerDidFinishPlaying() {
    logger.info("Audio playback completed")
    isPlaying = false
  }

  /// Generates speech from the provided text and saves it to a file.
  /// - Parameter text: The text to convert to speech.
  /// - Throws: An error if speech generation or saving fails.
  func generateSpeech(text: String) async throws {
    generationTime = nil
    saveTime = nil

    logger.info("Starting speech generation process")

    guard isInitialized else {
      logger.error("Attempted to generate speech before initialization")
      throw SpeechGeneratorError.notInitialized
    }

    let startTime = CFAbsoluteTimeGetCurrent()
    let audio = try await generateSpeechAudio(text: text)
    generationTime = CFAbsoluteTimeGetCurrent() - startTime

    let saveStartTime = CFAbsoluteTimeGetCurrent()
    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[
      0]
    let outputURL = documentsDirectory.appendingPathComponent("output.wav")
    try saveAudio(audio: audio, to: outputURL)
    saveTime = CFAbsoluteTimeGetCurrent() - saveStartTime

    let duration = CFAbsoluteTimeGetCurrent() - startTime
    logger.info(
      "Complete speech generation process finished in \(String(format: "%.2f", duration))s")

    playAudio(from: outputURL)
  }

  /// Resets the F5TTS instance and related state.
  /// This method clears the current F5TTS instance and sets initialization status to false.
  /// Call this when you need to reinitialize the model with fresh state.
  func resetF5TTS() {
    logger.info("Resetting F5TTS instance")
    f5tts = nil
  }
}
