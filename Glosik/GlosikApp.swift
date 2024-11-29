//
//  GlosikApp.swift
//  Glosik
//
//  Created by Rudrank Riyam on 11/29/24.
//

import SwiftUI

@main
struct GlosikApp: App {
  @State private var deviceStat = DeviceStat()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(deviceStat)
    }
  }
}
