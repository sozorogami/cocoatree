import Foundation
import Vapor

private enum LineType: String {
    case library = "  -"
    case dependency = "    -"
    case unknown = ""
}

private extension String {
    var lineType: LineType {
        if self.hasPrefix(LineType.dependency.rawValue) {
            return .dependency
        }
        if self.hasPrefix(LineType.library.rawValue) {
            return .library
        }
        return .unknown
    }
}

final class LockfileParser {

    /// Represents an error parsing a Podfile.lock
    struct ParseError: Error { }

    /// Converts the raw contents of a Podfile.lock into a format that can be rendered on the front-end
    ///
    /// - Parameter lockfile: The full copy/pasted contents of a Podfile.lock file
    /// - Returns: A dictionary of nodes and edges that can be rendered as a directed graph by dagrejs
    /// - Throws: A `ParseError` if the input is invalid
    static func parse(lockfile: String) throws -> [String: Any] {
        // Be agnostic about line break style
        let lineBreak = lockfile.contains(Character("\r")) ? "\r\n" : "\n"

        let pods = getPodsSection(lockfile: lockfile)
        let lines = pods.components(separatedBy: lineBreak)
        let hierarchy = try flattenedDependencyHierarchy(fromPodList: lines)

        guard hierarchy.keys.count > 0 else { throw ParseError() }

        return try formatHierarchyForDisplay(hierarchy: hierarchy)
    }

    /// Dagrejs renders a graph when provided with a dictionary of nodes and edges. This converts a flattened dependency
    /// hierarchy into that parsable format.
    ///
    /// - Parameter hierarchy: A dictionary in the form [libraryName: [dependencies]] representing a flattened dependency tree
    /// - Returns: A dictionary of nodes and edges for display by dagrejs
    /// - Throws: A `ParseError` if the input is invalid
    private static func formatHierarchyForDisplay(hierarchy: [String: [String]]) throws -> [String: Any] {
        // We start with one root node representing the App, linked to the root libraries, which are not
        // dependencies of any other library
        let appName = "App"
        var nodes: [[String: Any]] = [nodeDict(name: appName)]
        var edges: [[String: Any]] = rootLibraries(hierarchy: hierarchy).map{ edgeDict(source: appName, target: $0) }

        for library in hierarchy.keys {
            let node = nodeDict(name: library)
            nodes.append(node)

            guard let dependencies = hierarchy[library] else { throw self.ParseError() }

            for dependency in dependencies {
                edges.append(edgeDict(source: library, target: dependency))
            }
        }

        return ["nodes": nodes, "edges": edges]
    }

    /// Returns all libraries that are not dependencies of other libraries in the hierarchy
    ///
    /// - Parameter hierarchy: A dictionary in the form [libraryName: [dependencies]] representing a flattened dependency tree
    /// - Returns: An array of the names of all root libraries in the hierarchy
    private static func rootLibraries(hierarchy: [String: [String]]) -> [String] {
        let allLibraries = Set(hierarchy.keys)
        let deps = Set(hierarchy.flatMap { $1 })
        return Array(allLibraries.subtracting(deps))
    }

    /// A Podfile.lock represents the dependency graph as a flattened tree. This parses raw lines from a file into a native
    /// Swift dictionary with the same structure.
    ///
    /// - Parameter podList: An array of raw lines from a Podfile.lock's "PODS:" section
    /// - Returns: A dictionary in the form [libraryName: [dependencies]] representing a flattened dependency tree
    /// - Throws: A `ParseError` if the input is invalid
    private static func flattenedDependencyHierarchy(fromPodList podList: [String]) throws -> [String: [String]] {
        var librariesToDependencies = [String: [String]]()

        var currentLibraryName: String?
        var currentDependencyNames = [String]()
        func finalizeCurrentLibrary() {
            if let name = currentLibraryName {
                librariesToDependencies[name] = currentDependencyNames
            }
        }

        podList.forEach { line in
            guard let name = nameFromLine(line: line) else { return }
            switch line.lineType {
            case .library:
                finalizeCurrentLibrary()
                currentLibraryName = name
                currentDependencyNames = []
            case .dependency:
                currentDependencyNames.append(name)
            case .unknown:
                return
            }
        }
        finalizeCurrentLibrary()

        // Check hierarchy for consistency. Each dependency should also exist at root level.
        for dependency in librariesToDependencies.flatMap({ $1 }) {
            if !librariesToDependencies.keys.contains(dependency) {
                throw ParseError()
            }
        }

        return librariesToDependencies
    }

    private static func getPodsSection(lockfile: String) -> String {
        return lockfile.components(separatedBy: "DEPENDENCIES:")[0]
    }

    private static func nameFromLine(line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        let components = trimmed.components(separatedBy: " ")
        guard components.count > 1 else {
            return nil
        }
        return components[1]
    }

    private static func nodeDict(name: String) -> [String: [String: String]] {
        return ["data": ["id": name]]
    }

    private static func edgeDict(source: String, target: String) -> [String: [String: String]] {
        return ["data": ["source": source, "target": target]]
    }
}
