General Options:

    No options: Outputs the current Bluetooth state (on or off).
    -h, --help: Displays this help message.
    -v, --version: Shows the version of blueutil.

Power State Options:

    -p, --power: Outputs the current power state as 1 (on) or 0 (off).
    -p, --power STATE: Sets the power state. STATE can be one of: 1, on, 0, off, toggle.

Discoverable State Options:

    -d, --discoverable: Outputs the current discoverable state as 1 (discoverable) or 0 (not discoverable).
    -d, --discoverable STATE: Sets the discoverable state. STATE can be one of: 1, on, 0, off, toggle.

Device Listing Options:

    --favourites, --favorites: Lists favourite devices. Note that this returns an empty list starting with macOS 12/Monterey.
    --inquiry [T]: Inquires for devices in range. The default duration is 10 seconds. T can specify a different duration in seconds.
    --paired: Lists paired devices.
    --recent [N]: Lists recently used devices. The default number is 10. Use 0 to list all. Note that this returns an empty list starting with macOS 12/Monterey.
    --connected: Lists connected devices.

Device Information and Connection Options:

    --info ID: Shows detailed information about the device with the specified ID.
    --is-connected ID: Outputs the connected state of the device with the specified ID as 1 (connected) or 0 (not connected).
    --connect ID: Creates a connection to the device with the specified ID.
    --disconnect ID: Closes the connection to the device with the specified ID.
    --pair ID [PIN]: Pairs with the device with the specified ID. An optional PIN (up to 16 characters) can be provided, which will be used instead of interactive input if requested.
    --unpair ID: EXPERIMENTAL - Unpairs the device with the specified ID.
    --add-favourite ID, --add-favorite ID: Adds the device with the specified ID to favourites. Note that this does nothing starting with macOS 12/Monterey.
    --remove-favourite ID, --remove-favorite ID: Removes the device with the specified ID from favourites. Note that this does nothing starting with macOS 12/Monterey.

Output Formatting Option:

    --format FORMAT: Changes the output format for info and all listing commands. FORMAT can be one of: default, new-default, json, json-pretty.

Experimental Wait Options:

    --wait-connect ID [TIMEOUT]: EXPERIMENTAL - Waits for the device with the specified ID to connect. An optional TIMEOUT in seconds can be specified.
    --wait-disconnect ID [TIMEOUT]: EXPERIMENTAL - Waits for the device with the specified ID to disconnect. An optional TIMEOUT in seconds can be specified.
    --wait-rssi ID OP VALUE [PERIOD [TIMEOUT]]: EXPERIMENTAL - Waits for the device's RSSI value to meet a certain condition.
        OP can be one of: >, >=, <, <=, =, !=, gt, ge, lt, le, eq, ne.
        VALUE is the RSSI value to compare against.
        PERIOD is the checking interval in seconds (defaults to 1).
        TIMEOUT is the maximum wait time in seconds (defaults to 0, meaning no timeout).

Important Notes:

    ID can be the device's address (xxxxxxxxxxxx, xx-xx-xx-xx-xx-xx, or xx:xx:xx:xx:xx:xx) or its name (if found in paired or recent devices).
    Favourite devices and recent access date are not stored starting with macOS 12/Monterey.
    blueutil will refuse to run as root user by default. Use the environment variable BLUEUTIL_ALLOW_ROOT=1 to override.
