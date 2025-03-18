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
