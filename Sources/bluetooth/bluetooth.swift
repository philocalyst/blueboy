import ArgumentParser
import Foundation
import IOBluetooth

class DeviceNotificationRunLoopStopper: NSObject {
    private var expectedDevice: IOBluetoothDevice?

    init(withExpectedDevice device: IOBluetoothDevice) {
        expectedDevice = device
    }

    @objc func notification(
        _ notification: IOBluetoothUserNotification, fromDevice device: IOBluetoothDevice
    ) {
        if expectedDevice == device {
            notification.unregister()
            CFRunLoopStop(CFRunLoopGetCurrent())
        }
    }
}

enum State: String, CaseIterable, ExpressibleByArgument {
    case on, off, toggle
    case one = "1"
    case zero = "0"
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
                print("Listing connected devices...")
            }
        }
    }
