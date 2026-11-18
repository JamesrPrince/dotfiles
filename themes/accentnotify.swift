// Posts the notification System Settings posts after an accent colour change, so running apps repaint.
// Built on demand by reach.py into ~/.cache/theme-reach/accentnotify.
import Foundation
DistributedNotificationCenter.default().postNotificationName(
  NSNotification.Name("AppleColorPreferencesChangedNotification"), object: nil, userInfo: nil, deliverImmediately: true)
RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.3))
