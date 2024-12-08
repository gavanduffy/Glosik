import SwiftUI

public struct TextInputView: View {
  @Binding var text: String
  @FocusState private var isFocused: Bool
  
  public init(text: Binding<String>) {
    self._text = text
  }
  
  public var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("What would you like me to say?")
        .font(.title2)
        .fontWeight(.semibold)
        .foregroundStyle(.primary)
      
      Text("Enter the text you want to convert to natural-sounding speech.")
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .padding(.bottom, 4)
      
      TextEditor(text: $text)
        .font(.body)
        .focused($isFocused)
        .frame(minHeight: 120)
        .padding(12)
        .background(
          RoundedRectangle(cornerRadius: 12)
            .fill(Color(.textBackgroundColor))
        )
        .overlay(
          RoundedRectangle(cornerRadius: 12)
            .strokeBorder(isFocused ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: 1)
        )
        .overlay(
          Group {
            if text.isEmpty {
              Text("Type or paste your text here...")
                .foregroundStyle(.secondary)
                .padding(16)
                .allowsHitTesting(false)
            }
          },
          alignment: .topLeading
        )
      
      HStack {
        Text("\(text.count) characters")
          .font(.caption)
          .foregroundStyle(.secondary)
        
        Spacer()
        
        if !text.isEmpty {
          Button(action: { text = "" }) {
            Label("Clear", systemImage: "xmark.circle.fill")
              .labelStyle(.iconOnly)
              .foregroundStyle(.secondary)
          }
          .buttonStyle(.plain)
        }
      }
      .padding(.horizontal, 4)
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Text input section")
  }
}

#Preview {
  TextInputView(
    text: .constant("Hello! This is a test of the text input view.")
  )
  .padding()
}
