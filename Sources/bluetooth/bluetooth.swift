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
    case timeoutError(String)
    case invalidState(String)
    case invalidArgument(String)

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
        case .timeoutError(let message):
            return "Operation timed out: \(message)"
        case .invalidState(let message):
            return "Invalid state: \(message)"
        case .invalidArgument(let message):
            return "Invalid argument: \(message)"
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

    // Presets!!
    static let all = DevicePrintOptions(
        showAddress: true, showName: true, showConnected: true,
        showRSSI: true, showPairing: true, showIsIncoming: true
    )

    static let basic = DevicePrintOptions(
        showAddress: true, showName: true, showConnected: true,
        showRSSI: false, showPairing: false, showIsIncoming: false
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
    // Delegate method
    func peripheralDidDiscoverServices(_ peripheral: CBPeripheral) {
        CFRunLoopStop(RunLoop.current.getCFRunLoop())
    }
}

// MARK: - Device Management Functions
func getDevice(identifier: String) throws -> IOBluetoothDevice {
    logger.debug("Attempting to find device with identifier: \(identifier)")

    if isValidBluetoothID(arg: identifier) {
        guard let device = IOBluetoothDevice(addressString: identifier) else {
            logger.error("Device not found with identifier: \(identifier)")
            throw BluetoothError.deviceNotFound(identifier: identifier)
        }
        logger.debug("Found device by address: \(identifier)")
        return device
    } else {
        // If no valid identifier provided, check for a matched name in the list
        if let pairedDevices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] {
            for device in pairedDevices {
                if device.nameOrAddress == identifier {
                    logger.debug("Found device by name: \(identifier)")
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
        let isValid = regex.firstMatch(in: arg, range: range) != nil
        logger.debug("Bluetooth ID validation for \(arg): \(isValid)")
        return isValid
    } catch {
        logger.error("Error creating regex: \(error)")
        return false
    }
}

// Fully featured list devices func
func listDevices(_ devices: [IOBluetoothDevice], options: DevicePrintOptions) {
    logger.debug("Listing \(devices.count) devices")

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
            // Set.self,
            Get.self,
            List.self,
        ]
    )

    // @Option(name: .customLong("format"), help: "Change output format")
    // var format: Format?

    @Flag(name: .customLong("debug"), help: "Enable debug logging")
    var debug: Bool = false

    @Flag(name: .customLong("verbose"), help: "Enable verbose logging (implies debug)")
    var verbose: Bool = false

    mutating func run() throws {
        // Configure logging based on debug/verbose flags
        configureLogging()

        // logger.debug("Blueutil starting with format: \(format?.rawValue ?? "default")")

        // if let formatOption = format {
        //     logger.info("Setting format to \(formatOption)")
        //     print("Setting format to \(formatOption)")
        // } else {
        //     logger.info("Outputting current Bluetooth state")
        //     print("Outputting current Bluetooth state...")
        // }
    }

    private func configureLogging() {
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

    }
}

