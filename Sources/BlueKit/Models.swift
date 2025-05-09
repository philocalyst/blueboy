import ArgumentParser
import CoreBluetooth
import Foundation

/// ▰▰▰ Bluetooth state representation ▰▰▰
public enum State: String, CaseIterable, ExpressibleByArgument {
  case on, off, toggle
  case one = "1"
  case zero = "0"

  /// Convert state to boolean value
  public var boolValue: Bool {
    switch self {
    case .on, .one: return true
    case .off, .zero: return false
    case .toggle: return false  // Toggle is handled separately
    }
  }
}

/// ▰▰▰ Output format options ▰▰▰
public enum Format: String, CaseIterable, ExpressibleByArgument {
  case `default`
  case newDefault = "new-default"
  case json
  case jsonPretty = "json-pretty"
}

/// ▰▰▰ Comparison operations ▰▰▰
public enum Operation: String, CaseIterable, ExpressibleByArgument {
  case gt = ">"
  case ge = ">="
  case lt = "<"
  case le = "<="
  case eq = "="
  case ne = "!="
  case greaterThan = "gt"
  case greaterThanOrEqual = "ge"
  case lessThan = "lt"
  case lessThanOrEqual = "le"
  case equal = "eq"
  case notEqual = "ne"
}

/// ▰▰▰ Device output configuration ▰▰▰
public struct DevicePrintOptions {
  /// Show device Bluetooth address
  public var showAddress: Bool

  /// Show device name
  public var showName: Bool

  /// Show device connection status
  public var showConnected: Bool

  /// Show signal strength
  public var showRSSI: Bool

  /// Show pairing status
  public var showPairing: Bool

  /// Show if connection is incoming
  public var showIsIncoming: Bool

  /// Show all device information
  public static let all = DevicePrintOptions(
    showAddress: true, showName: true, showConnected: true,
    showRSSI: true, showPairing: true, showIsIncoming: true
  )

  /// Show basic device information
  public static let basic = DevicePrintOptions(
    showAddress: true, showName: true, showConnected: true,
    showRSSI: false, showPairing: false, showIsIncoming: false
  )

  /// Initialize with custom options
  public init(
    showAddress: Bool = true,
    showName: Bool = true,
    showConnected: Bool = true,
    showRSSI: Bool = false,
    showPairing: Bool = false,
    showIsIncoming: Bool = false
  ) {
    self.showAddress = showAddress
    self.showName = showName
    self.showConnected = showConnected
    self.showRSSI = showRSSI
    self.showPairing = showPairing
    self.showIsIncoming = showIsIncoming
  }
}
