import AVFoundation
import SwiftUI

/// A class that manages audio recording and playback functionality.
///
/// This class provides methods to:
/// - Start and stop audio recording
/// - Play and stop recorded audio
/// - Save recorded audio files
/// - Convert audio files to the required format (mono, 24kHz wav)
@MainActor
final class AudioRecorder: NSObject, ObservableObject {
    /// The audio recorder instance
    private var audioRecorder: AVAudioRecorder?

    /// The audio player instance
    private var audioPlayer: AVAudioPlayer?

    /// The URL of the recorded audio file
    private(set) var recordedFileURL: URL?

    /// A flag indicating whether audio is currently being recorded
    @Published private(set) var isRecording = false

    /// A flag indicating whether audio is currently being played
    @Published private(set) var isPlaying = false

    override init() {
        super.init()
        #if os(iOS) || os(visionOS)
            setupAudioSession()
        #elseif os(macOS)
            checkMicrophonePermission()
        #endif
    }

    #if os(iOS) || os(visionOS)
        /// Sets up the audio session for recording and playback
        private func setupAudioSession() {
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.playAndRecord, mode: .default)
                try audioSession.setActive(true)
            } catch {
                print(
                    "Failed to set up audio session: \(error.localizedDescription)"
                )
            }
        }
    #endif

    #if os(macOS)
        /// Requests and checks microphone permission status
        private func checkMicrophonePermission() {
            switch AVCaptureDevice.authorizationStatus(for: .audio) {
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    if !granted {
                        print("Microphone access denied")
                    }
                }
            case .denied, .restricted:
                print("Microphone access denied")
            case .authorized:
                break
            @unknown default:
                break
            }
        }
    #endif

    /// Starts recording audio
    func startRecording() {
        let documentsPath = FileManager.default.urls(
            for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentsPath.appendingPathComponent(
            "recording.wav")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 24000.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]

        do {
            audioRecorder = try AVAudioRecorder(
                url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            recordedFileURL = audioFilename
            isRecording = true
        } catch {
            print("Could not start recording: \(error.localizedDescription)")
        }
    }

    /// Stops recording audio
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
    }

    /// Plays the recorded audio from the specified URL
    /// - Parameter url: The URL of the audio file to play
    func playRecording(url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            isPlaying = true
        } catch {
            print("Could not play recording: \(error.localizedDescription)")
        }
    }

    /// Stops playing the audio
    func stopPlayback() {
        audioPlayer?.stop()
        isPlaying = false
    }
}

extension AudioRecorder: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(
        _ recorder: AVAudioRecorder, successfully flag: Bool
    ) {
        if !flag {
            print("Recording failed")
        }
        Task { @MainActor in
            isRecording = false
        }
    }
}

extension AudioRecorder: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(
        _ player: AVAudioPlayer, successfully flag: Bool
    ) {
        if !flag {
            print("Playback failed")
        }
        Task { @MainActor in
            isPlaying = false
        }
    }
}
