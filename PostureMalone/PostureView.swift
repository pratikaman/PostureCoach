import SwiftUI
import AppKit

// MARK: - Theme

private enum Theme {
    static let bg = Color(red: 0.055, green: 0.067, blue: 0.086)      // #0E1116
    static let card = Color(red: 0.090, green: 0.102, blue: 0.129)    // #171A21
    static let cardStroke = Color.white.opacity(0.06)
    static let neon = Color(red: 0.639, green: 0.878, blue: 0.259)    // #A3E042
    static let orange = Color(red: 0.960, green: 0.650, blue: 0.140)
    static let purple = Color(red: 0.600, green: 0.510, blue: 0.960)
    static let alert = Color(red: 0.950, green: 0.330, blue: 0.300)
    static let dim = Color.white.opacity(0.55)
    static let faint = Color.white.opacity(0.35)
}

private struct Card: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 14).fill(Theme.card))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.cardStroke))
    }
}

// MARK: - Popover

struct PostureView: View {
    @ObservedObject var motion: MotionManager
    @ObservedObject var posture: PostureMonitor
    @AppStorage("ui.showHistory") private var showHistory = false

    private var streaming: Bool { motion.status == .streaming }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            hero
            diagnostics
            statsCard
            calibrate
            settingsCard
            phraseCard
            if showHistory { historyCard }
            footer
        }
        .padding(16)
        .frame(width: 400)
        .background(Theme.bg)
        .preferredColorScheme(.dark)
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "bolt.fill")
                .foregroundStyle(Theme.neon)
            (Text("POSTURE ").foregroundColor(.white)
             + Text("MALONE").foregroundColor(Theme.neon))
                .font(.system(size: 15, weight: .black, design: .rounded))
                .italic()
            Spacer()
            circleButton(showHistory ? "chevron.up" : "chevron.down") {
                showHistory.toggle()
            }
            .help("7-day history")
            circleButton(posture.isPaused ? "play.fill" : "pause.fill") {
                posture.isPaused.toggle()
            }
            .help(posture.isPaused ? "Resume" : "Pause")
        }
    }

    private func circleButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.white.opacity(0.08)))
        }
        .buttonStyle(.plain)
    }

    // MARK: Hero

    private var statusWord: String {
        if posture.isPaused { return "PAUSED" }
        if !streaming { return "WAITING" }
        return posture.isSlouching ? "SLOUCHING" : "UPRIGHT"
    }

    private var statusColor: Color {
        if posture.isPaused || !streaming { return Theme.dim }
        return posture.isSlouching ? Theme.orange : Theme.neon
    }

    private var badge: (symbol: String, text: String, caption: String, color: Color) {
        if posture.isPaused {
            return ("pause.fill", "Paused", "Enjoy the break.", Theme.dim)
        }
        if !streaming {
            return ("airpods", "No signal", "Pop the buds in.", Theme.dim)
        }
        if posture.isSlouching {
            let dur = posture.slouchStartedAt.map {
                PostureMonitor.timeString(Date().timeIntervalSince($0))
            } ?? "0s"
            return ("exclamationmark.triangle.fill", "Slouching", "for \(dur)", Theme.orange)
        }
        return ("sparkle", "Great!", "Keep it up.", Theme.neon)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Circle().fill(statusColor).frame(width: 8, height: 8)
                        Text(statusWord)
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundStyle(statusColor)
                    }
                    Text("\(Int(posture.tiltDegrees.rounded()))°")
                        .font(.system(size: 46, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 5) {
                    let b = badge
                    HStack(spacing: 5) {
                        Image(systemName: b.symbol).font(.system(size: 10, weight: .bold))
                        Text(b.text).font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(b.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(b.color.opacity(0.12)))
                    .overlay(Capsule().stroke(b.color.opacity(0.6), lineWidth: 1))
                    Text(b.caption)
                        .font(.caption)
                        .foregroundStyle(Theme.dim)
                }
                .padding(.top, 6)
            }
            TiltBar(tilt: posture.tiltDegrees)
            Text("Neck tilt · Nudge threshold \(Int(posture.thresholdDegrees))°")
                .font(.caption2)
                .foregroundStyle(Theme.faint)
        }
    }

    @ViewBuilder
    private var diagnostics: some View {
        if !streaming && !posture.isPaused {
            Text("Motion permission: \(motion.authDescription)"
                 + (motion.lastError.map { "  ·  \($0)" } ?? ""))
                .font(.caption2)
                .foregroundStyle(Theme.dim)
                .textSelection(.enabled)
        }
    }

    // MARK: Stats

    private var statsCard: some View {
        HStack(spacing: 10) {
            statCol("arrow.up", Theme.neon, "Upright",
                    PostureMonitor.timeString(posture.uprightSeconds))
            statDivider
            statCol("figure.walk", Theme.orange, "Slouched",
                    PostureMonitor.timeString(posture.slouchSeconds), sub: slouchPct)
            statDivider
            statCol("bell.fill", Theme.purple, "Nudges", "\(posture.nudgeCount)")
        }
        .modifier(Card())
    }

    private var statDivider: some View {
        Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1, height: 34)
    }

    private var slouchPct: String? {
        let total = posture.uprightSeconds + posture.slouchSeconds
        guard total > 0 else { return nil }
        return "(\(Int((posture.slouchSeconds / total * 100).rounded()))%)"
    }

    private func statCol(_ symbol: String, _ color: Color, _ title: String,
                         _ value: String, sub: String? = nil) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 30, height: 30)
                .background(Circle().stroke(color.opacity(0.5), lineWidth: 1.5))
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.caption2).foregroundStyle(color)
                Text(value)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                if let sub {
                    Text(sub).font(.caption2).foregroundStyle(Theme.dim)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Calibrate

    private var calibrate: some View {
        VStack(spacing: 5) {
            Button(action: posture.calibrate) {
                HStack {
                    Image(systemName: "scope")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.neon)
                    Spacer()
                    Text("Set Upright Posture")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.neon)
                }
                .padding(.horizontal, 16)
                .frame(height: 44)
                .background(RoundedRectangle(cornerRadius: 22).fill(Theme.neon.opacity(0.10)))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Theme.neon, lineWidth: 1.5))
            }
            .buttonStyle(.plain)
            .disabled(!streaming)
            .opacity(streaming ? 1 : 0.4)
            Text("Recalibrate whenever your setup changes.")
                .font(.caption2)
                .foregroundStyle(Theme.faint)
                .frame(maxWidth: .infinity)
        }
    }

    // MARK: Settings

    private var settingsCard: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "waveform")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Theme.neon)
                .frame(width: 38, height: 38)
                .background(Circle().stroke(Theme.neon.opacity(0.3), lineWidth: 1.5))
            VStack(spacing: 10) {
                sliderRow("Nudge past", "at least",
                          value: $posture.thresholdDegrees, in: 5...35, step: 1,
                          label: "\(Int(posture.thresholdDegrees))°")
                sliderRow("after", "sustained for",
                          value: $posture.nudgeAfterSeconds, in: 15...600, step: 15,
                          label: PostureMonitor.timeString(posture.nudgeAfterSeconds))
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Spoken nudges")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                        Text("Play voice reminders")
                            .font(.caption2)
                            .foregroundStyle(Theme.dim)
                    }
                    Spacer()
                    Toggle("", isOn: $posture.speechEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .tint(Theme.neon)
                        .controlSize(.small)
                    circleButton("play.fill") { posture.speakNudge() }
                        .disabled(!posture.speechEnabled)
                        .opacity(posture.speechEnabled ? 1 : 0.4)
                        .help("Preview")
                }
            }
        }
        .modifier(Card())
    }

    private func sliderRow(_ title: String, _ sub: String,
                           value: Binding<Double>, in range: ClosedRange<Double>,
                           step: Double, label: String) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                Text(sub).font(.caption2).foregroundStyle(Theme.dim)
            }
            .frame(width: 78, alignment: .leading)
            Slider(value: value, in: range, step: step)
                .tint(Theme.neon)
                .controlSize(.small)
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(.white)
                .frame(width: 38, alignment: .trailing)
        }
    }

    // MARK: Phrase

    private var phraseCard: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "chair")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.neon)
            VStack(alignment: .leading, spacing: 4) {
                Text("Nudge phrase")
                    .font(.caption2)
                    .foregroundStyle(Theme.dim)
                HStack(spacing: 6) {
                    Image(systemName: "pencil")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.faint)
                    TextField("What should he say?", text: $posture.speechText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.35)))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.14)))
                Text("Your future self will high five you.")
                    .font(.caption2)
                    .foregroundStyle(Theme.dim)
            }
        }
        .modifier(Card())
    }

    // MARK: History

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            let days = posture.lastDays(7)
            if days.count > 1 {
                ForEach(days) { day in
                    HStack(spacing: 8) {
                        Text(day.date, format: .dateTime.weekday(.abbreviated))
                            .font(.caption2)
                            .foregroundStyle(Theme.dim)
                            .frame(width: 30, alignment: .leading)
                        ProgressView(value: day.slouchFraction)
                            .tint(Theme.orange)
                        Text("\(Int((day.slouchFraction * 100).rounded()))%")
                            .font(.caption2)
                            .monospacedDigit()
                            .foregroundStyle(Theme.dim)
                            .frame(width: 34, alignment: .trailing)
                    }
                }
                Text("Share of tracked time spent slouched")
                    .font(.caption2)
                    .foregroundStyle(Theme.faint)
            } else {
                Text("History shows up after a day of use.")
                    .font(.caption2)
                    .foregroundStyle(Theme.dim)
            }
        }
        .modifier(Card())
    }

    // MARK: Footer

    private var footer: some View {
        HStack(spacing: 8) {
            Text("PM")
                .font(.system(size: 14, weight: .black, design: .serif))
                .foregroundStyle(Theme.neon)
            Text("Posture Malone")
                .font(.caption)
                .foregroundStyle(Theme.dim)
            Spacer()
            Button("Quit") { NSApp.terminate(nil) }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
                .background(Capsule().fill(Color.white.opacity(0.08)))
        }
    }
}

// MARK: - Tilt bar

private struct TiltBar: View {
    let tilt: Double
    private let lo = -10.0
    private let hi = 40.0

    var body: some View {
        GeometryReader { geo in
            let frac = (min(max(tilt, lo), hi) - lo) / (hi - lo)
            let x = frac * (geo.size.width - 16)
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(LinearGradient(
                        colors: [Theme.neon, Theme.neon, .yellow, Theme.orange, Theme.alert],
                        startPoint: .leading, endPoint: .trailing))
                    .frame(height: 8)
                    .frame(maxHeight: .infinity)
                Circle()
                    .fill(Theme.neon)
                    .overlay(Circle().stroke(Color.black.opacity(0.5), lineWidth: 2))
                    .frame(width: 16, height: 16)
                    .offset(x: x)
            }
        }
        .frame(height: 16)
    }
}
