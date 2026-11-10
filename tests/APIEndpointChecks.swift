import Foundation

@main struct EndpointChecks {
    static func main() {
        let live = "https://192.168.1.20:3443/v1"
        let resolve = APIEndpointConfiguration.resolve
        precondition(resolve([:], live, false)?.absoluteString == live)
        precondition(resolve([:], live, true)?.absoluteString == live)
        precondition(resolve(["GODIEOR_API_BASE_URL":"https://override.example/v1"], live, false)?.host == "override.example")
        for invalid in ["", " ", "https://YOUR_BACKEND_HOST/v1", "$(GODIEOR_API_BASE_URL)",
                        "http://192.168.1.20:3443/v1", "https://host.test/v1?key=example", "https://host.test/v1#fragment", "https:///missing"] {
            precondition(resolve(["GODIEOR_API_BASE_URL":invalid], live, false) == nil)
            precondition(resolve(["GODIEOR_API_BASE_URL":invalid], live, true) == nil)
        }
        for valid in ["HTTPS://host.test/v1", "Https://host.test/v1"] {
            precondition(resolve(["GODIEOR_API_BASE_URL":valid],nil,false) != nil)
        }
        precondition(resolve(["GODIEOR_API_BASE_URL":"http://LOCALHOST:3000/v1"],nil,true) != nil)
        var userInfo = URLComponents(string: "https://host.test/v1")!
        userInfo.user = "user"; userInfo.password = "password" // Synthetic rejection input.
        precondition(resolve(["GODIEOR_API_BASE_URL":userInfo.string!],live,false) == nil)
        if CommandLine.arguments.count == 2 {
            let data = try! Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
            let info = try! PropertyListSerialization.propertyList(from: data, format: nil) as! [String: Any]
            let bundled = info["GODIEORAPIBaseURL"] as! String
            precondition(bundled == "https://endpoint-check.invalid/v1")
            precondition(resolve([:],bundled,false) == resolve([:],bundled,true))
            precondition(resolve([:],bundled,false)?.host == "endpoint-check.invalid")
        }
        precondition(resolve([:],nil,false) == nil)
        precondition(resolve([:],"https://YOUR_BACKEND_HOST/v1",false) == nil)
        precondition(resolve([:],nil,true)?.absoluteString == "http://localhost:3000/v1")
        precondition(resolve([:],"https://YOUR_BACKEND_HOST/v1",true)?.host == "localhost")
        precondition(resolve(["GODIEOR_API_BASE_URL":"http://127.0.0.1:3000/v1"],live,true)?.host == "127.0.0.1")
        precondition(resolve(["GODIEOR_API_BASE_URL":"http://127.0.0.1:3000/v1"],live,false) == nil)
        print("PASS endpoint configuration: shared HTTPS, precedence, malformed input, device/Simulator boundaries")
    }
}
