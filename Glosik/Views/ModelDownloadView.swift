import SwiftUI

struct ModelDownloadView: View {
    @StateObject private var viewModel = SpeechGeneratorViewModel()
    @Binding var isDownloadComplete: Bool
    @State private var downloadProgress: Double = 0
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.teal)
                .symbolEffect(.bounce, options: .repeating)
            
            Text("Downloading F5-TTS Model...")
                .font(.headline)
            
            ProgressView(value: downloadProgress) {
                Text("\(Int(downloadProgress * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .progressViewStyle(.linear)
            .frame(width: 200)
            
            if showError {
                VStack(spacing: 8) {
                    Text("Failed to initialize model")
                        .foregroundStyle(.red)
                        .font(.headline)
                    
                    Text(errorMessage ?? "Unknown error")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Retry") {
                        showError = false
                        downloadProgress = 0
                        Task {
                            await initializeModel()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.teal)
                }
                .padding()
            }
        }
        .padding(40)
        .task {
            await initializeModel()
        }
    }
    
    private func initializeModel() async {
        do {
            try await viewModel.initialize(downloadProgress: { progress in
                Task { @MainActor in
                    downloadProgress = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                }
            })
            isDownloadComplete = true
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
                downloadProgress = 0
            }
        }
    }
} 