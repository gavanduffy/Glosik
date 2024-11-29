# Głosik

Głosik (pronounced "gwoh-seek") is an example app to showcase the F5-TTS text-to-speech system using the MLX framework. The name comes from the Polish word "głos" (voice) with the diminutive suffix "-ik".

Here is the original repository of the implementation: https://github.com/lucasnewman/f5-tts-mlx

https://github.com/user-attachments/assets/ccebcee9-13e8-400b-a189-6df926c6223c

Watch the demo above to see Głosik in action!

## Requirements

- macOS 14.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

## Installation

1. Clone the repository
2. Open `Glosik.xcodeproj` in Xcode
3. Build and run the project

## Usage

1. Enter the text you want to convert to speech
2. (Optional) Record or select a reference audio sample:
   - Go to the "Reference" tab
   - Record a new audio sample and provide reference text
   - Save it as a reference sample
   - Select it from the reference picker in the "Generate" tab
3. Click "Generate Speech" to create the audio
4. Use the playback controls to listen to the generated speech

## Features

### Reference Audio Support

You can use your own reference audio samples to influence the generated speech. The app supports:

- Recording new reference samples with accompanying text
- Managing saved reference samples
- Selecting reference samples for speech generation
- Playing back reference samples

# License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
