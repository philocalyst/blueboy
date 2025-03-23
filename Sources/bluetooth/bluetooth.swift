import ArgumentParser
import CoreBluetooth
import CoreFoundation
import Foundation
@preconcurrency import IOBluetooth
import Logging

let logger = Logger(label: "com.blueutil")

// MARK: - Error Handling
enum BluetoothError: Error, LocalizedError {
    case invalidIdentifier(identifier: String)
    case deviceNotFound(identifier: String)
    case connectionFailed(String)
    case missingData(String)
    case operationFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidIdentifier(let identifier):
            return "Invalid device identifier: \(identifier)"
        case .deviceNotFound(let identifier):
            return "Device not found: \(identifier)"
        case .connectionFailed(let message):
            return "Connection failed: \(message)"
        case .missingData(let message):
            return "Missing data: \(message)"
        case .operationFailed(let message):
            return "Operation failed: \(message)"
        }
    }
}

// MARK: - Common Types
enum State: String, CaseIterable, ExpressibleByArgument {
    case on, off, toggle
    case one = "1"
    case zero = "0"

    var boolValue: Bool {
        switch self {
        case .on, .one: return true
        case .off, .zero: return false
        case .toggle: return false  // Toggle is handled separately
        }
    }
}

enum Format: String, CaseIterable, ExpressibleByArgument {
    case `default`
    case newDefault = "new-default"
    case json
    case jsonPretty = "json-pretty"
}

enum Operation: String, CaseIterable, ExpressibleByArgument {
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

// MARK: - Device Helpers
struct DevicePrintOptions {
    var showAddress: Bool
    var showName: Bool
    var showConnected: Bool
    var showRSSI: Bool
    var showPairing: Bool
    var showIsIncoming: Bool
    var showIsFavorite: Bool
    var showRecentAccessDate: Bool

    // Presets!!
    static let all = DevicePrintOptions(
        showAddress: true, showName: true, showConnected: true,
        showRSSI: true, showPairing: true, showIsIncoming: true,
        showIsFavorite: true, showRecentAccessDate: true
    )

    static let basic = DevicePrintOptions(
        showAddress: true, showName: true, showConnected: true,
        showRSSI: false, showPairing: false, showIsIncoming: false,
        showIsFavorite: false, showRecentAccessDate: false
    )
}

// MARK: - Notification Helpers
class DeviceNotificationRunLoopStopper: NSObject {
    private var expectedDevice: IOBluetoothDevice

    init(withExpectedDevice device: IOBluetoothDevice) {
        self.expectedDevice = device
    }

    @objc func notification(
        _ notification: IOBluetoothUserNotification, fromDevice device: IOBluetoothDevice
    ) {
        if expectedDevice == device {
            notification.unregister()
            CFRunLoopStop(RunLoop.current.getCFRunLoop())
        }
    }
}

class DeviceInquiryRunLoopStopper: NSObject, CBPeripheralDelegate {
    //Delegate method
    func peripheralDidDiscoverServices(_ peripheral: CBPeripheral) {
        CFRunLoopStop(RunLoop.current.getCFRunLoop())
    }
}

@main
struct Blueutil: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "A command-line utility for controlling Bluetooth on macOS.",
        version: "2.12.0",
        subcommands: [
            Device.self,
            Wait.self,
            Set.self,
            Get.self,
            List.self,
        ]
    )

    @Option(name: .customLong("format"), help: "Change output format")
    var format: Format?

    mutating func run() throws {
        if let formatOption = format {
            // Logic for format when no other command is given
            print("Setting format to \(formatOption)")
        } else {
            // Default behavior: output current state
            print("Outputting current Bluetooth state...")
        }
    }
}

extension Blueutil {
    struct List: ParsableCommand {
        @Flag(help: "List favorite devices")
        var favorites: Bool = false

        @Option(help: "Inquiry devices in range, duration in seconds (default 10)")
        var inquiry: Int?

        @Flag(help: "List paired devices")
        var paired: Bool = false

        @Option(help: "List recently used devices, default 10, 0 to list all")
        var recent: Int?

        @Flag(help: "List connected devices")
        var connected: Bool = false

