# Posture Malone

A menu-bar-only macOS "tech neck" coach driven by AirPods motion sensors.
You've been slouchin' too long — Posture Malone notices, and says so in your ears
(any AirPods that support spatial-audio head tracking), using Apple's public
`CMHeadphoneMotionManager` API.

Down-tilt is measured against gravity, so it's absolute and drift-free —
the ideal use of this sensor. No Dock icon, no windows: just a brain in
your menu bar.

## Requirements

- macOS 14 or later
- AirPods connected to this Mac and in your ears
- Xcode (or just Command Line Tools if you use `build.sh`)

## Run

**With Xcode:** open `PostureMalone.xcodeproj`, press ⌘R.

**Without Xcode:**

```bash
./build.sh && open "build/Posture Malone.app"
```

On first launch macOS asks for Motion & Fitness access — allow it, or
nothing streams. (The popover shows the current permission state and any
sensor error while it's not streaming.)

The project file is generated with [xcodegen](https://github.com/yonaskolb/XcodeGen)
from `project.yml`; if you change the file layout, re-run `xcodegen generate`.

## Using it

1. Put the AirPods in, click the brain icon, sit the way you want to sit,
   and click **Set Upright Posture** once. Recalibrate whenever your setup
   changes (couch vs desk, reclined chair, laptop on lap).
2. When you stay tilted past the threshold (default 15°) for longer than the
   delay (default 60s), a phrase you write yourself is spoken (TTS) through
   the AirPods — and again at the same interval while you stay slouched. The
   menu bar icon shows the current down-tilt while you're slouching.
3. The popover tracks upright vs slouched time per day (last 7 days shown).
   Time only accumulates while the buds are in and streaming.
4. The pause button in the popover header suspends counting and nudges (the
   gauge stays live); the menu bar icon shows a pause badge until you resume.

Threshold, delay, the spoken phrase, and a preview button are all in the
popover.

## Troubleshooting

- **"Waiting for AirPods motion…"** — the buds must be *connected to this
  Mac* (check the sound menu) and worn. If they auto-switched to your
  iPhone, play any audio on the Mac to pull them back.
- **Permission denied** — System Settings › Privacy & Security › Motion &
  Fitness, enable Posture Malone.

## Sibling project

The 3D head-orientation viewer this grew out of lives in
[AirPodsHeadTracker](https://github.com/pratikaman/AirPodsHeadTracker).
