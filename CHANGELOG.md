# Changelog

All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] – 2025-05-09

### Added
- Integrate **BlueKit** as an external package dependency (from version 0.6.8) instead of a vendored library.  
- Annotate all command entry points (`run()` methods in `Device`, `Get`, `List`, `Paired`, `Connected`) with `@MainActor` to enforce structured concurrency.  
- Execute logging in an isolated context via the updated BlueKit logging subsystem.

### Changed
- **Package.swift**  
  - Removed the local `BlueKit` library target.  
  - Added a remote dependency on `BlueKit` (v0.6.8).  
  - Updated the `bboy` executable target to depend on the remote `BlueKit` package.  
- Command implementations  
  - Dropped explicit logger injection into `DeviceManager` and `BluetoothManager`; commands now rely on `BlueBoyLogger.logger`.  
  - Instantiated `DeviceManager` and `BluetoothManager` without passing a logger parameter.  

### Removed
- Deleted internal BlueKit source modules:  
  - `BluetoothManager.swift`  
  - `DeviceManager.swift`  
  - `Errors.swift`  
  - `Logging.swift`  
- Removed the obsolete `options.md` documentation file.

## [0.7.0] - 2025-05-08

### Added
- Introduced a `Justfile` to streamline common development tasks. This includes recipes for building (debug and release), packaging binaries, compressing releases, generating checksums, creating release notes from the changelog, running the application, cleaning build artifacts, local installation, and updating Swift package dependencies.
- Implemented `BlueBoyLogger`, a dedicated logging mechanism utilizing `swift-log` for the `bboy` executable, enhancing debuggability and providing `--debug` and `--verbose` options.

### Changed
- Standardized logger usage across the project: `BlueBoyLogger` is now used within the `bboy` executable, and `BlueKitLogger` is used within the `BlueKit` library, replacing previous `BlueUtilLogger` references.
- Relocated `Models.swift` (which includes the `printDevices` function) from the `BlueKit` library target to the `BlueBoy` executable target. The `printDevices` function was also updated to utilize `IOBluetoothDevice` and the new `BlueBoyLogger`.
- Simplified the default output for `list` subcommands by using a basic set of `DevicePrintOptions`.
- Renamed the main executable product from `BlueBoy` to `bboy` in `Package.swift` for brevity and to match common command-line utility naming.
- Significantly revised and improved `README.md`:
    - Updated the project description and added a note on feature-parity with the original `blueutil` and an invitation for contributions.
    - Provided more comprehensive usage examples, clearer build instructions, and details on the design philosophy.
- Refined the command-line interface structure for better clarity and consistency with `swift-argument-parser` conventions:
    - The `get` command now uses `power` as a subcommand (e.g., `bboy get power`) instead of relying on a flag (`get --power`).
    - The `list inquiry` subcommand has been renamed to `list in-range` (e.g., `bboy list in-range`).

### Fixed
- Corrected command invocation examples and API descriptions in `README.md` to accurately reflect the updated CLI structure (e.g., usage of `get power` and `list in-range`).
- Removed placeholder/template text from `README.md` and improved overall accuracy of the documentation.


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

## [0.1.0-alpha] - 2025-05-08

### Added
-   Initial command-line tool `Blueboy` for macOS Bluetooth management, built with Swift and ArgumentParser.
-   **`device` command:**
    -   Display detailed information for a specific device (`--info ID`).
    -   Check connection status of a device (`--is-connected ID`).
    -   Connect to a device (`--connect ID`).
    -   Disconnect from a device (`--disconnect ID`).
    -   Pair with a device, including optional PIN support (`--pair ID [PIN]`).
    -   Unpair a device (`--unpair ID`).
-   **`list` command:**
    -   List currently paired devices (`--paired`).
    -   List currently connected devices (`--connected`).
    -   Discover devices in range via Bluetooth inquiry (`--inquiry [duration]`).
    -   Internal `DevicePrintOptions` for controlling the verbosity of listed device details.
-   **`get` command:**
    -   Retrieve the current Bluetooth power state (on/off) (`--power`).
    -   Retrieve the current Bluetooth discoverable state (`--discoverable`).
-   Basic error handling using a custom `BluetoothError` enum.
-   Support for debug (`--debug`) and verbose (`--verbose`) logging via `swift-log`.
-   Initial `Package.swift` defining the project and its dependencies.
-   Documentation including a `README.md` and an `options.md` file detailing command-line usage.

### Changed
-   The experimental `set` command (for modifying power/discoverable state) evolved from using individual flags for states to accepting positional arguments for operation and state (e.g., `set power on`), before being deactivated.
-   Refined device identification logic (`getDevice`) to support lookup by both MAC address and device name from paired devices.
-   Iterative improvements to logging messages, error handling, and the robustness of device inquiry and pairing processes.

### Removed
-   `--favorites` and `--recent` options from the `list` command, and corresponding `--add-favorite`/`--remove-favorite` options from the `device` command. These were removed due to underlying API changes and deprecations in macOS 12+.
-   A global `--format` option for CLI output was explored and then removed.
-   The `set` command, while developed, was deactivated from the main list of available subcommands.
-   An experimental `wait` command (for waiting on device connection or disconnection states) was developed but not included as an active feature.

---

[Unreleased]: https://github.com/philocalyst/blueboy/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/philocalyst/blueboy/compare/v0.6.8...v1.0.0
[0.7.0]: https://github.com/philocalyst/blueboy/compare/v0.6.8...v0.7.0
[0.6.8]: https://github.com/philocalyst/blueboy/v0.1.0-alpha...v0.6.8
[0.1.0-alpha]: https://github.com/philocalyst/blueboy/compare/...v0.1.0-alpha