        mutating func run() throws {
            if favorites {
                // Logic to list favorites
                print("Listing favorites...")
            } else if let duration = inquiry {
                // Logic for inquiry
                print("Inquiring for \(duration) seconds...")
            } else if paired {
                if let pairedDevices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] {
                    listDevices(pairedDevices, detailed: false)  // Assuming you have a listDevices function in Swift
                } else {
                    print("Could not retrieve paired devices.")
                }
                // Logic to list paired devices
                print("Listing paired devices...")
            } else if let count = recent {
                // Logic to list recent devices
                print("Listing recent devices (count: \(count))...")
            } else if connected {
                // Logic to list connected devices
                let pairedDevices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice]
                var connectedDevices = [IOBluetoothDevice]()

                if let pairedDevices = pairedDevices {  // Safely unwrap the optional
                    for device in pairedDevices {
                        if device.isConnected() {
                            connectedDevices.append(device)
                        }
                    }
                }

                listDevices(connectedDevices, detailed: false)
                print("Listing connected devices...")
            }
        }
    }
    struct Device: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Manage Bluetooth devices.")

        @Argument(help: "Device ID (address or name)")
        var id: String

        @Flag(name: .customLong("info"), help: "Show information about device")
        var info: Bool = false

        @Flag(name: .customLong("is-connected"), help: "Connected state of device as 1 or 0")
        var isConnected: Bool = false

        @Flag(name: .customLong("connect"), help: "Create a connection to device")
        var connect: Bool = false

        @Flag(name: .customLong("disconnect"), help: "Close the connection to device")
        var disconnect: Bool = false

        @Flag(name: .customLong("pair"), help: "Pair with device, optional PIN")
        var pair: Bool = false

        @Option(name: .customLong("pin"), help: "PIN for pairing (optional)")
        var pin: String? = nil

        @Flag(name: .customLong("unpair"), help: "EXPERIMENTAL unpair the device")
        var unpair: Bool = false

        @Flag(
            name: [.customLong("add-favourite"), .customLong("add-favorite")],
            help: "Add to favourites")
        var addFavourite: Bool = false

        @Flag(
            name: [.customLong("remove-favourite"), .customLong("remove-favorite")],
            help: "Remove from favourites")
        var removeFavourite: Bool = false

        @Option(name: .customLong("format"), help: "Change output format")
        var format: Format?

        mutating func run() throws {
            if info {
                // Logic to show device info
                print("Showing info for device \(id)")
            } else if isConnected {
                // Logic to check connection state
                print("Checking connection state for device \(id)")
            } else if connect {
                // Logic to connect to device
                do {
                    let device = try getDevice(identifier: id)
                    device.openConnection()
                } catch {
                    print("Error getting device: \(error)")
                }
                print("Pairing with device \(id) with PIN: \(pin ?? "no PIN provided")")

                print("Connecting to device \(id)")
            } else if disconnect {
                // Logic to disconnect from device
                do {
                    let device = try getDevice(identifier: id)
                    let stopper = DeviceNotificationRunLoopStopper.init(withExpectedDevice: device)
                    device.register(
                        forDisconnectNotification: stopper,
                        selector: #selector(
                            DeviceNotificationRunLoopStopper.notification(_:fromDevice:)))
                    if device.closeConnection() != kIOReturnSuccess {
                        print("failed")
                    }
                    CFRunLoopRun()
                } catch {
                    print("Error getting device: \(error)")
                }
                print("Disconnecting from device \(id)")

            } else if pair {
                // Logic to pair with device
                do {
                    let device = try getDevice(identifier: id)
                    class BluetoothPairDelegate: NSObject, IOBluetoothDevicePairDelegate {
                        var requestedPin: Int = 0
                    }
                    let delegate = BluetoothPairDelegate()
                    let pairer = IOBluetoothDevicePair(device: device)
                    pairer?.delegate = delegate

                    if let pinString = pin, let pinValue = Int(pinString) {
                        delegate.requestedPin = pinValue
                    }

                    if pairer?.start() != kIOReturnSuccess {
                        print("failed to start pairing")
                    }
                    CFRunLoopRun()
                    pairer?.stop()
                    if !device.isPaired() {
                        print("failed to pair")
                    }
                } catch {
                    print("Error getting device: \(error)")
                }
                print("Pairing with device \(id) with PIN: \(pin ?? "no PIN provided")")
            } else if unpair {
                do {
                    let device = try getDevice(identifier: id)
                    let removeSelector = NSSelectorFromString("remove")

                    if device.responds(to: removeSelector) {
                        device.perform(removeSelector)
                        device.closeConnection()
                    } else {
                        print("Device does not respond to 'remove' selector.")  // More informative message
                    }
                } catch {
                    print("Error getting device: \(error)")
                }
                print("Unpairing device \(id)")
            } else if addFavourite {
                // Logic to add to favorites
                print("Adding device \(id) to favorites")
            } else if removeFavourite {
                // Logic to remove from favorites
                print("Removing device \(id) from favorites")
            } else if let formatOption = format {
                // Logic for format
                print("Setting format to \(formatOption) for device command with ID \(id)")
            } else {
                print("No specific device action specified for ID \(id)")
            }
        }
    }

    struct Get: ParsableCommand {
        @Flag(
            name: [.short, .customLong("discoverable")], help: "Output discoverable state as 1 or 0"
        )
        var discoverableStateOutput: Bool = false

        @Flag(name: [.short, .customLong("power")], help: "Output power status as 1 or 0")
        var powerStateOutput: Bool = false

    }

    struct Set: ParsableCommand {
        @Option(name: [.short, .customLong("power")], help: "set power state")
        var powerState: State?

        @Option(name: [.short, .customLong("discoverable")], help: "set discoverable state")
        var discoverableState: State?

        mutating func run() throws {
            if let state = powerState {
                // Logic to set power state
                print("Setting power state to \(state)")
            } else if let state = discoverableState {
                // Logic to set discoverable state
                print("Setting discoverable state to \(state)")
            }
        }
    }

    struct Wait: ParsableCommand {

        @Argument(help: "Device ID (address or name)")
        var id: String

        @Option(name: .customLong("wait-connect"), help: "EXPERIMENTAL wait for device to connect")
        var waitConnect: Int?

        @Option(
            name: .customLong("wait-disconnect"), help: "EXPERIMENTAL wait for device to disconnect"
        )
        var waitDisconnect: Int?

    }
}