// MARK: - List Command
extension Blueutil {
    struct List: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "List Bluetooth devices"
        )

        // Removed deprecated favorites option

        @Option(help: "Inquiry devices in range, duration in seconds (default 10)")
        var inquiry: Int?

        @Flag(help: "List paired devices")
        var paired: Bool = false

        // Removed deprecated recent option

        @Flag(help: "List connected devices")
        var connected: Bool = false

        // @Option(name: .customLong("format"), help: "Change output format")
        // var format: Format?

        mutating func run() throws {
            logger.info("Running List command")

            // Default options for device printing
            var printOptions = DevicePrintOptions(
                showAddress: true,
                showName: true,
                showConnected: true,
                showRSSI: true,
                showPairing: true,
                showIsIncoming: true
            )

            if let duration = inquiry {
                logger.info("Inquiring for \(duration) seconds")
                let devices = try getDevicesInRange(duration: Double(duration))
                listDevices(devices, options: printOptions)
            } else if paired {
                logger.info("Listing paired devices")
                if let pairedDevices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] {
                    printOptions.showPairing = false
                    listDevices(pairedDevices, options: printOptions)
                } else {
                    logger.error("Could not retrieve paired devices")
                    print("Could not retrieve paired devices.")
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
                    logger.error("Could not retrieve paired devices")
                    print("Could not retrieve paired devices.")
                }
            }
        }

        private func getDevicesInRange(duration: Double) throws -> [IOBluetoothDevice] {
            logger.debug("Starting device inquiry for \(duration) seconds")

            return try autoreleasepool {
                class DeviceInquiryRunLoopStopper: NSObject, IOBluetoothDeviceInquiryDelegate {
                    var isCompleted = false

                    func deviceInquiryComplete(
                        _ sender: IOBluetoothDeviceInquiry!, error: IOReturn, aborted: Bool
                    ) {
                        logger.debug(
                            "Device inquiry completed with status: \(error), aborted: \(aborted)")
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
                    logger.error("Failed to start inquiry with error: \(result ?? IOReturn(0))")
                    throw BluetoothError.operationFailed("Failed to start inquiry")
                }

                logger.debug("Inquiry started, waiting for \(duration) seconds")

                let timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
                    logger.debug("Inquiry timeout reached")
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
                    logger.debug("Found \(foundDevices.count) devices in range")
                    return foundDevices
                }

                logger.error("No devices found during inquiry")
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

        // Removed deprecated favorite options

        // @Option(name: .customLong("format"), help: "Change output format")
        // var format: Format?

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
                // } else if let formatOption = format {
                //     logger.info("Setting format to \(formatOption) for device \(id)")
                //     print("Setting format to \(formatOption) for device command with ID \(id)")
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

            logger.debug("Attempting to open connection")
            let result = device.openConnection()

            if result != kIOReturnSuccess {
                logger.error("Failed to connect to device \(id): \(result)")
                throw BluetoothError.connectionFailed("Return code: \(result)")
            }

            logger.debug("Connection successful")
            print("Successfully connected to device \(id)")
        }

        private func disconnectFromDevice(_ id: String) throws {
            logger.info("Disconnecting from device \(id)")
            let device = try getDevice(identifier: id)

            logger.debug("Registering for disconnect notification")
            let stopper = DeviceNotificationRunLoopStopper(withExpectedDevice: device)
            device.register(
                forDisconnectNotification: stopper,
                selector: #selector(DeviceNotificationRunLoopStopper.notification(_:fromDevice:))
            )

            logger.debug("Closing connection")
            let result = device.closeConnection()
            if result != kIOReturnSuccess {
                logger.error("Failed to disconnect from device \(id): \(result)")
                throw BluetoothError.operationFailed("Return code: \(result)")
            }

            logger.debug("Waiting for disconnect completion")
            RunLoop.current.run()

            logger.info("Disconnect complete")
            print("Successfully disconnected from device \(id)")
        }

        private func pairWithDevice(_ id: String, pin: String?) throws {
            logger.info("Pairing with device \(id) with PIN: \(pin ?? "no PIN provided")")
            let device = try getDevice(identifier: id)

            class BluetoothPairDelegate: NSObject, IOBluetoothDevicePairDelegate {
                var requestedPin: Int = 0
                let logger: Logger

                init(logger: Logger) {
                    self.logger = logger
                    super.init()
                }

                // Implement required delegate methods
                func devicePairingStarted(_ sender: IOBluetoothDevicePair) {
                    logger.debug("Pairing started")
                }

                func devicePairingFinished(_ sender: IOBluetoothDevicePair, error: IOReturn) {
                    logger.debug("Pairing finished with status: \(error)")
                    CFRunLoopStop(RunLoop.current.getCFRunLoop())
                }

                func devicePairingPINCodeRequest(_ sender: IOBluetoothDevicePair) {
                    logger.debug("PIN code requested, requested PIN: \(requestedPin)")
                    if requestedPin > 0 {
                        logger.debug("Replying with PIN: \(requestedPin)")
                        let pinValue = requestedPin
                        let pinLength = String(pinValue).count

                        var bluetoothPin = BluetoothPINCode()

                        let pinCodePointer = withUnsafeMutablePointer(to: &bluetoothPin) { $0 }

                        sender.replyPINCode(pinLength, pinCode: pinCodePointer)
                    }
                }
            }

            let delegate = BluetoothPairDelegate(logger: logger)
            guard let pairer = IOBluetoothDevicePair(device: device) else {
                logger.error("Failed to create pairing object for device \(id)")
                throw BluetoothError.operationFailed("Could not create pairing object")
            }

            pairer.delegate = delegate

            if let pinString = pin, let pinValue = Int(pinString) {
                logger.debug("Using PIN: \(pinValue)")
                delegate.requestedPin = pinValue
            }

            logger.debug("Starting pairing process")
            if pairer.start() != kIOReturnSuccess {
                logger.error("Failed to start pairing with device \(id)")
                throw BluetoothError.operationFailed("Failed to start pairing process")
            }

            logger.debug("Waiting for pairing completion")
            RunLoop.current.run()

            logger.debug("Stopping pairing process")
            pairer.stop()

            if !device.isPaired() {
                logger.error("Failed to pair with device \(id)")
                throw BluetoothError.operationFailed(
                    "Device is not paired after the pairing process")
            }

            logger.info("Pairing successful")
            print("Successfully paired with device \(id)")
        }

        private func unpairDevice(_ id: String) throws {
            logger.info("Unpairing device \(id)")
            let device = try getDevice(identifier: id)
            let removeSelector = NSSelectorFromString("remove")

            logger.debug("Checking if device supports unpair operation")
            if device.responds(to: removeSelector) {
                logger.debug("Performing unpair operation")
                device.perform(removeSelector)
                device.closeConnection()
                logger.info("Unpair successful")
                print("Successfully unpaired device \(id)")
            } else {
                logger.error("Device \(id) does not support unpair operation")
                throw BluetoothError.operationFailed("Device does not support unpair operation")
            }
        }
    }
}

