// Event source for the bar's brightness slider: macOS has no public brightness notification, but
// DisplayServices (the framework helper/brightness already uses) posts one for the built-in display.
// This sleeps in the run loop (no CPU at idle) and, when the level changes, runs
//   sketchybar --trigger brightness_change INFO=<0-100>
// It exits when the bar is gone (the trigger fails), and only one runs at a time. Started by
// plugins/brightness_bar.sh watch, which items/brightness.sh queues for after the bar loads.
// Build: clang -O2 -F /System/Library/PrivateFrameworks -framework DisplayServices -framework CoreGraphics -framework CoreFoundation -o brightnesswatch brightnesswatch.c
#include <CoreFoundation/CoreFoundation.h>
#include <CoreGraphics/CoreGraphics.h>
#include <spawn.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/file.h>
#include <fcntl.h>
#include <sys/wait.h>
extern char **environ;
extern int DisplayServicesGetBrightness(CGDirectDisplayID id, float *b);
extern int DisplayServicesRegisterForBrightnessChangeNotifications(CGDirectDisplayID id, const void *observer, CFNotificationCallback cb);

static CGDirectDisplayID display;
static int last = -1;

static void changed(CFNotificationCenterRef c, void *o, CFNotificationName n, const void *obj, CFDictionaryRef ui) {
  float b = -1;
  if (DisplayServicesGetBrightness(display, &b)) return;
  int pct = (int)(b * 100 + 0.5f);
  if (pct == last) return;
  int first = last < 0;
  last = pct;
  if (first) return;   // the first look only records the level: no slide-out at start-up
  char info[32]; snprintf(info, sizeof info, "INFO=%d", pct);
  char *argv[] = {"/usr/local/bin/sketchybar", "--trigger", "brightness_change", info, NULL};
  pid_t pid; int st = 0;
  if (posix_spawn(&pid, argv[0], NULL, NULL, argv, environ) != 0) exit(1);
  waitpid(pid, &st, 0);
  if (!WIFEXITED(st) || WEXITSTATUS(st) != 0) exit(1);   // the bar is gone
}

int main(void) {
  // One watcher only: a second one (the bar's load and its safety poll can both start one) exits
  char lock[1024]; const char *t = getenv("TMPDIR");
  snprintf(lock, sizeof lock, "%s/sketchybar_brightnesswatch.lock", t ? t : "/tmp");
  int fd = open(lock, O_CREAT | O_RDWR, 0600);
  if (fd < 0 || flock(fd, LOCK_EX | LOCK_NB) != 0) return 0;
  CGDirectDisplayID list[8]; uint32_t n = 0;
  display = CGMainDisplayID();
  CGGetOnlineDisplayList(8, list, &n);
  for (uint32_t i = 0; i < n; i++) if (CGDisplayIsBuiltin(list[i])) { display = list[i]; break; }
  float b = -1;
  if (DisplayServicesGetBrightness(display, &b) == 0) last = (int)(b * 100 + 0.5f);
  if (DisplayServicesRegisterForBrightnessChangeNotifications(display, &display, changed)) return 1;
  CFRunLoopRun();
  return 0;
}
