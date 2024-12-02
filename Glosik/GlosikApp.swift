//
//  GlosikApp.swift
//  Glosik
//
//  Created by Rudrank Riyam on 11/29/24.
//

import GlosikUI
import SwiftUI

@main
struct GlosikApp: App {
  /// The device statistics object
  @State private var deviceStat = DeviceStat()
  @StateObject private var viewModel = ReferenceAudioViewModel()

  var body: some Scene {
    WindowGroup {
      TabView {
        ContentView(referenceViewModel: viewModel)
          .environment(deviceStat)
          .tabItem {
            Label("Generate", systemImage: "waveform.circle.fill")
          }

        AudioRecorderView(viewModel: viewModel)
          .tabItem {
            Label("Reference", systemImage: "mic.circle.fill")
          }
      }
    }
  }
}
