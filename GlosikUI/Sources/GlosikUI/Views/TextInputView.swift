import SwiftUI

public struct TextInputView: View {
  @Binding var text: String

  public init(text: Binding<String>) {
    self._text = text
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Enter Text")
        .font(.headline)

      TextEditor(text: $text)
        .frame(minHeight: 120)
        .padding(.vertical, 12)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
  }
}

#Preview {
  TextInputView(
    text: .constant("Hello! This is a test of the text input view.")
  )
  .padding()
}
