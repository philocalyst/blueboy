import ArgumentParser
import BlueKit
import Foundation
import Logging

/// ▰▰▰ Device command for interacting with specific devices ▰▰▰
struct DeviceCommand: ParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "device",
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

	func run() throws {
		let logger = BlueUtilLogger.logger
		let deviceManager = DeviceManager(logger: logger)

		logger.info("Running Device command for ID: \(id)")

		if info {
			try showDeviceInfo(id, deviceManager: deviceManager)
		} else if isConnected {
			try checkDeviceConnection(id, deviceManager: deviceManager)
		} else if connect {
			try connectToDevice(id, deviceManager: deviceManager)
		} else if disconnect {
			try disconnectFromDevice(id, deviceManager: deviceManager)
		} else if pair {
			try pairWithDevice(id, pin: pin, deviceManager: deviceManager)
		} else if unpair {
			try unpairDevice(id, deviceManager: deviceManager)
		} else {
			logger.info("No specific device action selected for \(id)")
			print("No specific device action specified for ID \(id)")
		}
	}

	private func showDeviceInfo(_ id: String, deviceManager: DeviceManager) throws {
		let logger = BlueUtilLogger.logger
		logger.info("Showing info for device \(id)")
		let device = try deviceManager.getDevice(identifier: id)
		print("Device Information:")
		let deviceInfo = deviceManager.listDevices([device], options: DevicePrintOptions.all)
		for line in deviceInfo {
			print(line)
		}
	}

	private func checkDeviceConnection(_ id: String, deviceManager: DeviceManager) throws {
		let isConnected = try deviceManager.isDeviceConnected(id)
		print(isConnected ? "1" : "0")
	}

	private func connectToDevice(_ id: String, deviceManager: DeviceManager) throws {
		try deviceManager.connectToDevice(id)
		print("Successfully connected to device \(id)")
	}

	private func disconnectFromDevice(_ id: String, deviceManager: DeviceManager) throws {
		try deviceManager.disconnectFromDevice(id)
		print("Successfully disconnected from device \(id)")
	}

	private func pairWithDevice(_ id: String, pin: String?, deviceManager: DeviceManager) throws {
		try deviceManager.pairWithDevice(id, pin: pin)
		print("Successfully paired with device \(id)")
	}

	private func unpairDevice(_ id: String, deviceManager: DeviceManager) throws {
		try deviceManager.unpairDevice(id)
		print("Successfully unpaired device \(id)")
	}
}
