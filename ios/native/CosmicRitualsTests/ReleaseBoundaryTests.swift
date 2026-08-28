import XCTest
@testable import CosmicRituals

/// Pins the separation between the internal testing build and a public candidate.
///
/// These read the project files as text on purpose. The invariants they protect live in
/// `project.pbxproj` and the shared schemes, not in Swift, and nothing else in the suite would
/// notice if someone added `TESTFLIGHT_BETA_ACCESS` to a second configuration or pointed the
/// standard scheme's archive action somewhere new.
///
/// `XMLDocument` is deliberately not used: it is macOS-only and will not link into a simulator
/// test bundle. Assertions are on content, never on line numbers, so ordinary edits above them
/// do not cause false failures.
final class ReleaseBoundaryTests: XCTestCase {

    // MARK: - Repository access

    private static var repositoryRoot: URL {
        URL(fileURLWithPath: #filePath)       // .../CosmicRitualsTests/ReleaseBoundaryTests.swift
            .deletingLastPathComponent()      // .../CosmicRitualsTests
            .deletingLastPathComponent()      // .../ios/native
    }

    private func text(at relativePath: String) throws -> String {
        let url = Self.repositoryRoot.appendingPathComponent(relativePath)
        guard FileManager.default.fileExists(atPath: url.path) else {
            XCTFail("Missing \(relativePath) — the release boundary cannot be verified")
            throw XCTSkip("missing file")
        }
        return try String(contentsOf: url, encoding: .utf8)
    }

    private var projectFile: String {
        get throws { try text(at: "CosmicRituals.xcodeproj/project.pbxproj") }
    }

    // MARK: - The compilation condition

    /// The whole boundary rests on this flag being *active* in exactly one configuration.
    ///
    /// Counting every mention of the name would be wrong: the release-boundary guard build
    /// phase has to name the flag in order to scan for it. What matters is how many build
    /// configurations switch it on.
    func testTestingAccessConditionIsActiveInOnlyTheTestFlightConfiguration() throws {
        let project = try projectFile

        let activations = project
            .components(separatedBy: "SWIFT_ACTIVE_COMPILATION_CONDITIONS = \"TESTFLIGHT_BETA_ACCESS")
            .count - 1
        XCTAssertEqual(
            activations, 1,
            "Exactly one build configuration may switch on TESTFLIGHT_BETA_ACCESS; found \(activations)"
        )

        XCTAssertFalse(
            project.contains("OTHER_SWIFT_FLAGS") && project.contains("-DTESTFLIGHT_BETA_ACCESS"),
            "The flag must not be smuggled in through OTHER_SWIFT_FLAGS"
        )

        // The configuration block that switches it on must be the TestFlight one.
        guard let activation = project.range(
            of: "SWIFT_ACTIVE_COMPILATION_CONDITIONS = \"TESTFLIGHT_BETA_ACCESS"
        ) else {
            return XCTFail("no configuration activates the flag")
        }
        let after = project[activation.upperBound...]
        guard let nameRange = after.range(of: "name = ") else {
            return XCTFail("no configuration name follows the activation")
        }
        let configurationName = after[nameRange.upperBound...].prefix(while: { $0 != ";" })
        XCTAssertEqual(
            String(configurationName), "TestFlight",
            "Testing access must belong to the TestFlight configuration, not \(configurationName)"
        )
    }

    func testEveryTargetDeclaresAllThreeConfigurationsAndDefaultsToRelease() throws {
        let project = try projectFile
        let lists = project.components(separatedBy: "isa = XCConfigurationList;").dropFirst()

        XCTAssertGreaterThanOrEqual(
            lists.count, 3,
            "Expected a configuration list per target plus the project; an empty parse must not pass vacuously"
        )

        for list in lists {
            let block = String(list.prefix(while: { $0 != "}" }))
            for configuration in ["Debug", "Release", "TestFlight"] {
                XCTAssertTrue(
                    block.contains("/* \(configuration) */"),
                    "Every configuration list must declare \(configuration)"
                )
            }
            XCTAssertTrue(
                block.contains("defaultConfigurationName = Release"),
                "A list that defaults to anything but Release can ship a non-Release build by accident"
            )
        }
    }

    // MARK: - Schemes

    func testStandardSchemeArchivesReleaseAndTestFlightSchemeArchivesTestFlight() throws {
        let cases = [
            ("CosmicRituals.xcscheme", "Release"),
            ("CosmicRitualsTestFlight.xcscheme", "TestFlight"),
        ]

        for (scheme, expected) in cases {
            let xml = try text(at: "CosmicRituals.xcodeproj/xcshareddata/xcschemes/\(scheme)")
            let archiveActions = xml.components(separatedBy: "<ArchiveAction").count - 1
            XCTAssertEqual(archiveActions, 1, "\(scheme) must declare exactly one ArchiveAction")

            guard let actionRange = xml.range(of: "<ArchiveAction") else {
                return XCTFail("\(scheme) has no ArchiveAction")
            }
            let action = xml[actionRange.upperBound...].prefix(while: { $0 != ">" })
            XCTAssertTrue(
                action.contains("buildConfiguration = \"\(expected)\""),
                "\(scheme) must archive \(expected); archive action was \(action)"
            )
        }
    }

    // MARK: - The fence in Swift

    /// A build that is not the internal testing configuration must carry the public marker and
    /// not the testing one. Asserting both directions is what makes the marker meaningful:
    /// checking only for absence would pass on a binary nothing could read.
    func testThisBuildCarriesExactlyOneChannelMarker() {
        XCTAssertEqual(ReleaseChannel.marker, "COSMIC_RITUALS_PUBLIC_BUILD")
        XCTAssertNotEqual(
            ReleaseChannel.marker, "COSMIC_RITUALS_TESTING_ACCESS_BUILD",
            "The two markers must never collapse into one value"
        )
    }

    /// The testing channel must not grant anything. It once bypassed a
    /// paywall; the app is free now, so the marker may describe the build but
    /// must never widen access — there is no access to widen.
    func testTheTestingChannelGrantsNothing() throws {
        let channel = try text(at: "CosmicRituals/App/ReleaseChannel.swift")
        XCTAssertFalse(
            channel.contains("isTestingDistribution"),
            "The access bypass must stay deleted; the channel marker is provenance only"
        )
        XCTAssertTrue(channel.contains("#if TESTFLIGHT_BETA_ACCESS"), "the marker fence remains")

        let rootView = try text(at: "CosmicRituals/Views/RootView.swift")
        for banned in ["SubscriptionStore", "hasPremiumAccess", "SubscriptionGateView"] {
            XCTAssertFalse(rootView.contains(banned), "RootView must not gate on \(banned)")
        }
    }
    // MARK: - The guard and the inspector exist and are wired

    func testReleaseBoundaryGuardRunsBeforeSourcesInTheAppTarget() throws {
        let project = try projectFile
        XCTAssertTrue(
            project.contains("Release boundary guard"),
            "The app target must carry the release boundary guard build phase"
        )

        guard let phasesRange = project.range(of: "buildPhases = (\n\t\t\t\tC05B000000000000000003D0") else {
            return XCTFail("The guard must be the first build phase, before Sources compiles anything")
        }
        XCTAssertNotNil(phasesRange)
    }

    func testReleaseBoundaryInspectorIsPresentAndExecutable() throws {
        let url = Self.repositoryRoot.appendingPathComponent("scripts/inspect_release_boundary.sh")
        XCTAssertTrue(
            FileManager.default.isExecutableFile(atPath: url.path),
            "scripts/inspect_release_boundary.sh must exist and be executable"
        )

        let script = try text(at: "scripts/inspect_release_boundary.sh")
        // Both directions must be checked, or the inspector can pass on an unreadable binary.
        XCTAssertTrue(script.contains("COSMIC_RITUALS_TESTING_ACCESS_BUILD"))
        XCTAssertTrue(script.contains("COSMIC_RITUALS_PUBLIC_BUILD"))
        XCTAssertTrue(
            script.contains("nothing was inspected"),
            "A missing binary must fail loudly rather than read as a pass"
        )
    }
}
