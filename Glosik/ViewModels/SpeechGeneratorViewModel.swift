//
//  SpeechGeneratorViewModel.swift
//  Glosik
//
//  Created by Rudrank Riyam on 11/29/24.
//

/// A view model that manages speech generation and playback functionality.
///
/// This class handles the initialization of the F5TTS model, speech generation,
/// and audio playback operations.
import SwiftUI
import F5TTS
import MLX
import AVFoundation
import os
import Vocos

@MainActor
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

  /// Generates speech from the provided text.
  /// - Parameters:
  ///   - text: The text to convert to speech.
  ///   - progressHandler: A closure that receives progress updates during generation.
  /// - Returns: An MLXArray containing the generated audio data.
  /// - Throws: An error if speech generation fails.
  func generateSpeech(text: String, progressHandler: @escaping (Double) -> Void) async throws -> MLXArray {
    logger.info("Starting speech generation for text: \(text.prefix(50))...")
    guard let f5tts else {
      logger.error("F5TTS not initialized before generation attempt")
      throw NSError(
        domain: "SpeechGenerator",
        code: -1,
        userInfo: [NSLocalizedDescriptionKey: "F5TTS not initialized"]
      )
    }

    let startTime = CFAbsoluteTimeGetCurrent()
    let result = try await f5tts.generate(text: text, progressHandler: progressHandler)
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
  func stopPlayback() {
    logger.info("Stopping audio playback")
    player?.pause()
    player = nil
    isPlaying = false
  }

  /// Handles the completion of audio playback.
  @objc private func playerDidFinishPlaying() {
    logger.info("Audio playback completed")
    isPlaying = false
  }
}
