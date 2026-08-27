import AppKit
import SwiftUI

@main
struct DesktopWidgetsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { incomingURL in
                    guard let externalURL = DesktopWidgetsURLRouter.externalURL(for: incomingURL) else {
                        return
                    }
                    NSWorkspace.shared.open(externalURL)
                }
        }
        .defaultSize(width: 980, height: 720)
    }
}
