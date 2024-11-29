//
//  GlosikApp.swift
//  Glosik
//
//  Created by Rudrank Riyam on 11/29/24.
//

import SwiftUI

@main
struct GlosikApp: App {
  /// The device statistics object
  @State private var deviceStat = DeviceStat()

  var body: some Scene {
    WindowGroup {
      TabView {
        ContentView()
          .environment(deviceStat)
          .tabItem {
            Label("Generate", systemImage: "waveform.circle.fill")
          }

        AudioRecorderView()
          .tabItem {
            Label("Reference", systemImage: "mic.circle.fill")
          }
      }
    }
  }
}
