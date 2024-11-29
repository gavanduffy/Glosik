//
//  DeviceStat.swift
//  Glosik
//
//  Created by Rudrank Riyam on 11/30/24.
//

import Foundation
import MLX
import Metal

/// A class that monitors and provides device statistics, particularly GPU memory usage.
///
/// This class updates GPU memory statistics every 2 seconds and provides real-time
/// information about active memory, cache memory, and peak memory usage.
@Observable
final class DeviceStat: @unchecked Sendable {
  /// The current GPU usage statistics
  @MainActor
  var gpuUsage = GPU.snapshot()

  /// The initial GPU snapshot taken at initialization
  private let initialGPUSnapshot = GPU.snapshot()

  /// Timer for periodic updates of GPU statistics
  private var timer: Timer?

  /// Initializes the DeviceStat monitor and starts periodic updates
  init() {
    timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
      self?.updateGPUUsages()
    }
  }

  /// Cleans up resources when the instance is deallocated
  deinit {
    timer?.invalidate()
  }

  /// Updates the GPU usage statistics by comparing with the initial snapshot
  private func updateGPUUsages() {
    let gpuSnapshotDelta = initialGPUSnapshot.delta(GPU.snapshot())
    DispatchQueue.main.async { [weak self] in
      self?.gpuUsage = gpuSnapshotDelta
    }
  }
}
