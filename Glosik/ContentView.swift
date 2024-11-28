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

@Observable
class SpeechGenerator {
  private var f5tts: F5TTS?
  private var player: AVPlayer?
  var isInitialized = false
  var errorMessage: String?
  var isPlaying = false
  
  func initialize() async {
    do {
      f5tts = try await F5TTS.fromPretrained(repoId: "lucasnewman/f5-tts-mlx")
      isInitialized = true
    } catch {
      errorMessage = error.localizedDescription
    }
  }
  
  func generateSpeech(text: String, progressHandler: @escaping (Double) -> Void) async throws -> MLXArray {
    guard let f5tts else {
      throw NSError(domain: "SpeechGenerator", code: -1, userInfo: [NSLocalizedDescriptionKey: "F5TTS not initialized"])
    }
    return try await f5tts.generate(text: text, progressHandler: progressHandler)
  }
  
  func saveAudio(audio: MLXArray, to outputURL: URL) throws {
    try AudioUtilities.saveAudioFile(url: outputURL, samples: audio)
    print("Saved audio to: \(outputURL.path)")
  }
  
  func playAudio(from url: URL) {
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
    isPlaying = false
  }
  
  func stopPlayback() {
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
    guard speechGenerator.isInitialized else { return }
    isGenerating = true
    progress = 0.0
    errorMessage = nil
    
    do {
      let audio = try await speechGenerator.generateSpeech(text: text) { newProgress in
        progress = newProgress
      }
      
      let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      let outputURL = documentsDirectory.appendingPathComponent("output.wav")
      try speechGenerator.saveAudio(audio: audio, to: outputURL)
      
      // Play the generated audio
      speechGenerator.playAudio(from: outputURL)
      
    } catch {
      errorMessage = "Failed to generate speech: \(error.localizedDescription)"
    }
    
    isGenerating = false
  }
}

#Preview {
  ContentView()
}