// MARK: - Set Command
// extension Blueutil {
//     struct Set: ParsableCommand {
//         static let configuration = CommandConfiguration(
//             abstract: "Set Bluetooth system states"
//         )

//         // Convert options to arguments as requested
//         @Argument(help: "Operation to perform (power or discoverable)")
//         var operation: String

//         @Argument(help: "State to set")
//         var state: State

//         mutating func run() throws {
//             logger.info("Running Set command with operation: \(operation), state: \(state)")

//             switch operation.lowercased() {
//             case "power", "p":
//                 try setPowerState(state)
//             case "discoverable", "d":
//                 try setDiscoverableState(state)
//             default:
//                 logger.error("Invalid operation: \(operation)")
//                 throw BluetoothError.invalidArgument(
//                     "Invalid operation: \(operation). Use 'power' or 'discoverable'")
//             }
//         }

//         private func setPowerState(_ state: State) throws {
//             // logger.info("Setting power state to \(state)")
//             // let host = IOBluetoothHostController.init()

//             // // Get current power state
//             // let currentPower = host.powerState
//             // logger.debug("Current power state: \(currentPower)")

//             // // Determine target state
//             // let targetState: Bool
//             // if state == .toggle {
//             //     targetState = !currentPower.boolValue
//             //     logger.debug(
//             //         "Toggling power state from \(currentPower.boolValue) to \(targetState)")
//             // } else {
//             //     targetState = state.boolValue
//             //     logger.debug("Setting power state to \(targetState)")
//             // }

//             // // Implementation for setting power state would go here
//             // // Since we don't have the actual implementation, just log and print
//             // logger.info("Power state set to \(targetState ? "on" : "off")")
//             // print("Power state set to \(targetState ? "on" : "off")")
//         }

//         private func setDiscoverableState(_ state: State) throws {
//             logger.info("Setting discoverable state to \(state)")

//             // Get current discoverable state (placeholder - implementation would vary)
//             let currentState = false  // Example value
//             logger.debug("Current discoverable state: \(currentState)")

//             // Determine target state
//             let targetState: Bool
//             if state == .toggle {
//                 targetState = !currentState
//                 logger.debug("Toggling discoverable state from \(currentState) to \(targetState)")
//             } else {
//                 targetState = state.boolValue
//                 logger.debug("Setting discoverable state to \(targetState)")
//             }

//             // Implementation for setting discoverable state would go here
//             logger.info("Discoverable state set to \(targetState ? "on" : "off")")
//             print("Discoverable state set to \(targetState ? "on" : "off")")
//         }
//     }
// }

// MARK: - Get Command
extension Blueutil {
    struct Get: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Get Bluetooth system states"
        )

        @Flag(
            name: [.short, .customLong("discoverable")], help: "Output discoverable state as 1 or 0"
        )
        var discoverableStateOutput: Bool = false

        @Flag(name: [.short, .customLong("power")], help: "Output power status as 1 or 0")
        var powerStateOutput: Bool = false

        // @Option(name: .customLong("format"), help: "Change output format")
        // var format: Format?

        mutating func run() throws {
            logger.info("Running Get command")

            if discoverableStateOutput {
                try getDiscoverableState()
            }

            if powerStateOutput {
                try getPowerState()
            }

            if !discoverableStateOutput && !powerStateOutput {
                logger.warning("No state retrieval specified")
                print("No state retrieval specified")
            }
        }

        private func getDiscoverableState() throws {
            logger.info("Getting discoverable state")
            let host = IOBluetoothHostController.init()

            // Placeholder for actual implementation
            let isDiscoverable = true  // Example value
            logger.debug("Current discoverable state: \(isDiscoverable)")

            print(isDiscoverable ? "1" : "0")
        }

        private func getPowerState() throws {
            logger.info("Getting power state")
            let host = IOBluetoothHostController.init()

            do {
                let power = host.powerState
                logger.debug("Power state raw value: \(power.rawValue)")
                print(power.rawValue)
            } catch {
                logger.error("Failed to get power state: \(error)")
                throw BluetoothError.operationFailed("Failed to get power state")
            }
        }
    }
}
