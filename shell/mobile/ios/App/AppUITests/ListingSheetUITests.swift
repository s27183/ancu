import XCTest

// Honest-partial -> the suburb data the goal names -> the phone app -> the listing site over the app
// Goal:      behavior 161 Expect 3 on iPhone — a real tap on a suburb's listing link shows the
//            site in the Safari sheet with Done, and Done lands back on the same suburb sheet.
// Invariant: the listing page runs in SFSafariViewController (Safari's process), never in our
//            web view; closing it returns to the app as it was.
// Capability: XCUITest taps the web view's elements by their accessibility labels and sees the
//            Safari sheet's Done button (Close on iOS 27, overlapped by the Address button) in the
//            app's own hierarchy (XCTest, Xcode's simulator SDK).
final class ListingSheetUITests: XCTestCase {
    func dump(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
        let file = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("161-\(name).png")
        try? app.screenshot().pngRepresentation.write(to: file)
        print("161 shot: \(file.path)")
        if name.hasPrefix("missing") { print("=== \(name) ===\n\(app.debugDescription)") }
    }

    /// Wait for the first element matching the predicate, failing with the tree if it never shows.
    func find(_ app: XCUIApplication, _ q: XCUIElementQuery, _ pred: String, _ what: String, timeout: Double = 15) -> XCUIElement {
        let e = q.matching(NSPredicate(format: pred)).firstMatch
        if !e.waitForExistence(timeout: timeout) {
            dump(app, "missing \(what)")
            XCTFail("never saw \(what)")
        }
        return e
    }

    /// After launch: close the welcome sheet if this is a first run (it shows once), then wait for home.
    func home(_ app: XCUIApplication) {
        _ = app.links.firstMatch.waitForExistence(timeout: 30)
        sleep(2)
        if let small = app.buttons.matching(NSPredicate(format: "label == 'Thu gọn giới thiệu'")).allElementsBoundByIndex.first(where: { $0.frame.width < 100 }) {
            small.tap()
        }
    }

    func testListingOpensInSafariSheetAndDoneReturns() throws {
        let app = XCUIApplication()
        app.launch()
        home(app)
        find(app, app.links, "label BEGINSWITH 'Khám phá khu vực'", "the explore way in").tap()
        let field = app.textFields.firstMatch
        if !field.waitForExistence(timeout: 8) {
            find(app, app.buttons, "label CONTAINS 'Tìm & lọc'", "Tìm & lọc").tap()
        }
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("Box Hill")
        find(app, app.buttons, "label CONTAINS 'Box Hill (Vic.)'", "the Box Hill (Vic.) result").tap()
        find(app, app.buttons, "label BEGINSWITH 'Nhà đang bán ở Box Hill'", "the listing button").tap()
        let tip = app.buttons["Xong"]
        if tip.waitForExistence(timeout: 3) { tip.tap() }
        let rea = find(app, app.links, "label CONTAINS 'realestate.com.au'", "the realestate.com.au link")
        dump(app, "1 listing sheet")
        rea.tap()
        // SFSafariViewController's dismiss button: «Done» before iOS 26, «Close» (identifier Close) on iOS 27
        let done = app.buttons.matching(NSPredicate(format: "identifier IN {'Done', 'Close'}")).firstMatch
        XCTAssertTrue(done.waitForExistence(timeout: 20), "no Safari sheet Done/Close button")
        XCTAssertTrue(app.buttons["OpenInSafariButton"].exists, "not the Safari sheet (no Open in Safari)")
        print("161 safari sheet: dismiss «\(done.label)», address «\(app.buttons["URL"].value ?? "")»")
        sleep(5)
        dump(app, "2 safari sheet")
        if !closeSheet(app, done, "listing") { dump(app, "missing: the Safari sheet is still up after Close"); XCTFail("the Safari sheet is still up") }
        XCTAssertTrue(app.links.matching(NSPredicate(format: "label CONTAINS 'realestate.com.au'")).firstMatch.waitForExistence(timeout: 10),
                      "the listing sheet is gone after Done")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Box Hill'")).firstMatch.exists, "not the Box Hill sheet")
        print("161 back: listing sheet for Box Hill with its realestate.com.au link")
        dump(app, "3 back on the listing sheet")
        print("161 sheet links: " + app.links.allElementsBoundByIndex.map { $0.label }.joined(separator: " | "))
        // the listing guide's outside link (ABS dwelling structure), from the same sheet
        let guide = find(app, app.links, "label BEGINSWITH 'ABS'", "the listing guide's ABS link")
        outside(app, guide, "listing guide", stay: rea)
    }

