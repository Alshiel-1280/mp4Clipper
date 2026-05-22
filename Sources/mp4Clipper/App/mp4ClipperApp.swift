import SwiftUI

@main
struct mp4ClipperApp: App {
    @StateObject private var settings = SettingsViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .frame(minWidth: 1180, minHeight: 760)
        }
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }

        Settings {
            SettingsView()
                .environmentObject(settings)
        }
    }
}
