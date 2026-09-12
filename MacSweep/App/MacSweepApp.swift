import AppKit
import SwiftUI

@main
struct MacSweepApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 1050, height: 680)
        .commands {
            MacSweepCommands()
        }

        Window("About MacSweep", id: AboutView.windowID) {
            AboutView()
        }
        .windowResizability(.contentSize)
    }
}

/// Application menu bar: custom About and a Help menu with GrayHawk Sentinel
/// links and the public repository.
struct MacSweepCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button("About \(AppInfo.name)") {
                openWindow(id: AboutView.windowID)
            }
        }

        CommandGroup(replacing: .help) {
            Button("\(AppInfo.name) Help") {
                NSWorkspace.shared.open(AppInfo.helpURL)
            }
            Divider()
            Button("Visit \(AppInfo.developer) Website") {
                NSWorkspace.shared.open(AppInfo.websiteURL)
            }
            Button("Contact Support") {
                NSWorkspace.shared.open(AppInfo.emailURL)
            }
            Divider()
            Button("GitHub Repository") {
                NSWorkspace.shared.open(AppInfo.githubURL)
            }
            Button("Report an Issue") {
                NSWorkspace.shared.open(AppInfo.issuesURL)
            }
            Button("License") {
                NSWorkspace.shared.open(AppInfo.licenseURL)
            }
        }
    }
}
