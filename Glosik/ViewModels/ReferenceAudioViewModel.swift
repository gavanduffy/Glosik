import AVFoundation
import SwiftUI

// Add this struct to hold reference sample data
struct ReferenceSample: Equatable {
    let audio: URL
    let text: String

    static func == (lhs: ReferenceSample, rhs: ReferenceSample) -> Bool {
        lhs.audio == rhs.audio && lhs.text == rhs.text
    }
}

@MainActor
final class ReferenceAudioViewModel: ObservableObject {
    /// The audio recorder instance
    private var audioRecorder = AudioRecorder()

    /// List of saved reference samples
    @Published private(set) var referenceSamples: [ReferenceSample] = []

    /// Currently selected reference sample
    @Published var selectedReference: ReferenceSample?

    /// Loads all reference samples from the References directory
    func loadReferenceSamples() {
        let documentsPath = FileManager.default.urls(
            for: .documentDirectory, in: .userDomainMask)[0]
        let referencesPath = documentsPath.appendingPathComponent("References")

        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: referencesPath,
                includingPropertiesForKeys: nil
            )

            referenceSamples =
                files
                .filter { $0.pathExtension == "wav" }
                .compactMap { audioURL -> ReferenceSample? in
                    let textURL = audioURL.deletingPathExtension()
                        .appendingPathExtension("txt")
                    guard
                        let text = try? String(
                            contentsOf: textURL, encoding: .utf8)
                    else { return nil }
                    return ReferenceSample(audio: audioURL, text: text)
                }
        } catch {
            print("Failed to load references: \(error.localizedDescription)")
        }
    }

    /// Saves a new reference audio sample
    func saveReferenceAudio(url: URL, text: String) throws {
        let documentsPath = FileManager.default.urls(
            for: .documentDirectory, in: .userDomainMask)[0]
        let referencesPath = documentsPath.appendingPathComponent(
            "References", isDirectory: true)

        try FileManager.default.createDirectory(
            at: referencesPath, withIntermediateDirectories: true)

        let timestamp = ISO8601DateFormatter().string(from: Date())
        let audioURL = referencesPath.appendingPathComponent("\(timestamp).wav")
        let textURL = referencesPath.appendingPathComponent("\(timestamp).txt")

        try FileManager.default.copyItem(at: url, to: audioURL)
        try text.write(to: textURL, atomically: true, encoding: .utf8)

        loadReferenceSamples()  // Reload samples after saving
    }

    /// Plays the specified audio file
    func playAudio(url: URL) {
        audioRecorder.playRecording(url: url)
    }

    /// Stops audio playback
    func stopPlayback() {
        audioRecorder.stopPlayback()
    }

    /// Starts recording a new audio sample
    func startRecording() {
        audioRecorder.startRecording()
    }

    /// Stops recording and returns the recorded file URL
    func stopRecording() -> URL? {
        audioRecorder.stopRecording()
        return audioRecorder.recordedFileURL
    }

    /// Returns whether audio is currently recording
    var isRecording: Bool {
        audioRecorder.isRecording
    }

    /// Returns whether audio is currently playing
    var isPlaying: Bool {
        audioRecorder.isPlaying
    }
}
