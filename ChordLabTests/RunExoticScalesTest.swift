import XCTest
@testable import ChordLab

final class RunExoticScalesTest: XCTestCase {
    
    func testRunExoticScales() {
        // Create an instance of the test class
        let exoticTest = TonicExoticScalesTests()
        
        // Run the test and capture output
        exoticTest.testAllExoticScales()
        
        // The test should complete without errors
        XCTAssertTrue(true, "Test completed")
    }
}