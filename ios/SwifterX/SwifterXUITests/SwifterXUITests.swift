import XCTest

/// App Store screenshots via `fastlane screenshots` (scheme **SwifterXUITests**).
/// The app launches with `-FASTLANE_SNAPSHOT` so `AppState` opens the customer **main** tab without sign-in flows.
final class SwifterXUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAppStoreScreenshots() throws {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 30))

        snapshot("01_Home")

        let servicesTab = tabBar.buttons["Services"]
        if servicesTab.waitForExistence(timeout: 5) {
            servicesTab.tap()
            snapshot("02_Services")
        }
    }
}
