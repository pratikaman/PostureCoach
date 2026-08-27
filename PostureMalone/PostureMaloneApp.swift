import SwiftUI

@main
struct PostureMaloneApp: App {
    @StateObject private var motion = MotionManager()

    var body: some Scene {
        MenuBarExtra {
            PostureView(motion: motion, posture: motion.posture)
        } label: {
            MenuBarLabel(motion: motion, posture: motion.posture)
        }
        .menuBarExtraStyle(.window)
    }
}

/// Menu bar label: live tilt next to the icon; no number = no data coming in.
/// Uses explicit Image + Text — a SwiftUI `Label` renders icon-only in the
/// menu bar, silently dropping the text.
private struct MenuBarLabel: View {
    @ObservedObject var motion: MotionManager
    @ObservedObject var posture: PostureMonitor

    var body: some View {
        let deg = "\(Int(posture.tiltDegrees.rounded()))°"
        let streaming = motion.status == .streaming
        if posture.isPaused {
            if streaming {
                Image(systemName: "pause.circle")
                Text(deg)
            } else {
                Image(systemName: "pause.circle")
            }
        } else if streaming {
            Image(systemName: "brain.head.profile")
            Text(posture.isSlouching ? deg + "↓" : deg)
        } else {
            Image(systemName: "brain.head.profile")
        }
    }
}
