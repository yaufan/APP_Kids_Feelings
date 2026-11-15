import 'dart:async';
import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

/// Shaking the phone (搥枕頭's helper: docs/design.md 用力點為主、搖手機為輔).
/// The accelerometer needs no permission.
abstract interface class Shakes {
  /// One event for each good shake.
  Stream<void> get shakes;
}

class NoShakes implements Shakes {
  const NoShakes();

  @override
  Stream<void> get shakes => const Stream.empty();
}

/// Shakes from the phone's accelerometer (without gravity): a jolt stronger
/// than [threshold] m/s², at most one every [gap].
class SystemShakes implements Shakes {
  const SystemShakes();

  static const threshold = 13.0;
  static const gap = Duration(milliseconds: 280);

  @override
  Stream<void> get shakes {
    DateTime? last;
    try {
      return userAccelerometerEventStream(samplingPeriod: SensorInterval.gameInterval).where((e) {
        final g = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
        if (g < threshold) return false;
        final now = DateTime.now();
        if (last != null && now.difference(last!) < gap) return false;
        last = now;
        return true;
      }).map((_) {}).handleError((Object _) {});
    } catch (_) {
      // No accelerometer: tapping is enough.
      return const Stream.empty();
    }
  }
}
