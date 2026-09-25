import AppKit
import SwiftUI
import HaltungCore

/// Randloses Panel, das trotz Borderless-Style Key-Window werden darf, damit
/// die enthaltenen SwiftUI-Buttons aktiv und klickbar sind.
final class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// Verwaltet das schwebende Liquid-Glass-Overlay-Panel, das bei wichtigen
/// Erinnerungen erscheint und aktiv bestätigt werden muss.
@MainActor
final class OverlayController: NSObject, NSWindowDelegate {
    private var panel: NSPanel?
    /// Oberkante und horizontaler Mittelpunkt des Panels beim Einblenden. Waechst
    /// der Inhalt (Video), bleibt die Oberkante fix und das Panel waechst nach
    /// unten (statt ueber den Rand) und bleibt horizontal zentriert.
    private var anchorTopY: CGFloat?
    private var anchorCenterX: CGFloat?

    func show(
        config: ReminderConfig,
        phase: Phase,
        onComplete: @escaping () -> Void,
        onSnooze: @escaping () -> Void,
        onIgnore: @escaping () -> Void
    ) {
        dismiss()

        let view = OverlayView(
            config: config,
            phase: phase,
            onComplete: { [weak self] in
                self?.dismiss()
                onComplete()
            },
            onSnooze: { [weak self] in
                self?.dismiss()
                onSnooze()
            },
            onIgnore: { [weak self] in
                self?.dismiss()
                onIgnore()
            }
        )

        let hosting = NSHostingView(rootView: view)
        // Panel waechst/schrumpft mit dem SwiftUI-Inhalt (z.B. eingeblendetes Video).
        hosting.sizingOptions = [.minSize, .intrinsicContentSize, .maxSize]
        // HUD-Panel im Stil der track-Pausenerinnerung: dunkel, schwebend.
        let panel = KeyablePanel(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 320),
            styleMask: [.titled, .nonactivatingPanel, .hudWindow],
            backing: .buffered,
            defer: false
        )
        panel.title = "Haltung"
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.contentView = hosting
        panel.setContentSize(hosting.fittingSize)
        positionInUpperThird(panel)
        anchorTopY = panel.frame.maxY
        anchorCenterX = panel.frame.midX
        panel.delegate = self
        NSApp.activate(ignoringOtherApps: true)
        // makeKey statt nur orderFront: erst dann sind die Buttons aktiv.
        panel.makeKeyAndOrderFront(nil)
        self.panel = panel
    }

    /// Haelt beim Mitwachsen des Inhalts die Oberkante fest und zentriert das
    /// Panel horizontal neu.
    func windowDidResize(_ notification: Notification) {
        guard let panel, let anchorTopY, let anchorCenterX else { return }
        let size = panel.frame.size
        panel.setFrameOrigin(NSPoint(x: anchorCenterX - size.width / 2, y: anchorTopY - size.height))
    }

    /// Verschiebt der Nutzer das Panel, wandert der Anker mit — sonst wuerde das
    /// naechste Mitwachsen es an die alte Stelle zuruecksetzen.
    func windowDidMove(_ notification: Notification) {
        guard let panel else { return }
        anchorTopY = panel.frame.maxY
        anchorCenterX = panel.frame.midX
    }

    /// Zentriert horizontal und setzt das Panel ins obere Bildschirmdrittel,
    /// damit die Erinnerung gut sichtbar ist.
    private func positionInUpperThird(_ panel: NSPanel) {
        guard let screen = NSScreen.main else {
            panel.center()
            return
        }
        let frame = screen.visibleFrame
        let size = panel.frame.size
        let x = frame.midX - size.width / 2
        let y = frame.maxY - size.height - 120
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    func dismiss() {
        panel?.orderOut(nil)
        panel = nil
    }

    var isShowing: Bool { panel != nil }
}
