import CoreBluetooth
import CoreFoundation
import Foundation
@preconcurrency import IOBluetooth
import Logging

/// ▰▰▰ Manages Bluetooth device operations ▰▰▰
public class DeviceManager {
    private let logger: Logger

    /// Initialize with optional custom logger
    /// - Parameter logger: Logger instance to use
    public init(logger: Logger = BlueUtilLogger.logger) {
        self.logger = logger
    }

    /// Get a device by identifier (address or name)
    /// - Parameter identifier: Bluetooth address or device name
    /// - Returns: IOBluetoothDevice instance
    /// - Throws: BluetoothError if device not found or identifier invalid
    public func getDevice(identifier: String) throws -> IOBluetoothDevice {
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

    /// Check if a string is a valid Bluetooth ID
    /// - Parameter arg: String to validate
    /// - Returns: Boolean indicating if string is a valid Bluetooth ID
    public func isValidBluetoothID(arg: String) -> Bool {
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

    /// List devices with specified print options
    /// - Parameters:
    ///   - devices: Array of IOBluetoothDevice instances
    ///   - options: DevicePrintOptions defining what information to show
    public func listDevices(_ devices: [IOBluetoothDevice], options: DevicePrintOptions) -> [String]
    {
        logger.debug("Listing \(devices.count) devices")

        var output = [String]()

        if devices.isEmpty {
            output.append("No devices found.")
            return output
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

                output.append(deviceInfo.joined(separator: ", "))
            } catch {
                logger.error("Error processing device: \(error.localizedDescription)")
            }
        }

        return output
    }

    /// Get devices in range through Bluetooth inquiry
    /// - Parameter duration: Duration in seconds to scan for devices
    /// - Returns: Array of discovered devices
    /// - Throws: BluetoothError if inquiry fails
    public func getDevicesInRange(duration: Double) throws -> [IOBluetoothDevice] {
        logger.debug("Starting device inquiry for \(duration) seconds")

        return try autoreleasepool {
            // ▰▰▰ Inquiry Delegate ▰▰▰
            class InquiryStopper: NSObject, IOBluetoothDeviceInquiryDelegate {
                var isCompleted = false
                let logger: Logger

                init(logger: Logger) {
                    self.logger = logger
                    super.init()
                }

                func deviceInquiryComplete(
                    _ inquiry: IOBluetoothDeviceInquiry!,
                    error: IOReturn,
                    aborted: Bool
                ) {
                    logger.debug(
                        "Inquiry completed (error: \(error), aborted: \(aborted))"
                    )
                    isCompleted = true
                    CFRunLoopStop(CFRunLoopGetCurrent())
                }
            }

            let stopper = InquiryStopper(logger: logger)
            guard let inquirer = IOBluetoothDeviceInquiry(delegate: stopper) else {
                throw BluetoothError.operationFailed("Failed to initialize inquiry")
            }

            // inquiryLength is UInt8
            inquirer.inquiryLength = UInt8(duration)
            inquirer.updateNewDeviceNames = true

            let startResult = inquirer.start()
            guard startResult == kIOReturnSuccess else {
                logger.error("Failed to start inquiry: \(startResult)")
                throw BluetoothError.operationFailed("Inquiry start failed")
            }

            logger.debug("Inquiry started; will time out in \(duration)s")
            let timer = Timer.scheduledTimer(
                withTimeInterval: duration, repeats: false
            ) { [weak inquirer] _ in
                self.logger.debug("Inquiry timeout reached")
                inquirer?.stop()
            }
            RunLoop.current.add(timer, forMode: .default)

            // run until the delegate stops us
            while !stopper.isCompleted {
                RunLoop.current.run(
                    mode: .default,
                    before: Date.distantFuture
                )
            }

            if let found = inquirer.foundDevices() as? [IOBluetoothDevice] {
                logger.debug("Found \(found.count) devices")
                return found
            }

            logger.error("No devices found during inquiry")
            throw BluetoothError.deviceNotFound(identifier: "No devices found")
        }
    }

    /// Connect to a device by ID
    /// - Parameter identifier: Device ID or name
    /// - Throws: BluetoothError if connection fails
    public func connectToDevice(_ identifier: String) throws {
        logger.info("Connecting to device \(identifier)")
        let device = try getDevice(identifier: identifier)

        logger.debug("Attempting to open connection")
        let result = device.openConnection()

        if result != kIOReturnSuccess {
            logger.error("Failed to connect to device \(identifier): \(result)")
            throw BluetoothError.connectionFailed("Return code: \(result)")
        }

        logger.debug("Connection successful")
    }

    /// Disconnect from a device
    /// - Parameter identifier: Device ID or name
    /// - Throws: BluetoothError if disconnection fails
    public func disconnectFromDevice(_ identifier: String) throws {
        logger.info("Disconnecting from device \(identifier)")
        let device = try getDevice(identifier: identifier)

        // Setup notification for handling disconnect event
        class DeviceNotificationRunLoopStopper: NSObject {
            private var expectedDevice: IOBluetoothDevice
            var logger: Logger

            init(withExpectedDevice device: IOBluetoothDevice, logger: Logger) {
                self.expectedDevice = device
                self.logger = logger
                super.init()
            }

            @objc func notification(
                _ notification: IOBluetoothUserNotification, fromDevice device: IOBluetoothDevice
            ) {
                if expectedDevice == device {
                    logger.debug("Received disconnect notification")
                    notification.unregister()
                    CFRunLoopStop(RunLoop.current.getCFRunLoop())
                }
            }
        }

        logger.debug("Registering for disconnect notification")
        let stopper = DeviceNotificationRunLoopStopper(withExpectedDevice: device, logger: logger)
        device.register(
            forDisconnectNotification: stopper,
            selector: #selector(DeviceNotificationRunLoopStopper.notification(_:fromDevice:))
        )

        logger.debug("Closing connection")
        let result = device.closeConnection()
        if result != kIOReturnSuccess {
            logger.error("Failed to disconnect from device \(identifier): \(result)")
            throw BluetoothError.operationFailed("Return code: \(result)")
        }

        logger.debug("Waiting for disconnect completion")
        RunLoop.current.run()

        logger.info("Disconnect complete")
    }

    /// Pair with a device
    /// - Parameters:
    ///   - identifier: Device ID or name
    ///   - pin: Optional PIN code for pairing
    /// - Throws: BluetoothError if pairing fails
    public func pairWithDevice(_ identifier: String, pin: String?) throws {
        logger.info("Pairing with device \(identifier) with PIN: \(pin ?? "no PIN provided")")
        let device = try getDevice(identifier: identifier)

        // ▰▰▰ Local pair‐delegate ▰▰▰
        class BluetoothPairDelegate: NSObject, IOBluetoothDevicePairDelegate {
            var requestedPin: Int = 0
            let logger: Logger

            init(logger: Logger) {
                self.logger = logger
                super.init()
            }

            @objc func devicePairingStarted(_ sender: Any!) {
                logger.debug("Pairing started")
            }

            @objc func devicePairingFinished(_ sender: Any!, error: IOReturn) {
                logger.debug("Pairing finished with status: \(error)")
                CFRunLoopStop(RunLoop.current.getCFRunLoop())
            }

            @objc func devicePairingPINCodeRequest(_ sender: Any!) {
                logger.debug("PIN code requested (requestedPin=\(requestedPin))")
                guard requestedPin > 0,
                    let pair = sender as? IOBluetoothDevicePair
                else { return }

                let pinValue = requestedPin
                let pinLength = String(pinValue).count
                var bluetoothPin = BluetoothPINCode()

                withUnsafeMutablePointer(to: &bluetoothPin) { ptr in
                    pair.replyPINCode(pinLength, pinCode: ptr)
                }
            }
        }

        let delegate = BluetoothPairDelegate(logger: logger)
        guard let pairer = IOBluetoothDevicePair(device: device) else {
            throw BluetoothError.operationFailed("Could not create pairing object")
        }
        pairer.delegate = delegate
        if let pinString = pin, let pinValue = Int(pinString) {
            delegate.requestedPin = pinValue
            logger.debug("Using PIN: \(pinValue)")
        }

        let startRes = pairer.start()
        guard startRes == kIOReturnSuccess else {
            throw BluetoothError.operationFailed("Pair start failed: \(startRes)")
        }

        // hang the runloop until the delegate calls us back
        RunLoop.current.run()
        pairer.stop()

        guard device.isPaired() else {
            throw BluetoothError.operationFailed("Device not paired after pairing")
        }
        logger.info("Pairing successful")

    }

    /// Unpair a device
    /// - Parameter identifier: Device ID or name
    /// - Throws: BluetoothError if unpairing fails
    public func unpairDevice(_ identifier: String) throws {
        logger.info("Unpairing device \(identifier)")
        let device = try getDevice(identifier: identifier)
        let removeSelector = NSSelectorFromString("remove")

        logger.debug("Checking if device supports unpair operation")
        if device.responds(to: removeSelector) {
            logger.debug("Performing unpair operation")
            device.perform(removeSelector)
            device.closeConnection()
            logger.info("Unpair successful")
        } else {
            logger.error("Device \(identifier) does not support unpair operation")
            throw BluetoothError.operationFailed("Device does not support unpair operation")
        }
    }

    /// Check if a device is connected
    /// - Parameter identifier: Device ID or name
    /// - Returns: Boolean indicating connection status
    /// - Throws: BluetoothError if device not found
    public func isDeviceConnected(_ identifier: String) throws -> Bool {
        logger.info("Checking connection state for device \(identifier)")
        let device = try getDevice(identifier: identifier)
        return device.isConnected()
    }
}
