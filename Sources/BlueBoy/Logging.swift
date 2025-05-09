import Foundation
import Logging

/// Central logging configuration for BlueKit
public enum BlueBoyLogger {
  /// Shared logger instance
  public static var logger = Logger(label: "com.philocalyst.bluekit")

  /// Configure logging level based on debug/verbose flags
  /// - Parameters:
  ///   - debug: Enable debug level logging
  ///   - verbose: Enable verbose (trace) level logging
  public static func configure(debug: Bool, verbose: Bool) {
    let logLevel: Logger.Level

    if verbose {
      logLevel = .trace
      logger.info("Verbose logging enabled")
    } else if debug {
      logLevel = .debug
      logger.info("Debug logging enabled")
    } else {
      logLevel = .warning
    }

    // In a real implementation, we would set the log level here
    // This depends on the specific logging backend used
  }
}
