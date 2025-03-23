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

// MARK: - Device Management Functions
func getDevice(identifier: String) throws -> IOBluetoothDevice {
    if isValidBluetoothID(arg: identifier) {
        guard let device = IOBluetoothDevice(addressString: identifier) else {
            logger.error("Device not found with identifier: \(identifier)")
            throw BluetoothError.deviceNotFound(identifier: identifier)
        }
        return device
    } else {
        // If no identifer provided, move to start checking for a matched name in the list
        if let pairedDevices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] {
            for device in pairedDevices {
                if device.nameOrAddress == identifier {
                    return device
                }
            }
        }

        logger.error("Invalid or not found device identifier: \(identifier)")
        throw BluetoothError.invalidIdentifier(identifier: identifier)
    }
}

func isValidBluetoothID(arg: String) -> Bool {
    let regexPattern = "^[0-9a-f]{2}([0-9a-f]{10}|(-[0-9a-f]{2}){5}|(:[0-9a-f]{2}){5})$"
    do {
        let regex = try NSRegularExpression(pattern: regexPattern, options: [.caseInsensitive])
        let range = NSRange(location: 0, length: arg.utf16.count)
        return regex.firstMatch(in: arg, range: range) != nil
    } catch {
        logger.error("Error creating regex: \(error)")
        return false
    }
}

// Fully featured list devices func
func listDevices(_ devices: [IOBluetoothDevice], options: DevicePrintOptions) {
    if devices.isEmpty {
        print("No devices found.")
        return
    }

    for device in devices {
        do {
            var deviceInfo = [String]()

            try autoreleasepool {
                if options.showAddress, let addressString = device.addressString {
                    deviceInfo.append("Address: \(addressString)")
                }

                if options.showName {
                    let nameOrAddress = device.nameOrAddress ?? "-"
                    deviceInfo.append("Name: \(nameOrAddress)")
                }

                if options.showConnected {
                    let isConnected = device.isConnected()
                    deviceInfo.append("Connected: \(isConnected ? "Yes" : "No")")
                }

                if options.showRSSI {
                    deviceInfo.append("RSSI: \(device.rawRSSI()) dbm")
                }

                if options.showPairing {
                    deviceInfo.append("Paired: \(device.isPaired() ? "Yes" : "No")")
                }

                if options.showIsIncoming {
                    deviceInfo.append("Incoming: \(device.isIncoming() ? "Yes" : "No")")
                }

                if options.showIsFavorite {
                    deviceInfo.append("Favorite: \(device.isFavorite() ? "Yes" : "No")")
                }

                if options.showRecentAccessDate, let recentAccessDate = device.recentAccessDate() {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .medium
                    dateFormatter.timeStyle = .short
                    deviceInfo.append(
                        "Last Accessed: \(dateFormatter.string(from: recentAccessDate))")
                } else if options.showRecentAccessDate {
                    deviceInfo.append("Last Accessed: Never")
                }
            }

            print(deviceInfo.joined(separator: ", "))
        } catch {
            logger.error("Error processing device: \(error.localizedDescription)")
        }
    }
}

// MARK: - Main Command
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
            logger.info("Setting format to \(formatOption)")
            print("Setting format to \(formatOption)")
        } else {
            logger.info("Outputting current Bluetooth state")
            print("Outputting current Bluetooth state...")
        }
    }
}

