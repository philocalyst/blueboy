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
