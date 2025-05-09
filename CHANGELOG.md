# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.6.8] - 2025-05-08

### Added
- **Core Bluetooth Library (`BlueKit`)**:
    - Introduced `BlueKit`, a new Swift library to encapsulate all core Bluetooth logic, promoting modularity and reusability.
    - `BluetoothManager`: Manages system-level Bluetooth states (e.g., power).
    - `DeviceManager`: Handles device-specific operations including discovery, fetching device information, connection, pairing, and unpairing. Initial implementation includes internal improvements for robust device identification and interaction.
    - `Errors.swift`: Defines custom error types for clear error reporting.
    - `Logging.swift`: Provides a centralized mechanism for logging.
    - `Models.swift`: Contains shared data structures like `State`, `Format`, `Operation`, and `DevicePrintOptions`.
- **Command-Line Interface (`blueutil`)**:
    - Established a new CLI structure with `CLI.swift` as the main entry point.
    - `device` command: New command for interacting with specific Bluetooth devices (e.g., get info, connect, disconnect, pair, unpair).
    - `get` command: New command to retrieve Bluetooth system states (currently focused on power state).
    - `list` command: New command to list Bluetooth devices, supporting various modes (inquiry, paired, connected) and includes a `printDevices` utility for clear output.

### Changed
- **Project Structure & Build**:
    - Refactored the project to separate command-line interface logic (`Blue` target) from core Bluetooth functionality (`BlueKit` library).
    - Updated `Package.swift` to define the new `BlueKit` library and `blueutil` executable targets.
    - Upgraded Swift tools version to 5.9 and adjusted the minimum macOS deployment target.
- **Command Functionality & Usage**:
    - `device` command: Enhanced to use subcommands (`info`, `is-connected`, `connect`, `disconnect`, `pair`, `unpair`) for actions, replacing the previous flag-based approach for clearer and more extensible usage.
    - `list` command: Refactored to use subcommands (`inquiry`, `paired`, `connected`) for different listing modes, improving command structure over previous flag-based options.
    - `get` command: Streamlined to focus on retrieving power state; the option for discoverable state has been removed (see Removed section).
- **Code Style**:
    - Applied `swift-format` across the entire codebase to ensure consistent code style and readability.

### Removed
- Removed the placeholder `getDiscoverableState()` method from `BlueKit.BluetoothManager` as it was not fully implemented and determined to be faulty.
- Consequently, removed the `--discoverable` option from the `get` command.

---

[Unreleased]: https://example.com/your-project/compare/v0.6.8...HEAD
[0.6.8]: https://example.com/your-project/compare/...v0.6.8