// MARK: - List Command
extension Blueutil {
    struct List: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "List Bluetooth devices"
        )

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

        @Option(name: .customLong("format"), help: "Change output format")
        var format: Format?

        mutating func run() throws {
            logger.info("Running List command")

            // Default options for device printing
            var printOptions = DevicePrintOptions(
                showAddress: true,
                showName: true,
                showConnected: true,
                showRSSI: true,
                showPairing: true,
                showIsIncoming: true,
                showIsFavorite: false,
                showRecentAccessDate: true
            )

            if favorites {
                logger.info("Listing favorite devices")
                if let favoriteDevices = IOBluetoothDevice.favoriteDevices() as? [IOBluetoothDevice]
                {
                    listDevices(favoriteDevices, options: printOptions)
                } else {
                    print("Could not retrieve favorite devices.")
                }
            } else if let duration = inquiry {
                logger.info("Inquiring for \(duration) seconds")
                let devices = try getDevicesInRange(duration: Double(duration))
                listDevices(devices, options: printOptions)
                print("Inquiring for \(duration) seconds...")
                // TODO: Implementation for device inquiry
            } else if paired {
                logger.info("Listing paired devices")
                if let pairedDevices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] {
                    printOptions.showPairing = false
                    listDevices(pairedDevices, options: printOptions)
                } else {
                    print("Could not retrieve paired devices.")
                }
            } else if let count = recent {
                logger.info("Listing \(count) recent devices")
                if let recentDevices = IOBluetoothDevice.recentDevices(UInt(count))
                    as? [IOBluetoothDevice]
                {
                    listDevices(recentDevices, options: printOptions)
                } else {
                    print("Could not retrieve recent devices.")
                }
            } else if connected {
                logger.info("Listing connected devices")
                let pairedDevices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] ?? []
                printOptions.showConnected = false
                let connectedDevices = pairedDevices.filter { $0.isConnected() }

                listDevices(connectedDevices, options: printOptions)
            } else {
                logger.info("No specific list option selected, showing paired devices")
                if let pairedDevices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] {
                    listDevices(pairedDevices, options: printOptions)
                } else {
                    print("Could not retrieve paired devices.")
                }
            }
        }
        private func getDevicesInRange(duration: Double) throws -> [IOBluetoothDevice] {
            try autoreleasepool {
                class DeviceInquiryRunLoopStopper: NSObject, IOBluetoothDeviceInquiryDelegate {
                    var isCompleted = false

                    func deviceInquiryComplete(
                        _ sender: IOBluetoothDeviceInquiry!, error: IOReturn, aborted: Bool
                    ) {
                        isCompleted = true
                        CFRunLoopStop(CFRunLoopGetCurrent())
                    }
                }

                let stopper = DeviceInquiryRunLoopStopper()
                let inquirer = IOBluetoothDeviceInquiry(delegate: stopper)

                inquirer?.inquiryLength = 10  // Length is in seconds
                inquirer?.updateNewDeviceNames = true  // Retrival of found devices

                let syncQueue = DispatchQueue(label: "com.bluetooth.inquiry.sync")

                let result = inquirer?.start()
                if result != kIOReturnSuccess {
                    throw BluetoothError.deviceNotFound(identifier: "Failed to start inquiry")
                }

                let timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
                    syncQueue.sync {
                        inquirer?.stop()
                    }
                }

                // Add the timer to the current run loop
                RunLoop.current.add(timer, forMode: .default)

                // Run the loop until stopped by the delegate
                while !stopper.isCompleted {
                    RunLoop.current.run(mode: .default, before: Date.distantFuture)
                }

                if let foundDevices = inquirer?.foundDevices() as? [IOBluetoothDevice] {
                    return foundDevices
                }

                throw BluetoothError.deviceNotFound(identifier: "No devices found")
            }
        }
    }
}

// MARK: - Device Command
extension Blueutil {
    struct Device: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Manage Bluetooth devices"
        )

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
        var pin: String?

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
            logger.info("Running Device command for ID: \(id)")

            if info {
                try showDeviceInfo(id)
            } else if isConnected {
                try checkDeviceConnection(id)
            } else if connect {
                try connectToDevice(id)
            } else if disconnect {
                try disconnectFromDevice(id)
            } else if pair {
                try pairWithDevice(id, pin: pin)
            } else if unpair {
                try unpairDevice(id)
            } else if addFavourite {
                try addDeviceToFavorites(id)
            } else if removeFavourite {
                try removeDeviceFromFavorites(id)
            } else if let formatOption = format {
                logger.info("Setting format to \(formatOption) for device \(id)")
                print("Setting format to \(formatOption) for device command with ID \(id)")
            } else {
                logger.info("No specific device action selected for \(id)")
                print("No specific device action specified for ID \(id)")
            }
        }

        // Device command helper methods
        private func showDeviceInfo(_ id: String) throws {
            logger.info("Showing info for device \(id)")
            let device = try getDevice(identifier: id)
            print("Device Information:")
            listDevices([device], options: DevicePrintOptions.all)
        }

        private func checkDeviceConnection(_ id: String) throws {
            logger.info("Checking connection state for device \(id)")
            let device = try getDevice(identifier: id)
            print(device.isConnected() ? "1" : "0")
        }

        private func connectToDevice(_ id: String) throws {
            logger.info("Connecting to device \(id)")
            let device = try getDevice(identifier: id)
            let result = device.openConnection()

            if result != kIOReturnSuccess {
                logger.error("Failed to connect to device \(id): \(result)")
                throw BluetoothError.connectionFailed("Return code: \(result)")
            }

            print("Successfully connected to device \(id)")
        }

        private func disconnectFromDevice(_ id: String) throws {
            logger.info("Disconnecting from device \(id)")
            let device = try getDevice(identifier: id)

            let stopper = DeviceNotificationRunLoopStopper(withExpectedDevice: device)
            device.register(
                forDisconnectNotification: stopper,
                selector: #selector(DeviceNotificationRunLoopStopper.notification(_:fromDevice:))
            )

            let result = device.closeConnection()
            if result != kIOReturnSuccess {
                logger.error("Failed to disconnect from device \(id): \(result)")
                throw BluetoothError.operationFailed("Return code: \(result)")
            }

            RunLoop.current.run()
            print("Successfully disconnected from device \(id)")
        }

        private func pairWithDevice(_ id: String, pin: String?) throws {
            logger.info("Pairing with device \(id) with PIN: \(pin ?? "no PIN provided")")
            let device = try getDevice(identifier: id)

            class BluetoothPairDelegate: NSObject, IOBluetoothDevicePairDelegate {
                var requestedPin: Int = 0

                // Implement required delegate methods
                func devicePairingStarted(_ sender: IOBluetoothDevicePair) {
                    logger.info("Pairing started")
                }

                func devicePairingFinished(_ sender: IOBluetoothDevicePair, error: IOReturn) {
                    logger.info("Pairing finished with status: \(error)")
                    CFRunLoopStop(RunLoop.current.getCFRunLoop())

                }

                func devicePairingPINCodeRequest(_ sender: IOBluetoothDevicePair) {
                    // if requestedPin > 0 {
                    //     sender.replyPINCode(withNumber: requestedPin)
                    // }
                }
            }

            let delegate = BluetoothPairDelegate()
            guard let pairer = IOBluetoothDevicePair(device: device) else {
                logger.error("Failed to create pairing object for device \(id)")
                throw BluetoothError.operationFailed("Could not create pairing object")
            }

            pairer.delegate = delegate

            if let pinString = pin, let pinValue = Int(pinString) {
                delegate.requestedPin = pinValue
            }

            if pairer.start() != kIOReturnSuccess {
                logger.error("Failed to start pairing with device \(id)")
                throw BluetoothError.operationFailed("Failed to start pairing process")
            }

            RunLoop.current.run()
            pairer.stop()

            if !device.isPaired() {
                logger.error("Failed to pair with device \(id)")
                throw BluetoothError.operationFailed(
                    "Device is not paired after the pairing process")
            }

            print("Successfully paired with device \(id)")
        }

        private func unpairDevice(_ id: String) throws {
            logger.info("Unpairing device \(id)")
            let device = try getDevice(identifier: id)
            let removeSelector = NSSelectorFromString("remove")

            if device.responds(to: removeSelector) {
                device.perform(removeSelector)
                device.closeConnection()
                print("Successfully unpaired device \(id)")
            } else {
                logger.error("Device \(id) does not support unpair operation")
                throw BluetoothError.operationFailed("Device does not support unpair operation")
            }
        }

        private func addDeviceToFavorites(_ id: String) throws {
            logger.info("Adding device \(id) to favorites")
            let device = try getDevice(identifier: id)
            // TODO: Implementation for adding to favorites
            print("Added device \(id) to favorites")
        }

        private func removeDeviceFromFavorites(_ id: String) throws {
            logger.info("Removing device \(id) from favorites")
            let device = try getDevice(identifier: id)
            // TODO: Implementation for removing from favorites
            print("Removed device \(id) from favorites")
        }
    }
}

