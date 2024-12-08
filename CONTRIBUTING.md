# Contributing to Głosik

Thank you for your interest in contributing to Głosik! This document provides guidelines and examples for contributing to the project.

## Getting Started

1. Fork the repository
2. Clone your fork:

```bash
git clone https://github.com/rudrankriyam/Glosik.git
cd Glosik
```

3. Create a new branch for your feature:

```bash
git checkout -b feature/your-feature-name
```

## Development Environment Setup

- Xcode 15.0 or later
- macOS 14.0 or later
- Swift 5.9 or later

## Project Structure

```
Glosik/
├── Glosik/          # Main application
│   ├── App/         # App entry point and configuration
│   ├── Models/      # Data models
│   ├── Views/       # SwiftUI views
│   └── Utils/       # Utility functions and extensions
└── GlosikUI/        # Reusable SwiftUI components package
    ├── Sources/
    └── Tests/
```

## Coding Guidelines

### Swift Style Guide

- Use Swift's native naming conventions
- Follow SwiftUI best practices
- Implement proper error handling

### Example: Adding a New View

```swift
import SwiftUI

struct CustomView: View {
    // MARK: - Properties
    @State private var text = ""

    // MARK: - Body
    var body: some View {
        VStack {
            TextField("Enter text", text: $text)
                .textFieldStyle(.roundedBorder)

            Button("Process") {
                processText()
            }
        }
        .padding()
    }

    // MARK: - Private Methods
    private func processText() {
        // Implementation
    }
}
```

### Example: Adding a New Model

```swift
import Foundation

struct AudioSample: Identifiable, Codable {
    let id: UUID
    let text: String
    let duration: TimeInterval
    let createdAt: Date

    init(text: String, duration: TimeInterval) {
        self.id = UUID()
        self.text = text
        self.duration = duration
        self.createdAt = Date()
    }
}
```

### Example: Adding Unit Tests

```swift
import XCTest
@testable import Glosik

final class AudioSampleTests: XCTestCase {
    func testAudioSampleCreation() {
        let sample = AudioSample(text: "Hello", duration: 2.5)

        XCTAssertEqual(sample.text, "Hello")
        XCTAssertEqual(sample.duration, 2.5)
        XCTAssertNotNil(sample.id)
    }
}
```

You are more than welcome to use Swift Testing too!

## Pull Request Process

1. Update the README.md with details of changes if needed
2. Update the documentation for any public APIs
3. Add tests for new functionality
4. Ensure all tests pass
5. Create a Pull Request with a clear title and description

Example PR title: "Add custom audio processing feature"

## Commit Message Guidelines

Follow the conventional commits specification:

```
feat: add custom audio processing
fix: resolve memory leak in audio generation
docs: update installation instructions
test: add unit tests for audio processing
style: format code according to style guide
```

## Documentation

- Document all public APIs
- Include inline comments for complex logic
- Update README.md for significant changes

Example documentation:

```swift
/// Processes audio samples using the F5-TTS model
/// - Parameters:
///   - text: The input text to convert to speech
///   - reference: Optional reference audio sample
/// - Returns: Generated audio data
/// - Throws: AudioProcessingError if generation fails
func processAudio(text: String, reference: AudioSample?) throws -> Data {
    // Implementation
}
```

## Questions or Problems?

- Open an issue for bugs
- Use discussions for questions

## License

By contributing to Głosik, you agree that your contributions will be licensed under the MIT License.
