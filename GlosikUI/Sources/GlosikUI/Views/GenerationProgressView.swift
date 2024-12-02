import SwiftUI

public struct GenerationProgressView: View {
  let progress: Double

  public init(progress: Double) {
    self.progress = progress
  }

  public var body: some View {
    VStack {
      if progress > 0 {
        ProgressView(
          "Generating Speech... \(Int(progress * 100))%",
          value: progress,
          total: 1.0
        )
        .progressViewStyle(.linear)
        .padding()
      }
    }
  }
}

#Preview {
  GenerationProgressView(progress: 0.65)
}
