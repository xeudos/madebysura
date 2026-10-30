import XCTest

final class SessionControlsTests: XCTestCase {
    private func launch(largeText: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--session-ui-test"]
        if largeText { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launchEnvironment["LC_HOME_PATH"] = "/ui-test-host"
        app.launch()
        return app
    }
    private func assertVisible(_ button: XCUIElement, in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(button.waitForExistence(timeout: 15), file: file, line: line)
        XCTAssertTrue(button.isHittable, file: file, line: line)
        XCTAssertGreaterThanOrEqual(button.frame.minY, app.frame.minY, file: file, line: line)
        XCTAssertLessThanOrEqual(button.frame.maxY, app.frame.maxY, file: file, line: line)
    }
    func testControlsStayVisibleAndSecondSkipTap() {
        let app = launch()
        let skip = app.buttons["session.skip"]
        let primary = app.buttons["session.primary"]
        assertVisible(skip, in: app)
        assertVisible(primary, in: app)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Pinned timer controls"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        skip.tap()
        XCTAssertTrue(primary.label.contains("Skip now"))
        skip.tap()
        let resumed = expectation(for: NSPredicate(format: "label CONTAINS %@", "Pause"), evaluatedWith: primary)
        wait(for: [resumed], timeout: 5)
        assertVisible(skip, in: app)
    }
    func testControlsStayOnScreenWithLargeAccessibilityText() {
        let app = launch(largeText: true)
        assertVisible(app.buttons["session.skip"], in: app)
        assertVisible(app.buttons["session.primary"], in: app)
        app.swipeUp()
        assertVisible(app.buttons["session.skip"], in: app)
        assertVisible(app.buttons["session.primary"], in: app)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Pinned controls with large accessibility text"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
