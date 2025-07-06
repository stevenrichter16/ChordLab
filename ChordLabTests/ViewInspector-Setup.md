# ViewInspector Setup Guide for ChordLab

## Overview
ViewInspector is a library that allows you to inspect and test SwiftUI views programmatically. This guide explains how to set it up and use it in the ChordLab project.

## Installation

### Using Swift Package Manager (Recommended)

1. In Xcode, go to File → Add Package Dependencies
2. Enter the URL: `https://github.com/nalexn/ViewInspector`
3. Choose the latest version (currently 0.9.11 or later)
4. Add to the `ChordLabTests` target only

### Manual Installation

Add this to your Package.swift if you have one:
```swift
dependencies: [
    .package(url: "https://github.com/nalexn/ViewInspector", from: "0.9.11")
],
targets: [
    .testTarget(
        name: "ChordLabTests",
        dependencies: ["ViewInspector"]
    )
]
```

## Setup Requirements

### 1. Import ViewInspector
```swift
import ViewInspector
```

### 2. Make Views Inspectable
Add conformance to `Inspectable` for each custom view you want to test:
```swift
extension MyCustomView: Inspectable { }
```

### 3. Handle @MainActor
Since SwiftUI views often require main actor, mark your test class:
```swift
@MainActor
final class MyViewTests: XCTestCase {
    // tests here
}
```

## Test Pattern Examples

### Basic View Inspection
```swift
func testViewExists() throws {
    // Given
    let view = MyView()
    
    // When
    let inspected = try view.inspect()
    
    // Then
    XCTAssertNotNil(inspected)
}
```

### Testing Text Content
```swift
func testTextContent() throws {
    let view = MyView()
    let text = try view.inspect().text()
    XCTAssertEqual(try text.string(), "Expected Text")
}
```

### Testing View Hierarchy
```swift
func testViewHierarchy() throws {
    let view = MyView()
    let vStack = try view.inspect().vStack()
    let firstText = try vStack.text(0)
    let button = try vStack.button(1)
}
```

### Testing with Environment Objects
```swift
func testWithEnvironment() throws {
    let theoryEngine = TheoryEngine()
    let view = MyView()
        .environment(theoryEngine)
    
    let inspected = try view.inspect()
    // Test view with environment
}
```

## Common ViewInspector Methods

- `.text()` - Find Text views
- `.button()` - Find Button views  
- `.vStack()`, `.hStack()`, `.zStack()` - Find stack views
- `.forEach()` - Iterate through ForEach content
- `.view(MyCustomView.self)` - Find custom views
- `.find(text: "...")` - Search for text in hierarchy
- `.findAll(ViewType.self)` - Find all views of a type

## Best Practices

1. **Test One Thing at a Time**: Each test should verify a single aspect
2. **Use Descriptive Names**: Test method names should explain what they test
3. **Mock Dependencies**: Use mock objects for services/engines
4. **Test States**: Verify view changes with different states
5. **Performance Tests**: Measure view creation/inspection time

## Troubleshooting

### "View type is not inspectable"
Add `extension YourView: Inspectable { }`

### "Function unavailable"
Some SwiftUI features aren't supported by ViewInspector. Check their documentation.

### "Index out of range"
The view hierarchy might be different than expected. Print the view structure:
```swift
print(try view.inspect().pathToRoot)
```

## Running Tests

1. Select the test scheme in Xcode
2. Press Cmd+U to run all tests
3. Or click the diamond next to individual tests

## Current Test Files

- `ChordVisualizerViewTests.swift` - Comprehensive tests for the main chord visualizer
- `ColorLegendViewInspectorTests.swift` - Simple example tests for the color legend component

## Next Steps

1. Install ViewInspector package
2. Run the existing tests to verify setup
3. Extend tests to cover more views and scenarios
4. Add accessibility identifier tests
5. Create tests for user interactions

## Resources

- [ViewInspector Documentation](https://github.com/nalexn/ViewInspector)
- [ViewInspector Guide](https://github.com/nalexn/ViewInspector/blob/master/guide.md)
- [SwiftUI Testing Best Practices](https://www.swiftbysundell.com/articles/swiftui-testing-best-practices/)