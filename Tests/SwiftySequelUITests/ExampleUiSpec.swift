import Nimble
import Quick
import XCTest

internal class ExampleUiSpec: QuickSpec {
    override internal func spec() {
        print(
            "Printing something to work around a linking error. See "
                + "https://stackoverflow.com/q/40986082/981846 for more info."
        )

        XCUIDevice.shared.orientation = (UIDevice.current.userInterfaceIdiom == .pad) ? .landscapeLeft : .portrait
        XCUIApplication().launch()

        describe("The UI tests for the POS application") {
            it("work") {
                expect(true) == true
            }
        }
    }
}
