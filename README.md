# Welcome to BlueBoy

[![Swift Version](https://badgen.net/static/Swift/5.9/orange)](https://swift.org)
[![Apple Platform](https://badgen.net/badge/icon/macOS%2013+?icon=apple&label)](https://developer.apple.com/macOS)

BlueBoy(bboy) is a command-line utility for controlling Bluetooth on macOS. Who doesn't hate clicking through out-of-the way, poorly-designed, swiftUI menus on macOS? Here, we love the CLI. You may have heard of blueutil? This is its spirtual successor. It provides a simple and effective way to manage Bluetooth devices, check system states, and list available, paired, or connected devices directly from your terminal. Very powerful for automation.

With a modern CLI interface with slightly more readable errors, this is the beginnning of a bright future for bluetooth management on macOS. It uses a whole new high-level bluetooth library that you can integrate into your own app. So hip hip hooray for bluetooth!

> A note on feature-parity with blueutil: there are some hyper-private frameworks that blueutil uses that I haven't been able to get to work here. This means all of the set methods, and the discoverability getter. If you happen to be skilled in briding obj-c and swift, and especially interfacing with private frameworks from Swift, please open a PR, or shoot me an email!

## Brief Summary

`bboy` allows users to interact with macOS Bluetooth functionalities such as:
-   Querying Bluetooth power state.
-   Listing paired, connected, or discoverable devices.
-   Getting detailed information about specific devices.
-   Connecting to, disconnecting from, pairing with, and unpairing devices.

```console
$ bboy list paired
Address: 00-11-22-33-44-55, Name: My Bluetooth Keyboard, Connected: Yes, RSSI: -50 dbm, Incoming: No
Address: AA-BB-CC-DD-EE-FF, Name: My Bluetooth Mouse, Connected: Yes, RSSI: -65 dbm, Incoming: No
```

## Get Started

Get started by following the [installation instructions](#install) below. Once installed, you can explore the available commands and options.

## Tutorial

`bboy` follows a standard command-line structure:

```shell
bboy [global-options] <subcommand> [subcommand-options-and-arguments]
```

**Global Options:**
-   `--debug`: Enable debug logging for more detailed output.
-   `--verbose`: Enable verbose logging (implies debug) for maximum output.

### Core Subcommands:

#### 1. `get`: Get Bluetooth system states

Used to retrieve system-level Bluetooth information.

-   **Get Power State**:
    Check if Bluetooth is currently powered on. Outputs `1` for on, `0` for off.
    ```shell
    bboy get power
    ```
    If no specific state is requested, it will prompt you:
    ```shell
    $ bboy get
    No state retrieval specified
    ```

#### 2. `list`: List Bluetooth devices

This command has several sub-subcommands to list different categories of devices. If no sub-subcommand is specified, it defaults to `list paired`.

-   **List Paired Devices** (`list paired` - default):
    Shows all devices that are paired with your Mac.
    ```shell
    bboy list
    bboy list paired
    ```
    Output includes Address, Name, Connected status, RSSI, and Incoming status.

-   **List Connected Devices** (`list connected`):
    Shows only the devices currently connected to your Mac.
    ```shell
    bboy list connected
    ```
    Output includes Address, Name, RSSI, Paired status, and Incoming status.

-   **Inquire Devices in Range** (`list in-range`):
    Scans for nearby Bluetooth devices.
    ```shell
    bboy list in-range
    ```
    By default, it scans for 10 seconds. You can specify a custom duration:
    ```shell
    bboy list in-range <duration_in_seconds>
    # Example: Scan for 15 seconds
    bboy list in-range 15
    ```
    Output includes Address, Name, Connected status, RSSI, Paired status, and Incoming status.

#### 3. `device`: Manage Bluetooth devices

Interact with specific Bluetooth devices using their ID (MAC address or name).

-   **Device Actions**:
    The `device` command takes a device ID and an action to perform.

    -   `info`: Show detailed information for a device.
        ```shell
        bboy device <device_id> info
        # Example: bboy device 00-11-22-33-44-55 info
        # Example: bboy device "My Bluetooth Keyboard" info
        ```

    -   `is-connected`: Check if a specific device is connected. Outputs `1` for connected, `0` for not connected.
        ```shell
        bboy device <device_id> is-connected
        ```

    -   `connect`: Connect to a device.
        ```shell
        bboy device <device_id> connect
        ```

    -   `disconnect`: Disconnect from a device.
        ```shell
        bboy device <device_id> disconnect
        ```

    -   `pair`: Pair with a device. A PIN may be required for some devices.
        ```shell
        bboy device <device_id> pair
        bboy device <device_id> pair --pin <your_pin>
        ```

    -   `unpair`: Unpair a device.
        ```shell
        bboy device <device_id> unpair
        ```

**Example Workflow:**

1.  List paired devices:
    ```shell
    bboy list paired
    ```
    *(Identify the device ID, e.g., `AA-BB-CC-DD-EE-FF`)*

2.  Check if it's connected:
    ```shell
    bboy device AA-BB-CC-DD-EE-FF is-connected
    ```

3.  If not connected, connect to it:
    ```shell
    bboy device AA-BB-CC-DD-EE-FF connect
    ```

## Design Philosophy

`bboy` aims to be:
-   **Focused**: A dedicated utility for macOS Bluetooth control.
-   **Intuitive**: Leveraging `ArgumentParser` for a clear and standard CLI experience.
-   **Effective**: Providing direct access to common Bluetooth operations.
-   **Informative**: Offering useful feedback and logging options for troubleshooting.

## Building and Debugging

### Building

1.  Ensure you have Xcode Command Line Tools installed.
2.  Clone the repository (if applicable) or navigate to the project directory.
3.  Build the project using Swift Package Manager:
    -   For a debug build:
        ```shell
        swift build
        ```
        The executable will be located at `.build/debug/bboy`.
    -   For a release build:
        ```shell
        swift build -c release
        ```
        The executable will be located at `.build/release/bboy`.

### Debugging

`bboy` includes logging flags to help with debugging:
-   `--debug`: Enables general debug messages.
    ```shell
    bboy --debug list paired
    ```
-   `--verbose`: Enables more detailed verbose messages (implies debug).
    ```shell
    bboy --verbose device <device_id> connect
    ```
    Logs are managed by `bboyLogger` and will be printed to standard error/output.

## Install

1.  **Build from Source (Recommended)**:
    Follow the [Building](#building) instructions to create a release build:
    ```shell
    swift build -c release
    ```
    Then, copy the executable to a directory in your `PATH`, for example `/usr/local/bin`:
    ```shell
    sudo cp .build/release/bboy /usr/local/bin/
    ```
    Ensure `/usr/local/bin` is in your shell's `PATH` environment variable.

2.  **Homebrew (Future Possibility)**:

## Changelog

For a detailed list of changes, please see the [CHANGELOG.md](CHANGELOG.md) file.

## Libraries Used

-   [**swift-argument-parser**](https://github.com/apple/swift-argument-parser): For parsing command-line arguments.
-   [**swift-log**](https://github.com/apple/swift-log): A Logging API for Swift.
-   **BlueKit**: A custom internal library/module for handling Bluetooth interactions (Local only for now, working on uploading...).
-   **Foundation**: Standard Apple framework.
-   **IOBluetooth**: Standard macOS framework for Bluetooth communication.

## Acknowledgements

-   This tool builds upon the capabilities provided by Apple's CoreBluetooth and IOBluetooth frameworks.
-   Thanks to the Swift community for excellent tools and libraries (YAH).

## License

This project is licensed under the [MIT] - see the [LICENSE](LICENSE) file for details. 
