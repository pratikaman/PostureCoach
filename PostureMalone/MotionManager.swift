import CoreMotion
import Combine
import Foundation

/// Minimal CMHeadphoneMotionManager wrapper: connection state, permission
/// diagnostics, and a gravity-derived down-tilt feed into PostureMonitor.
final class MotionManager: NSObject, ObservableObject, CMHeadphoneMotionManagerDelegate {

    enum Status: Equatable {
        case idle           // not started yet
        case unavailable    // no headphone motion support on this system
        case denied         // motion permission denied
        case waiting        // started, waiting for AirPods to stream
        case streaming      // receiving samples
    }

    @Published private(set) var status: Status = .idle
    @Published private(set) var authDescription: String = ""
    @Published private(set) var lastError: String?
    @Published private(set) var lastSample: Date?

    /// The whole point of the app.
    let posture = PostureMonitor()

    private let manager = CMHeadphoneMotionManager()
    private var started = false
    private var postureForward: AnyCancellable?

    override init() {
        super.init()
        manager.delegate = self
        // Re-publish nested changes so the menu bar label (which observes
        // MotionManager) updates when posture state changes.
        postureForward = posture.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
        // Menu-bar-only app: start as soon as we exist.
        start()
    }

    func start() {
        if started { return }
        started = true
        refreshAuth()
        guard manager.isDeviceMotionAvailable else {
            status = .unavailable
            return
        }
        if CMHeadphoneMotionManager.authorizationStatus() == .denied {
            status = .denied
            return
        }
        status = .waiting
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self else { return }
            self.refreshAuth()
            if let error = error as NSError? {
                self.lastError = "\(error.domain) \(error.code): \(error.localizedDescription)"
                // CMErrorMotionActivityNotAuthorized == 105
                if CMHeadphoneMotionManager.authorizationStatus() == .denied
                    || (error.domain == CMErrorDomain && error.code == 105) {
                    self.status = .denied
                }
                return
            }
            guard let motion else { return }
            self.lastError = nil
            self.handle(motion)
        }
    }

    // MARK: - CMHeadphoneMotionManagerDelegate

    func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        DispatchQueue.main.async {
            if self.status == .idle || self.status == .waiting { self.status = .waiting }
        }
    }

    func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        DispatchQueue.main.async {
            if self.status == .streaming { self.status = .waiting }
        }
    }

    // MARK: - Sample handling

    private func handle(_ motion: CMDeviceMotion) {
        status = .streaming
        let now = Date()
        lastSample = now

        // Gravity-referenced down-tilt: absolute, drift-free.
        // Head frame: +Z out of the face; looking down tips gravity toward +Z.
        let g = motion.gravity
        posture.update(
            rawDownDegrees: asin(max(-1.0, min(1.0, g.z))) * 180.0 / .pi,
            at: now
        )
    }

    private func refreshAuth() {
        switch CMHeadphoneMotionManager.authorizationStatus() {
        case .notDetermined: authDescription = "not determined (no prompt answered yet)"
        case .restricted: authDescription = "restricted"
        case .denied: authDescription = "denied"
        case .authorized: authDescription = "authorized"
        @unknown default: authDescription = "unknown"
        }
    }
}
