import SwiftUI

public struct TimingInfoView: View {
  let generationTime: Double?
  let saveTime: Double?

  public init(
    generationTime: Double? = nil,
    saveTime: Double? = nil
  ) {
    self.generationTime = generationTime
    self.saveTime = saveTime
  }

  public var body: some View {
    HStack {
      if let generationTime {
        Text("Generation: \(String(format: "%.2fs", generationTime))")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      if let saveTime {
        Text("Save: \(String(format: "%.2fs", saveTime))")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .trailing)
    .padding(.horizontal)
  }
}

#Preview {
  TimingInfoView(
    generationTime: 2.45,
    saveTime: 0.32
  )
}
