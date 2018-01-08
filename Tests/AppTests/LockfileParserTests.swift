import XCTest
@testable import App

final class LockfileParserTests: XCTestCase {
    func testParsingEmptyStringReturnsAppWithNoDependencies() {
        let output = try! LockfileParser.parse(lockfile: "")
        guard let nodes = output["nodes"] as? [[String: [String: String]]],
            let edges = output["edges"] as? [Any] else {
                XCTFail("Failed to cast dictionaries as expected")
                return
        }

        XCTAssertEqual(nodes[0]["data"]?["id"], "App")
        XCTAssert(edges.isEmpty)
    }

    func testParsingFlatDependencies() {
        let input =
        """
        PODS:
          - SteamedHams
          - CarHole
        DEPENDENCIES:
            blah blah blah
        """

        let output = try! LockfileParser.parse(lockfile: input)
        guard let nodes = output["nodes"] as? [[String: [String: String]]],
            let edges = output["edges"] as? [[String: [String: String]]] else {
                XCTFail("Failed to cast dictionaries as expected")
                return
        }

        XCTAssert(nodes.contains{ $0["data"]?["id"] == "SteamedHams" })
        XCTAssert(nodes.contains{ $0["data"]?["id"] == "CarHole" })
    }

    func testParsingWhenDependenciesSectionIsOmitted() {
        let input =
        """
        PODS:
          - SteamedHams
          - CarHole
        """

        let output = try! LockfileParser.parse(lockfile: input)
        guard let nodes = output["nodes"] as? [[String: [String: String]]],
            let edges = output["edges"] as? [[String: [String: String]]] else {
                XCTFail("Failed to cast dictionaries as expected")
                return
        }

        XCTAssert(nodes.contains{ $0["data"]?["id"] == "SteamedHams" })
        XCTAssert(nodes.contains{ $0["data"]?["id"] == "CarHole" })
    }

    func testParsingRelatedDependencies() {
        let input =
        """
        PODS:
          - LisaNeedsBraces
          - DentalPlan
            - LisaNeedsBraces
        DEPENDENCIES:
            blah blah blah
        """

        let output = try! LockfileParser.parse(lockfile: input)
        guard let nodes = output["nodes"] as? [[String: [String: String]]],
            let edges = output["edges"] as? [[String: [String: String]]] else {
                XCTFail()
                return
        }

        XCTAssert(nodes.contains{ $0["data"]?["id"] == "LisaNeedsBraces" })
        XCTAssert(nodes.contains{ $0["data"]?["id"] == "DentalPlan" })
        XCTAssert(edges.contains{ $0["data"]?["source"] == "DentalPlan" })
        XCTAssert(edges.contains{ $0["data"]?["target"] == "LisaNeedsBraces" })
    }

    func testMalformedPodfilesThrowAnError() {
        // Podfile.lock should contain "- FlamingHomer" at root level
        let input =
        """
        PODS:
          - FlamingMoe
            - FlamingHomer
        """

        do {
            let output = try LockfileParser.parse(lockfile: input)
        } catch {
            return
        }

        XCTFail("Invalid input did not throw an error")
    }
}
