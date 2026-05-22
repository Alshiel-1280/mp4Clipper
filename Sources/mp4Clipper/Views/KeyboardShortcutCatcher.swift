import SwiftUI

struct KeyboardShortcutCatcher: NSViewRepresentable {
    var onKeyDown: (NSEvent) -> Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(onKeyDown: onKeyDown)
    }

    func makeNSView(context: Context) -> KeyView {
        let view = KeyView()
        context.coordinator.install()
        return view
    }

    func updateNSView(_ nsView: KeyView, context: Context) {
        context.coordinator.onKeyDown = onKeyDown
    }

    static func dismantleNSView(_ nsView: KeyView, coordinator: Coordinator) {
        coordinator.uninstall()
    }

    final class Coordinator {
        var onKeyDown: (NSEvent) -> Bool
        private var monitor: Any?

        init(onKeyDown: @escaping (NSEvent) -> Bool) {
            self.onKeyDown = onKeyDown
        }

        func install() {
            guard monitor == nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self else { return event }
                return self.onKeyDown(event) ? nil : event
            }
        }

        func uninstall() {
            if let monitor {
                NSEvent.removeMonitor(monitor)
            }
            monitor = nil
        }
    }

    final class KeyView: NSView {
        override var acceptsFirstResponder: Bool { false }
    }
}