// MARK: - Wait Command
extension Blueutil {
    struct Wait: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Wait for device connection or disconnection"
        )

        @Argument(help: "Device ID (address or name)")
        var id: String

        @Option(
            name: .customLong("wait-connect"),
            help: "EXPERIMENTAL wait for device to connect (timeout in seconds)")
        var waitConnect: Int?

        @Option(
            name: .customLong("wait-disconnect"),
            help: "EXPERIMENTAL wait for device to disconnect (timeout in seconds)")
        var waitDisconnect: Int?

        mutating func run() throws {
            if let timeout = waitConnect {
                try waitForDeviceConnection(id, timeout: timeout)
            } else if let timeout = waitDisconnect {
                try waitForDeviceDisconnection(id, timeout: timeout)
            } else {
                logger.warning("No wait condition specified for device \(id)")
                print("No wait condition specified for device \(id)")
            }
        }

        private func waitForDeviceConnection(_ id: String, timeout: Int) throws {
            logger.info("Waiting for device \(id) to connect (timeout: \(timeout)s)")
            let device = try getDevice(identifier: id)

            // TODO: Implementation for waiting for connection
            print("Waiting for device \(id) to connect...")
        }

        private func waitForDeviceDisconnection(_ id: String, timeout: Int) throws {
            logger.info("Waiting for device \(id) to disconnect (timeout: \(timeout)s)")
            let device = try getDevice(identifier: id)

            // TODO: Implementation for waiting for disconnection
            print("Waiting for device \(id) to disconnect...")
        }
    }
}

// MARK: - Set Command
extension Blueutil {
    struct Set: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Set Bluetooth system states"
        )

        @Option(name: [.short, .customLong("power")], help: "Set power state")
        var powerState: State?

        @Option(name: [.short, .customLong("discoverable")], help: "Set discoverable state")
        var discoverableState: State?

        mutating func run() throws {
            if let state = powerState {
                try setPowerState(state)
            }

            if let state = discoverableState {
                try setDiscoverableState(state)
            }

            if powerState == nil && discoverableState == nil {
                logger.warning("No state changes specified")
                print("No state changes specified")
            }
        }

        private func setPowerState(_ state: State) throws {
            logger.info("Setting power state to \(state)")
            let host = IOBluetoothHostController.init()
            var power = host.powerState
            print(power)
            print("Setting power state to \(state)")
        }

        private func setDiscoverableState(_ state: State) throws {
            logger.info("Setting discoverable state to \(state)")
            // Implementation for setting discoverable state
            print("Setting discoverable state to \(state)")
        }
    }
}

// MARK: - Get Command

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
