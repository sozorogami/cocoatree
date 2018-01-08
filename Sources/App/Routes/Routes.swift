import Vapor
import LeafProvider
import Foundation

extension Droplet {
    func setupRoutes() throws {
        get("") { req in
            return try self.view.make("form.html")
        }

        post("") { req in
            guard let body = req.data["data"]?.string else { return try self.view.make("error.html") }
            guard let leaf = self.view as? LeafRenderer else { return try self.view.make("error.html") }

            do {
                let nodesAndEdges = try LockfileParser.parse(lockfile: body)
                let JSONData = try JSONSerialization.data(withJSONObject: nodesAndEdges, options: .prettyPrinted)
                let JSONString = String(data: JSONData, encoding: String.Encoding.utf8)

                return try leaf.make("graph", ["elementsIn": JSONString])
            }
            catch {
                return try self.view.make("error.html")
            }
        }
    }
}
