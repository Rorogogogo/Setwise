/*
README
- How to run: Open the folder in Xcode 14+ (macOS 13+ SDK), set the app target's bundle ID, then Build & Run.
- Permissions: None required. The app uses /usr/bin/defaults and /usr/bin/killall for SystemUIServer.
- Assumptions: macOS 13+ with SwiftUI NavigationSplitView available.
*/

import SwiftUI

@main
struct SetwiseApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
    }
}
