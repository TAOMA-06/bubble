import XCTest

final class BeadWorksUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchApp(fixtureImage: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        // Always reset storage so gallery assertions don't depend on state left behind by
        // previous test runs or manual simulator sessions.
        var args = ["-uiTestResetStorage"]
        if fixtureImage { args.append("-uiTestFixtureImage") }
        app.launchArguments = args
        app.launch()
        return app
    }

    func testHomeScreenShowsMainMenu() {
        let app = launchApp()

        XCTAssertTrue(app.buttons["menuButton_自由创作"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["menuButton_导入图片"].exists)
        XCTAssertTrue(app.buttons["menuButton_作品库"].exists)
    }

    func testFreeCreationSelectColorAndPlaceBead() {
        let app = launchApp()

        app.buttons["menuButton_自由创作"].tap()
        app.buttons["29 × 29 标准板"].tap()

        let canvas = app.otherElements["boardCanvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 5))

        let ironButton = app.buttons["ironButton"]
        XCTAssertFalse(ironButton.isEnabled, "iron button should be disabled while the board is empty")

        app.buttons["colorSwatch_2"].tap()
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

        XCTAssertTrue(ironButton.isEnabled, "placing a bead should enable ironing")
        attachScreenshot(named: "BoardEditor", of: app)
    }

    func testPhotoImportFlowWithFixtureImageEntersEditor() {
        let app = launchApp(fixtureImage: true)

        app.buttons["menuButton_导入图片"].tap()

        let useFixtureButton = app.buttons["useFixtureImageButton"]
        XCTAssertTrue(useFixtureButton.waitForExistence(timeout: 5))
        useFixtureButton.tap()

        let startButton = app.buttons["startFromTemplateButton"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        attachScreenshot(named: "PhotoImportPreview", of: app)
        startButton.tap()

        XCTAssertTrue(app.otherElements["boardCanvas"].waitForExistence(timeout: 5))
    }

    func testIroningAndSavingAddsWorkToGallery() {
        let app = launchApp()
        let workTitle = "UI 测试作品"

        app.buttons["menuButton_自由创作"].tap()
        app.buttons["16 × 16 快速板"].tap()

        let canvas = app.otherElements["boardCanvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 5))
        app.buttons["colorSwatch_3"].tap()
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

        let ironButton = app.buttons["ironButton"]
        XCTAssertTrue(ironButton.isEnabled)
        ironButton.tap()

        let titleField = app.textFields["workTitleField"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        titleField.tap()
        titleField.clearAndTypeText(workTitle)

        let saveButton = app.buttons["saveWorkButton"]
        saveButton.tap()

        let savedPredicate = NSPredicate(format: "label == %@", "已保存到作品库")
        expectation(for: savedPredicate, evaluatedWith: saveButton)
        waitForExpectations(timeout: 5)
        attachScreenshot(named: "FinishedWork", of: app)

        // Pop FinishedWorkView -> BoardEditorView -> HomeView.
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()

        app.buttons["menuButton_作品库"].tap()
        XCTAssertTrue(app.staticTexts[workTitle].waitForExistence(timeout: 5))
        attachScreenshot(named: "Gallery", of: app)

        app.buttons["galleryCard_\(workTitle)"].tap()
        XCTAssertTrue(app.buttons["reopenWorkButton"].waitForExistence(timeout: 5))
        app.buttons["reopenWorkButton"].tap()
        XCTAssertTrue(app.otherElements["boardCanvas"].waitForExistence(timeout: 5))
    }

    func testSamplePatternOpensGuidedEditor() {
        let app = launchApp()

        app.buttons["menuButton_示例图纸"].tap()
        let heart = app.buttons["patternCard_heart"]
        XCTAssertTrue(heart.waitForExistence(timeout: 5))
        heart.tap()

        XCTAssertTrue(app.otherElements["boardCanvas"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["guideToggle"].exists)
        attachScreenshot(named: "PatternEditor", of: app)
    }

    func testUndoRemovesLastStroke() {
        let app = launchApp()

        app.buttons["menuButton_自由创作"].tap()
        app.buttons["16 × 16 快速板"].tap()

        let canvas = app.otherElements["boardCanvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 5))
        app.buttons["colorSwatch_2"].tap()
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.4, dy: 0.4)).tap()

        let ironButton = app.buttons["ironButton"]
        XCTAssertTrue(ironButton.isEnabled)

        app.buttons["undoButton"].tap()
        XCTAssertFalse(ironButton.isEnabled, "undo should restore an empty board")
    }

    private func attachScreenshot(named name: String, of app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

private extension XCUIElement {
    func clearAndTypeText(_ text: String) {
        guard let stringValue = value as? String, !stringValue.isEmpty else {
            typeText(text)
            return
        }
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        typeText(deleteString)
        typeText(text)
    }
}
