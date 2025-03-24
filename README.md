
# Blueboy

The powerful and feature-rich command-line utility for controlling Bluetooth on macOS. Blueboy provides a comprehensive set of commands for managing Bluetooth devices, connections, and system states directly from your terminal.

## Features

- 🔍 List paired and connected devices
- 🔄 Connect to and disconnect from devices
- 🔌 Toggle Bluetooth power and discoverability
- 📱 Get detailed device information
- 🔐 Pair with devices (with optional PIN support)
- ⏱️ Inquire for devices in range with customizable duration

## Installation

<!-- ### Homebrew -->

<!-- ```bash -->
<!-- brew install blueutil -->
<!-- ``` -->

### From Source

```bash
git clone https://github.com/philocalyst/blueutil.git
cd blueutil
swift build -c release
cp .build/release/blueutil /usr/local/bin/
```

## Usage

Blueboy offers several commands through a clean, intuitive interface:

### Device Management

```bash
# Get information about a specific device
blueutil device 00-11-22-33-44-55 --info

# Connect to a device
blueutil device 00-11-22-33-44-55 --connect

# Disconnect from a device
blueutil device 00-11-22-33-44-55 --disconnect

# Pair with a device (with optional PIN)
blueutil device 00-11-22-33-44-55 --pair --pin 1234

# Unpair a device
blueutil device 00-11-22-33-44-55 --unpair


# Check if a device is connected
blueutil device 00-11-22-33-44-55 --is-connected
```

### Listing Devices

```bash
# List all paired devices
blueutil list --paired

# List connected devices
blueutil list --connected

# Search for devices in range (specify duration in seconds)
blueutil list --inquiry 10
```

### System Controls

```bash
# Set Bluetooth power state
blueutil set --power on
blueutil set --power off
blueutil set --power toggle

# Set discoverable state
blueutil set --discoverable on
blueutil set --discoverable off

# Get current power state
blueutil get --power

# Get discoverable state
blueutil get --discoverable
```

### Output Formatting

```bash
# Change output format
blueutil --format json
blueutil --format json-pretty
```

## How It Works

Blueboy leverages macOS CoreBluetooth and IOBluetooth frameworks to provide a comprehensive command-line interface for Bluetooth management. Built with Swift's ArgumentParser, it offers a modern, type-safe command structure with helpful error handling.

The tool is designed with a modular architecture:

1. **Command Structure** - Clean subcommand organization for intuitive usage
2. **Device Management** - Robust device lookup and connection handling
3. **Error Handling** - Descriptive error messages for troubleshooting
4. **Logging** - Integrated logging for development and debugging

## Examples

### Managing a Bluetooth Headset

```bash
# Connect to headphones
blueutil device "My Headphones" --connect

# Check connection status
blueutil device "My Headphones" --is-connected

# Disconnect when done
blueutil device "My Headphones" --disconnect
```

### Finding New Devices

```bash
# Search for devices in range for 30 seconds
blueutil list --inquiry 30

# Pair with a new device
blueutil device 00-11-22-33-44-55 --pair
```

### System Automation

```bash
# Toggle Bluetooth power
blueutil set --power toggle

# Check if Bluetooth is enabled
if [ $(blueutil get --power) -eq 1 ]; then
    echo "Bluetooth is enabled"
else
    echo "Bluetooth is disabled"
fi
```

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.

1. Fork the repository
2. Create your feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add some amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

## Acknowledgments

Blueboy builds on the foundations laid by earlier Bluetooth utilities for macOS and is inspired by the need for comprehensive command-line control of Bluetooth devices.
Very large thanks to Toy and [blueutil](https://github.com/toy/blueutil)

## License

[MIT](LICENSE)

---

Created under duress by Miles ;)
