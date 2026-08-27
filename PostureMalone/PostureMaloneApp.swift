import SwiftUI

@main
struct PostureMaloneApp: App {
    @StateObject private var motion = MotionManager()

    var body: some Scene {
        MenuBarExtra {
            PostureView(motion: motion, posture: motion.posture)
        } label: {
            if motion.posture.isPaused {
                Image(systemName: "pause.circle")
            } else if motion.posture.isSlouching {
                Label("\(Int(motion.posture.tiltDegrees.rounded()))°",
                      systemImage: "brain.head.profile")
            } else {
                Image(systemName: "brain.head.profile")
            }
        }
        .menuBarExtraStyle(.window)
    }
}
