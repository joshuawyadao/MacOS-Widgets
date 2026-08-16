import Foundation

enum DesktopWidgetsURLRouter {
    static func externalURL(for incomingURL: URL) -> URL? {
        guard let scheme = incomingURL.scheme?.lowercased(),
              scheme == "https" || scheme == "http",
              incomingURL.host?.lowercased() == "open-meteo.com" else {
            return nil
        }
        return incomingURL
    }
}
