# Fast launch and native splash

Docify calls `runApp` immediately. The native Android splash is released by the
first Flutter frame, not by Firebase, Google Sign-In, ads, or an animation timer.

- The launch gate reads only `onboarding_seen_v1` from local preferences. It
  routes as soon as that read completes, interrupting the entrance if needed.
  A failed preferences read falls back to the guest-capable Home screen.
- After the first frame, Firebase's local session setup and AdMob initialize
  independently of routing. They share single-flight futures with consumers.
  Google Sign-In setup remains lazy; no startup account chooser or silent
  authentication is added. An unconfigured build still works as a guest app.
- Only Home mounts at launch. Tools, Documents and Profile mount on first use
  and keep their state afterwards; hidden tabs stop ticking animations. In
  particular, the document library is not scanned just to show Home.
- A banner waits for ad SDK readiness, never blocks Home, and ignores late
  callbacks after its widget has been disposed. Builds without a banner unit
  skip the SDK entirely.

## Splash artwork and motion

The existing paper/check/sparkle identity is redrawn as a small vector. The
launcher icon and store/app name are unchanged. A sky-blue background matches
across the native window, day/night launch themes and Flutter's first frame.

Android 12+ uses `drawable/splash_mark_animated.xml`: a 360 ms, one-shot paper
pop, drawn checkmark, gentle sparkle turn, and a rising/fading **Docify** wordmark.
The wordmark is an outlined path inside the icon, not Android's static bottom
branding slot. Its artwork fits the system splash's inner safe circle.

Android 11 and older use the same finished vector in `launch_background.xml`.
A window background cannot play an animated vector, so there is no extra splash
Activity, dependency, GIF/video, or minimum display time to emulate it.

`windowSplashScreenAnimationDuration` is metadata, not a delay. There is no
keep-on-screen condition, exit-listener wait, animation-completion navigation,
or artificial splash timer. Fast launches can skip the unfinished native
motion. The short Flutter bridge also ends as soon as local routing is ready
and respects reduced-motion settings.

Native vector geometry is mirrored in `lib/widgets/launch_splash.dart`; keep
both versions and their timing aligned when editing the design.

## Evidence and limits

`test/startup_test.dart` covers pending SDKs, first/returning installs,
preferences failures and SDK failures. `test/widget_test.dart` guards lazy
mounting/state retention; `test/launch_splash_test.dart` covers the entrance,
reduced motion, small layouts and mid-animation disposal.

These tests prove that optional SDKs no longer gate Home. They do not measure
cold launch milliseconds on a real phone or compile Android resources. Verify
cold/warm launch and the native motion on a release APK on both Android 12+
and an older supported Android device. No local APK/AAB/web/Gradle build is
needed for the agent loop.

The current `ci.yml` still has a `push` trigger, despite the manual-only
onboarding notes. This batch does not change or dispatch workflows. Use one
batched push and do not queue a duplicate CI run if one already started.
