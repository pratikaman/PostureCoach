import SwiftUI

@main
struct PostureMaloneApp: App {
    @StateObject private var motion = MotionManager()

    var body: some Scene {
        MenuBarExtra {
            PostureView(motion: motion, posture: motion.posture)
        } label: {
            // Live tilt in the menu bar; no number = no data coming in.
            let deg = "\(Int(motion.posture.tiltDegrees.rounded()))°"
            let streaming = motion.status == .streaming
            if motion.posture.isPaused {
                if streaming {
                    Label(deg, systemImage: "pause.circle")
                } else {
                    Image(systemName: "pause.circle")
                }
            } else if streaming {
                Label(motion.posture.isSlouching ? deg + "↓" : deg,
                      systemImage: "brain.head.profile")
            } else {
                Image(systemName: "brain.head.profile")
            }
        }
        .menuBarExtraStyle(.window)
    }
}
