import XCTest

final class LaunchScreenTests: XCTestCase {
    func testAppBundleContainsDeclaredLaunchStoryboard() throws {
        // Inspect the built app, since a source-only check cannot catch a missing resource.
        let name = try XCTUnwrap(
            Bundle.main.object(forInfoDictionaryKey: "UILaunchStoryboardName") as? String
        )
        XCTAssertFalse(name.isEmpty)
        let resource = try XCTUnwrap(Bundle.main.url(forResource: name, withExtension: "storyboardc"))
        var isDirectory: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: resource.path, isDirectory: &isDirectory))
        XCTAssertTrue(isDirectory.boolValue)
    }
}
