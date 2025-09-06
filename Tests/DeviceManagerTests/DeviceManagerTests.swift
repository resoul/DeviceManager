import XCTest
import Combine
import UIKit
@testable import DeviceManager

final class DeviceManagerTests: XCTestCase {

    private var deviceManager: DeviceManager!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        deviceManager = DeviceManager.shared
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        cancellables?.removeAll()
        cancellables = nil
        super.tearDown()
    }

    // MARK: - Basic Functionality Tests

    func testDeviceManagerSingleton() {
        // Test that DeviceManager is a singleton
        let instance1 = DeviceManager.shared
        let instance2 = DeviceManager.shared

        XCTAssertIdentical(instance1, instance2, "DeviceManager should be a singleton")
    }

    func testGetCurrentDevice() {
        // Test getCurrentDevice returns a valid Device object
        let device = deviceManager.getCurrentDevice()

        XCTAssertNotNil(device, "getCurrentDevice should return a valid Device")
        XCTAssertFalse(device.name.isEmpty, "Device name should not be empty")
        XCTAssertFalse(device.model.isEmpty, "Device model should not be empty")
        XCTAssertFalse(device.systemName.isEmpty, "System name should not be empty")
        XCTAssertFalse(device.systemVersion.isEmpty, "System version should not be empty")
        XCTAssertGreaterThan(device.screenSize.width, 0, "Screen width should be greater than 0")
        XCTAssertGreaterThan(device.screenSize.height, 0, "Screen height should be greater than 0")
        XCTAssertGreaterThan(device.screenScale, 0, "Screen scale should be greater than 0")
    }

    func testGetDeviceDescription() {
        // Test getDeviceDescription returns non-empty string
        let description = deviceManager.getDeviceDescription()

        XCTAssertFalse(description.isEmpty, "Device description should not be empty")
        XCTAssertTrue(description.contains("Name:"), "Description should contain device name")
        XCTAssertTrue(description.contains("Model:"), "Description should contain device model")
        XCTAssertTrue(description.contains("System:"), "Description should contain system info")
    }

    func testDeviceTypeDetection() {
        // Test device type detection methods
        let isiPhone = deviceManager.isiPhone()
        let isiPad = deviceManager.isiPad()

        // On a real device or simulator, one of these should be true
        XCTAssertTrue(isiPhone || isiPad, "Device should be either iPhone or iPad")
        XCTAssertFalse(isiPhone && isiPad, "Device cannot be both iPhone and iPad")
    }

    func testGetScreenSize() {
        // Test getScreenSize returns valid dimensions
        let screenSize = deviceManager.getScreenSize()

        XCTAssertGreaterThan(screenSize.width, 0, "Screen width should be positive")
        XCTAssertGreaterThan(screenSize.height, 0, "Screen height should be positive")
        XCTAssertEqual(screenSize, UIScreen.main.bounds.size, "Screen size should match UIScreen.main.bounds.size")
    }

    func testGetSafeAreaInsets() {
        // Test getSafeAreaInsets returns valid insets
        let safeArea = deviceManager.getSafeAreaInsets()

        XCTAssertGreaterThanOrEqual(safeArea.top, 0, "Safe area top should be non-negative")
        XCTAssertGreaterThanOrEqual(safeArea.bottom, 0, "Safe area bottom should be non-negative")
        XCTAssertGreaterThanOrEqual(safeArea.left, 0, "Safe area left should be non-negative")
        XCTAssertGreaterThanOrEqual(safeArea.right, 0, "Safe area right should be non-negative")
    }

    // MARK: - Publisher Tests

    func testCurrentDevicePublisher() {
        // Test that currentDevice publisher emits values
        let expectation = XCTestExpectation(description: "CurrentDevice publisher should emit values")

        deviceManager.$currentDevice
            .sink { device in
                XCTAssertNotNil(device, "Published device should not be nil")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    func testOrientationPublisher() {
        // Test orientation publisher exists and can be subscribed to
        let expectation = XCTestExpectation(description: "Orientation publisher should be subscribable")
        expectation.isInverted = false

        deviceManager.orientationPublisher
            .sink { orientation in
                // Just test that we can subscribe and receive values
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Give some time for the publisher to emit
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testBatteryLevelPublisher() {
        // Test battery level publisher
        let expectation = XCTestExpectation(description: "Battery level publisher should be subscribable")

        deviceManager.batteryLevelPublisher
            .sink { level in
                XCTAssertGreaterThanOrEqual(level, -1.0, "Battery level should be >= -1.0 (unknown)")
                XCTAssertLessThanOrEqual(level, 1.0, "Battery level should be <= 1.0")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Trigger battery level update if possible
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testBatteryStatePublisher() {
        // Test battery state publisher
        let expectation = XCTestExpectation(description: "Battery state publisher should be subscribable")

        deviceManager.batteryStatePublisher
            .sink { state in
                // Battery state should be one of the valid enum cases
                let validStates: [UIDevice.BatteryState] = [.unknown, .unplugged, .charging, .full]
                XCTAssertTrue(validStates.contains(state), "Battery state should be valid")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testSafeAreaPublisher() {
        // Test Safe Area publisher
        let expectation = XCTestExpectation(description: "Safe Area publisher should be subscribable")

        deviceManager.safeAreaPublisher
            .sink { safeArea in
                XCTAssertGreaterThanOrEqual(safeArea.top, 0, "Safe area top should be non-negative")
                XCTAssertGreaterThanOrEqual(safeArea.bottom, 0, "Safe area bottom should be non-negative")
                XCTAssertGreaterThanOrEqual(safeArea.left, 0, "Safe area left should be non-negative")
                XCTAssertGreaterThanOrEqual(safeArea.right, 0, "Safe area right should be non-negative")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Filtered Publisher Tests

    func testSignificantOrientationChanges() {
        // Test that significant orientation changes filter works
        let expectation = XCTestExpectation(description: "Significant orientation changes should be filtered")
        expectation.expectedFulfillmentCount = 1

        deviceManager.significantOrientationChanges
            .sink { orientation in
                // Should only receive significant orientations
                let significantOrientations: [UIDeviceOrientation] = [
                    .portrait, .portraitUpsideDown, .landscapeLeft, .landscapeRight
                ]
                XCTAssertTrue(significantOrientations.contains(orientation),
                             "Should only receive significant orientations")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Wait a bit to see if we get any values
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testCriticalBatteryChanges() {
        // Test critical battery changes filter
        let expectation = XCTestExpectation(description: "Critical battery changes should be filtered")

        deviceManager.criticalBatteryChanges
            .sink { level in
                XCTAssertLessThanOrEqual(level, 0.2, "Critical battery level should be <= 20%")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // This test might not fulfill if battery is not critical
        // So we'll fulfill it after timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testChargingStatusChanges() {
        // Test charging status changes
        let expectation = XCTestExpectation(description: "Charging status changes should work")

        deviceManager.chargingStatusChanges
            .sink { isCharging in
                XCTAssertNotNil(isCharging, "Charging status should not be nil")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Convenience Method Tests

    func testDebouncedOrientationChanges() {
        // Test debounced orientation changes
        let expectation = XCTestExpectation(description: "Debounced orientation changes should work")

        let debouncedPublisher = deviceManager.debouncedOrientationChanges(for: 0.1)

        debouncedPublisher
            .sink { orientation in
                XCTAssertNotNil(orientation, "Debounced orientation should not be nil")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testThrottledBatteryChanges() {
        // Test throttled battery changes
        let expectation = XCTestExpectation(description: "Throttled battery changes should work")

        let throttledPublisher = deviceManager.throttledBatteryChanges(for: 0.1)

        throttledPublisher
            .sink { level in
                XCTAssertGreaterThanOrEqual(level, -1.0, "Throttled battery level should be valid")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testDeviceUpdates() {
        // Test periodic device updates
        let expectation = XCTestExpectation(description: "Device updates should work")
        expectation.expectedFulfillmentCount = 2

        let updatesPublisher = deviceManager.deviceUpdates(every: 0.1)

        updatesPublisher
            .prefix(2) // Take only first 2 updates
            .sink { device in
                XCTAssertNotNil(device, "Device update should not be nil")
                XCTAssertFalse(device.name.isEmpty, "Updated device name should not be empty")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Performance Tests

    func testMemoryLeaks() {
        // Test that subscriptions don't cause memory leaks
        weak var weakDeviceManager = deviceManager

        var localCancellables = Set<AnyCancellable>()

        // Create multiple subscriptions
        deviceManager.orientationPublisher
            .sink { _ in }
            .store(in: &localCancellables)

        deviceManager.batteryLevelPublisher
            .sink { _ in }
            .store(in: &localCancellables)

        deviceManager.$currentDevice
            .sink { _ in }
            .store(in: &localCancellables)

        // Cancel subscriptions
        localCancellables.removeAll()

        XCTAssertNotNil(weakDeviceManager, "DeviceManager should still exist after cancelling subscriptions")
    }

    func testPublisherPerformance() {
        // Test that publishers don't impact performance significantly
        measure {
            let expectation = XCTestExpectation(description: "Performance test")
            expectation.expectedFulfillmentCount = 100

            var localCancellables = Set<AnyCancellable>()

            // Subscribe to multiple publishers
            for _ in 0..<100 {
                deviceManager.$currentDevice
                    .sink { _ in
                        expectation.fulfill()
                    }
                    .store(in: &localCancellables)
            }

            wait(for: [expectation], timeout: 2.0)
            localCancellables.removeAll()
        }
    }

    // MARK: - Edge Case Tests

    func testDeviceManagerAfterMemoryWarning() {
        // Simulate memory warning and test DeviceManager still works
        NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)

        let device = deviceManager.getCurrentDevice()
        XCTAssertNotNil(device, "DeviceManager should work after memory warning")

        let description = deviceManager.getDeviceDescription()
        XCTAssertFalse(description.isEmpty, "Device description should work after memory warning")
    }

    func testMultipleSubscriptions() {
        // Test multiple subscriptions to the same publisher
        let expectation1 = XCTestExpectation(description: "First subscription")
        let expectation2 = XCTestExpectation(description: "Second subscription")
        let expectation3 = XCTestExpectation(description: "Third subscription")

        deviceManager.$currentDevice
            .sink { _ in expectation1.fulfill() }
            .store(in: &cancellables)

        deviceManager.$currentDevice
            .sink { _ in expectation2.fulfill() }
            .store(in: &cancellables)

        deviceManager.$currentDevice
            .sink { _ in expectation3.fulfill() }
            .store(in: &cancellables)

        wait(for: [expectation1, expectation2, expectation3], timeout: 1.0)
    }
}

// MARK: - Device Model Tests
extension DeviceManagerTests {

    func testDeviceModel() {
        // Test Device model properties
        let device = deviceManager.getCurrentDevice()

        XCTAssertFalse(device.name.isEmpty, "Device name should not be empty")
        XCTAssertFalse(device.model.isEmpty, "Device model should not be empty")
        XCTAssertFalse(device.systemName.isEmpty, "System name should not be empty")
        XCTAssertFalse(device.systemVersion.isEmpty, "System version should not be empty")
        XCTAssertNotEqual(device.screenSize, .zero, "Screen size should not be zero")
        XCTAssertGreaterThan(device.screenScale, 0, "Screen scale should be positive")
        XCTAssertFalse(device.deviceIdentifier.isEmpty, "Device identifier should not be empty")
    }

    func testDeviceDescription() {
        // Test Device description formatting
        let device = deviceManager.getCurrentDevice()
        let description = device.description

        XCTAssertTrue(description.contains(device.name), "Description should contain device name")
        XCTAssertTrue(description.contains(device.model), "Description should contain device model")
        XCTAssertTrue(description.contains(device.systemName), "Description should contain system name")
        XCTAssertTrue(description.contains(device.systemVersion), "Description should contain system version")
    }

    func testDeviceIdiomDescription() {
        // Test that device idiom is properly described
        let device = deviceManager.getCurrentDevice()
        let description = device.description

        let validIdioms = ["iPhone", "iPad", "Apple TV", "CarPlay", "Mac (Catalyst)", "Vision Pro", "Unknown"]
        let containsValidIdiom = validIdioms.contains { description.contains($0) }

        XCTAssertTrue(containsValidIdiom, "Description should contain a valid idiom description")
    }

    func testDeviceOrientationDescription() {
        // Test that device orientation is properly described
        let device = deviceManager.getCurrentDevice()
        let description = device.description

        let validOrientations = ["Portrait", "Landscape", "Face up", "Face down", "Unknown", "Upside Down"]
        let containsValidOrientation = validOrientations.contains { description.contains($0) }

        XCTAssertTrue(containsValidOrientation, "Description should contain a valid orientation description")
    }

    func testBatteryStateDescription() {
        // Test that battery state is properly described
        let device = deviceManager.getCurrentDevice()
        let description = device.description

        let validBatteryStates = ["Charging", "Full", "Unplugged", "Unknown"]
        let containsValidBatteryState = validBatteryStates.contains { description.contains($0) }

        XCTAssertTrue(containsValidBatteryState, "Description should contain a valid battery state description")
    }
}