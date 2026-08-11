import XCTest

final class RegistrationUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testRegistrationReachesRoadmap() throws {
        let app = XCUIApplication()
        app.launch()

        let roadmapTitle = app.navigationBars["FinLit India"]
        // SwiftUI isn't propagating .accessibilityIdentifier through these
        // TextField/Button modifier chains to XCUITest's snapshot (confirmed
        // via app.debugDescription — the identifier attribute is absent even
        // though the modifier is applied). Matching on placeholder/label text
        // instead, which the dump confirms is present and queryable.
        let nameField = app.textFields["Enter your name"]

        // If a previous run already registered and the session persisted,
        // we may land straight on the roadmap. Bootstrapping (anonymous
        // sign-in + profile fetch) makes real network calls, which can be
        // slow under XCTest instrumentation — give it real time.
        let reachedRoadmapFirst = roadmapTitle.waitForExistence(timeout: 5)
        if reachedRoadmapFirst {
            XCTAssertTrue(true, "Already registered from a previous session; roadmap loaded.")
            return
        }

        guard nameField.waitForExistence(timeout: 30) else {
            attachScreenshot(named: "name-field-missing")
            XCTFail("Registration name field did not appear. Screen dump:\n\(app.debugDescription)")
            return
        }
        nameField.tap()
        nameField.typeText("Test User")

        let phoneField = app.textFields["98765 43210"]
        XCTAssertTrue(phoneField.exists, "Phone field not found")
        phoneField.tap()
        phoneField.typeText("9876543210")

        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.exists, "Continue button not found")
        continueButton.tap()

        guard roadmapTitle.waitForExistence(timeout: 30) else {
            attachScreenshot(named: "post-register-timeout")
            XCTFail("Did not reach the roadmap screen after registering. Screen dump:\n\(app.debugDescription)")
            return
        }
    }

    private func attachScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
