# DeviceManager

A powerful iOS Swift package for reactive device monitoring using Combine framework. DeviceManager provides a centralized, type-safe way to monitor device orientation, battery status, screen properties, and Safe Area changes in real-time.

## Features

- 🔄 **Reactive Programming**: Built on Combine framework for elegant async event handling
- 📱 **Device Information**: Comprehensive device details including model, system version, screen properties
- 🔋 **Battery Monitoring**: Real-time battery level and charging status tracking
- 📐 **Orientation Tracking**: Filtered and debounced orientation change notifications
- 🛡️ **Safe Area Monitoring**: Automatic Safe Area insets tracking
- ⚡ **Performance Optimized**: Built-in debouncing and throttling for smooth UI updates
- 💾 **Memory Safe**: Proper memory management with automatic cleanup
- 🎯 **Type Safe**: Strongly typed APIs with comprehensive enum support

## Requirements

- iOS 13.0+
- macCatalyst 13.0+
- Swift 5.7+
- Xcode 14.0+

## Installation

### Swift Package Manager

Add DeviceManager to your project using Xcode:

1. In Xcode, select **File** → **Add Package Dependencies**
2. Enter the repository URL: `https://github.com/yourusername/DeviceManager`
3. Click **Add Package**

Or add it to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/DeviceManager", from: "1.0.0")
]
```

## Quick Start

### Basic Usage

```swift
import DeviceManager
import Combine

class ViewController: UIViewController {
    private var cancellables = Set<AnyCancellable>()
    private let deviceManager = DeviceManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Subscribe to all device changes
        deviceManager.$currentDevice
            .receive(on: DispatchQueue.main)
            .sink { device in
                print("Device updated: \(device.description)")
            }
            .store(in: &cancellables)
    }
}
```

### Orientation Monitoring

```swift
// Monitor significant orientation changes only
DeviceManager.shared.significantOrientationChanges
    .receive(on: DispatchQueue.main)
    .sink { orientation in
        switch orientation {
        case .portrait:
            // Handle portrait orientation
            break
        case .landscapeLeft, .landscapeRight:
            // Handle landscape orientation
            break
        default:
            break
        }
    }
    .store(in: &cancellables)

// Debounced orientation changes to avoid frequent updates
DeviceManager.shared.debouncedOrientationChanges(for: 0.5)
    .receive(on: DispatchQueue.main)
    .sink { orientation in
        // Perform expensive UI updates here
    }
    .store(in: &cancellables)
```

### Battery Monitoring

```swift
// Monitor critical battery levels (20% and below)
DeviceManager.shared.criticalBatteryChanges
    .receive(on: DispatchQueue.main)
    .sink { level in
        showLowBatteryAlert(level: level)
    }
    .store(in: &cancellables)

// Monitor charging status
DeviceManager.shared.chargingStatusChanges
    .receive(on: DispatchQueue.main)
    .sink { isCharging in
        updateBatteryIcon(charging: isCharging)
    }
    .store(in: &cancellables)

// Throttled battery level updates
DeviceManager.shared.throttledBatteryChanges(for: 2.0)
    .receive(on: DispatchQueue.main)
    .sink { level in
        batteryLabel.text = "Battery: \(Int(level * 100))%"
    }
    .store(in: &cancellables)
```

### Safe Area Monitoring

```swift
// Monitor Safe Area changes (useful for orientation changes)
DeviceManager.shared.safeAreaPublisher
    .receive(on: DispatchQueue.main)
    .sink { safeArea in
        // Update UI constraints based on Safe Area
        updateLayoutConstraints(for: safeArea)
    }
    .store(in: &cancellables)
```

### Device Type Detection

```swift
let deviceManager = DeviceManager.shared

if deviceManager.isiPhone() {
    // iPhone-specific logic
    setupiPhoneLayout()
} else if deviceManager.isiPad() {
    // iPad-specific logic
    setupiPadLayout()
}

// Get screen properties
let screenSize = deviceManager.getScreenSize()
let safeArea = deviceManager.getSafeAreaInsets()
```

## Advanced Usage

### Custom Update Intervals

```swift
// Get device updates every 5 seconds
DeviceManager.shared.deviceUpdates(every: 5.0)
    .receive(on: DispatchQueue.main)
    .sink { device in
        logDeviceState(device)
    }
    .store(in: &cancellables)
```

### Combining Multiple Publishers

```swift
// Combine orientation and battery changes
Publishers.CombineLatest(
    DeviceManager.shared.significantOrientationChanges,
    DeviceManager.shared.batteryLevelPublisher
)
.receive(on: DispatchQueue.main)
.sink { orientation, batteryLevel in
    // Handle combined changes
    updateUI(orientation: orientation, battery: batteryLevel)
}
.store(in: &cancellables)
```

## API Reference

### DeviceManager

#### Properties

- `currentDevice: Device` - Current device information (Published property)
- `orientationPublisher` - Publisher for orientation changes
- `batteryLevelPublisher` - Publisher for battery level changes
- `batteryStatePublisher` - Publisher for battery state changes
- `safeAreaPublisher` - Publisher for Safe Area changes
- `deviceChangesPublisher` - Combined publisher for all device changes

#### Computed Publishers

- `significantOrientationChanges` - Filtered orientation changes (portrait/landscape only)
- `criticalBatteryChanges` - Battery level changes when ≤ 20%
- `chargingStatusChanges` - Charging status changes

#### Methods

- `getCurrentDevice() -> Device` - Get current device information
- `getDeviceDescription() -> String` - Get device description summary
- `isiPhone() -> Bool` - Check if device is iPhone
- `isiPad() -> Bool` - Check if device is iPad
- `getScreenSize() -> CGSize` - Get screen size in points
- `getSafeAreaInsets() -> UIEdgeInsets` - Get current Safe Area insets

#### Convenience Methods

- `debouncedOrientationChanges(for:)` - Debounced orientation publisher
- `throttledBatteryChanges(for:)` - Throttled battery level publisher
- `deviceUpdates(every:)` - Periodic device updates publisher

### Device

A struct containing comprehensive device information:

```swift
struct Device {
    let name: String                    // Device name
    let model: String                   // Device model (e.g., "iPhone 15 Pro")
    let systemName: String              // System name (e.g., "iOS")
    let systemVersion: String           // System version (e.g., "17.0")
    let screenSize: CGSize              // Screen size in points
    let screenScale: CGFloat            // Screen scale factor
    let idiom: UIUserInterfaceIdiom     // Device idiom (.phone, .pad, etc.)
    let orientation: UIDeviceOrientation // Current orientation
    let batteryLevel: Float             // Battery level (0.0-1.0)
    let batteryState: UIDevice.BatteryState // Battery state
    let isSimulator: Bool               // Running on simulator
    let deviceIdentifier: String        // Device identifier
    
    var description: String             // Formatted device description
}
```

## Best Practices

1. **Memory Management**: Always store Combine subscriptions in `cancellables` set
2. **Main Thread**: Use `.receive(on: DispatchQueue.main)` for UI updates
3. **Performance**: Use debounced/throttled publishers for expensive operations
4. **Battery Monitoring**: Only monitor battery when needed to preserve battery life
5. **Weak References**: Use `[weak self]` in sink closures to avoid retain cycles

## Example App

Check out the example app in the repository for a complete implementation demonstrating all features.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

If you find this package helpful, please give it a ⭐️ on GitHub!

For questions, issues, or feature requests, please open an issue on GitHub.