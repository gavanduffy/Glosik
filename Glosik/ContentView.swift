//
//  ContentView.swift
//  Glosik
//
//  Created by Rudrank Riyam on 11/29/24.
//

import SwiftUI
import F5TTS
import MLX
import Vocos
import AVFoundation
import os

// Add logger instance at the top level
private let logger = Logger(
  subsystem: Bundle.main.bundleIdentifier ?? "com.glosik",
  category: "SpeechGeneration"
)

class SpeechGenerator: ObservableObject {
  private var f5tts: F5TTS?
  private var player: AVPlayer?
  var isInitialized = false
  var errorMessage: String?
  var isPlaying = false
  
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
  
  func generateSpeech(text: String, progressHandler: @escaping (Double) -> Void) async throws -> MLXArray {
    logger.info("Starting speech generation for text: \(text.prefix(50))...")
    guard let f5tts else {
      logger.error("F5TTS not initialized before generation attempt")
      throw NSError(domain: "SpeechGenerator", code: -1, userInfo: [NSLocalizedDescriptionKey: "F5TTS not initialized"])
    }
    
    let startTime = CFAbsoluteTimeGetCurrent()
    let result = try await f5tts.generate(text: text, progressHandler: progressHandler)
    let duration = CFAbsoluteTimeGetCurrent() - startTime
    
    logger.info("Speech generation completed in \(String(format: "%.2f", duration))s")
    return result
  }
  
  func saveAudio(audio: MLXArray, to outputURL: URL) throws {
    logger.info("Saving audio to \(outputURL.path)")
    let startTime = CFAbsoluteTimeGetCurrent()
    try AudioUtilities.saveAudioFile(url: outputURL, samples: audio)
    let duration = CFAbsoluteTimeGetCurrent() - startTime
    logger.info("Audio saved successfully in \(String(format: "%.2f", duration))s")
  }
  
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
  
  @objc private func playerDidFinishPlaying() {
    logger.info("Audio playback completed")
    isPlaying = false
  }
  
  func stopPlayback() {
    logger.info("Stopping audio playback")
    player?.pause()
    player = nil
    isPlaying = false
  }
}

struct ContentView: View {
  @StateObject private var speechGenerator = SpeechGenerator()
  @State private var text = "Hello! This is a test of the F5 text to speech system."
  @State private var isGenerating = false
  @State private var progress = 0.0
  @State private var errorMessage: String?
  
  var body: some View {
    NavigationStack {
      VStack(spacing: 20) {
        TextEditor(text: $text)
          .frame(height: 100)
          .padding(8)
          .overlay(
            RoundedRectangle(cornerRadius: 8)
              .stroke(Color.gray.opacity(0.2), lineWidth: 1)
          )
          .padding(.horizontal)
        
        if isGenerating {
          ProgressView(value: progress) {
            Text("Generating speech... \(Int(progress * 100))%")
          }
          .padding()
        }
        
        Button(action: {
          Task {
            await generateSpeech()
          }
        }) {
          HStack {
            Image(systemName: "waveform")
            Text("Generate Speech")
          }
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.blue)
          .foregroundColor(.white)
          .cornerRadius(10)
        }
        .disabled(isGenerating || text.isEmpty)
        .padding()
        
        if let errorMessage {
          Text(errorMessage)
            .foregroundColor(.red)
            .padding()
        }
        
        if !isGenerating {
          Button(action: {
            if speechGenerator.isPlaying {
              speechGenerator.stopPlayback()
            } else {
              let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
              let outputURL = documentsDirectory.appendingPathComponent("output.wav")
              speechGenerator.playAudio(from: outputURL)
            }
          }) {
            HStack {
              Image(systemName: speechGenerator.isPlaying ? "stop.fill" : "play.fill")
              Text(speechGenerator.isPlaying ? "Stop" : "Play")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
          }
          .padding()
        }
      }
      .navigationTitle("Glosik")
      .task {
        await speechGenerator.initialize()
      }
    }
  }
  
  private func generateSpeech() async {
    guard speechGenerator.isInitialized else {
      logger.error("Attempted to generate speech before initialization")
      return 
    }
    
    logger.info("Starting speech generation process")
    isGenerating = true
    progress = 0.0
    errorMessage = nil
    
    do {
      let startTime = CFAbsoluteTimeGetCurrent()
      let audio = try await speechGenerator.generateSpeech(text: text) { newProgress in
        progress = newProgress
        logger.debug("Generation progress: \(Int(newProgress * 100))%")
      }
      
      let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      let outputURL = documentsDirectory.appendingPathComponent("output.wav")
      try speechGenerator.saveAudio(audio: audio, to: outputURL)
      
      let duration = CFAbsoluteTimeGetCurrent() - startTime
      logger.info("Complete speech generation process finished in \(String(format: "%.2f", duration))s")
      
      // Play the generated audio
      speechGenerator.playAudio(from: outputURL)
      
    } catch {
      logger.error("Speech generation failed: \(error.localizedDescription)")
      errorMessage = "Failed to generate speech: \(error.localizedDescription)"
    }
    
    isGenerating = false
  }
}

#Preview {
  ContentView()
}