func listDevices(_ devices: [IOBluetoothDevice], detailed: Bool) {
    if devices.isEmpty {
        print("No devices found.")
        return
    }
    for device in devices {
        print(
            "Address: \(device.addressString ?? "-"), Name: \(device.nameOrAddress ?? "-"), Connected: \(device.isConnected() ? "Yes (\(device.rawRSSI()) dbm)" : "No")"
        )
        if detailed {
            // Add more detailed information retrieval here
        }
    }
}

enum BluetoothError: Error {
    case invalidIdentifier(identifier: String)
    case deviceNotFound(identifier: String)
}

func getDevice(identifier: String) throws -> IOBluetoothDevice {
    if isValidID(arg: identifier) {
        guard let device = IOBluetoothDevice(addressString: identifier) else {
            throw BluetoothError.deviceNotFound(identifier: identifier)
        }
        return device
    } else {
        throw BluetoothError.invalidIdentifier(identifier: identifier)
    }
    // else {
    // Not a valid id, use name instead.
    // let searchDevices =
    //     IOBluetoothDevice.pairedDevices()

    // let foundDevices = searchDevices.filter { device in
    //     return device == identifier
    // }

    // // Return the first matching device, or throw an error if none are found.
    // guard let device = foundDevices.first else {
    //     throw BluetoothError.deviceNotFound(identifier: identifier)
    // }
    // return device
    // }
}

func isValidID(arg: String) -> Bool {
    let regexPattern = "^[0-9a-f]{2}([0-9a-f]{10}|(-[0-9a-f]{2}){5}|(:[0-9a-f]{2}){5})$"
    do {
        let regex = try NSRegularExpression(pattern: regexPattern, options: [.caseInsensitive])
        let range = NSRange(location: 0, length: arg.utf16.count)
        if regex.firstMatch(in: arg, range: range) != nil {
            return true
        } else {
            return false
        }
    } catch {
        print("Error creating regex: \(error)")
        return false  // Or handle the error as appropriate for your application
    }
}
