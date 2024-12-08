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
  @StateObject private var viewModel = ReferenceAudioViewModel()
  @State private var selectedSidebarItem: SidebarItem? = .generate

  enum SidebarItem: String, Identifiable {
    case generate = "Generate"
    case reference = "Reference"
    
    var id: String { rawValue }
    
    var icon: String {
      switch self {
      case .generate: "waveform.circle.fill"
      case .reference: "mic.circle.fill"
      }
    }
  }

  var body: some Scene {
    WindowGroup {
      NavigationSplitView {
        List(selection: $selectedSidebarItem) {
          ForEach([SidebarItem.generate, .reference], id: \.self) { item in
            Label(item.rawValue, systemImage: item.icon)
              .tag(item)
          }
        }
        .navigationTitle("Głosik")
      } detail: {
        if let selectedItem = selectedSidebarItem {
          switch selectedItem {
          case .generate:
            ContentView(referenceViewModel: viewModel)
              .environment(deviceStat)
          case .reference:
            AudioRecorderView(viewModel: viewModel)
          }
        } else {
          Text("Select an option from the sidebar")
        }
      }
    }
  }
}