    /// iOS 27's top bar: the Address button's frame (x 26–376) covers Close's centre (x 16–60), so
    /// XCUITest's element tap picks a "hittable" point at Close's corner (20.4, 69.4 measured), where
    /// nothing reacts. A person taps the drawn X at the centre: tap that coordinate.
    func closeSheet(_ app: XCUIApplication, _ close: XCUIElement, _ name: String) -> Bool {
        close.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        if gone(app.buttons["OpenInSafariButton"], 8) { print("161 \(name): closed by tapping the X at Close's centre"); return true }
        return false
    }

    func gone(_ e: XCUIElement, _ timeout: Double = 10) -> Bool {
        let x = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: e)
        return XCTWaiter.wait(for: [x], timeout: timeout) == .completed
    }

    /// Tap an outside link: the Safari sheet shows it; Close lands back with `stay` still on screen.
    func outside(_ app: XCUIApplication, _ link: XCUIElement, _ name: String, stay: XCUIElement) {
        link.tap()
        let close = app.buttons.matching(NSPredicate(format: "identifier IN {'Done', 'Close'}")).firstMatch
        XCTAssertTrue(close.waitForExistence(timeout: 20), "\(name): no Safari sheet")
        XCTAssertTrue(app.buttons["OpenInSafariButton"].exists, "\(name): not the Safari sheet")
        sleep(3)
        print("161 \(name): Safari sheet at «\(app.buttons["URL"].value ?? "")»")
        dump(app, "\(name) in Safari sheet")
        XCTAssertTrue(closeSheet(app, close, name), "\(name): Safari sheet still up")
        XCTAssertTrue(stay.waitForExistence(timeout: 5), "\(name): not back where it was")
        print("161 \(name): back, «\(stay.label)» on screen")
    }

    func way(_ app: XCUIApplication, _ title: String) {
        app.launch()
        home(app)
        find(app, app.links, "label BEGINSWITH '\(title)'", title).tap()
        sleep(3)
    }

    func testOutsideLinksOpenInSafariSheet() throws {
        let app = XCUIApplication()
        // a fact card's source link (Federal Register of Legislation)
        way(app, "Nước Úc qua số liệu")
        let fact = find(app, app.links, "label == 'Công báo Luật liên bang Úc'", "a fact source")
        outside(app, fact, "fact source", stay: fact)
        // a market page's outside link (ABS)
        way(app, "Thị trường nhà ở Úc")
        let abs = find(app, app.links, "label == 'Cục Thống kê Úc (ABS)'", "a market source")
        outside(app, abs, "market source", stay: abs)
        // a news note stays in the app; its source opens in the Safari sheet
        way(app, "Tin tức")
        let note = find(app, app.buttons, "label CONTAINS 'RBA tăng lãi suất'", "the RBA news note")
        note.tap()
        sleep(2)
        XCTAssertFalse(app.buttons["OpenInSafariButton"].exists, "a news note left the app")
        dump(app, "news note")
        print("161 news note: in app; links now: " + app.links.allElementsBoundByIndex.map { $0.label }.joined(separator: " | "))
    }

    func testListLinks() throws {
        let app = XCUIApplication()
        for way in ["Nước Úc qua số liệu", "Thị trường nhà ở Úc", "Tin tức", "Lập kế hoạch ngân sách"] {
            app.launch()
            home(app)
            find(app, app.links, "label BEGINSWITH %@".replacingOccurrences(of: "%@", with: "'\(way)'"), way).tap()
            sleep(4)
            print("161 \(way) links: " + app.links.allElementsBoundByIndex.map { $0.label }.joined(separator: " | "))
            print("161 \(way) buttons: " + app.buttons.allElementsBoundByIndex.prefix(60).map { $0.label }.joined(separator: " | "))
        }
    }
}
