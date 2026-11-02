import XCTest

final class PlannerUITests: XCTestCase {
  @MainActor func testLaunchAndAdd() {
    let app = XCUIApplication()
    app.launch()
    XCTAssertTrue(app.navigationBars["OverlapWindow"].waitForExistence(timeout: 10))
    XCTAssertTrue(app.staticTexts["Chicago"].exists)
    app.buttons["Add participant"].tap()
    let field = app.textFields["Name"]
    XCTAssertTrue(field.waitForExistence(timeout: 3))
    field.tap()
    field.typeText("Remote team")
    app.buttons["Add"].tap()
    XCTAssertTrue(app.staticTexts["Remote team"].waitForExistence(timeout: 3))
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.lifetime = .keepAlways
    add(attachment)
  }
}
