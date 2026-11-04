// Audio devices.
//   audio list       output device names, one per line
//   audio current    the default output device
//   audio set NAME   make NAME the default output
//   audio mic        "on" if any input device is in use, else "off"
// Build: clang -O2 -framework CoreAudio -framework CoreFoundation -o audio audio.c
#include <CoreAudio/CoreAudio.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static AudioObjectPropertyAddress addr(AudioObjectPropertySelector s, AudioObjectPropertyScope sc) {
  AudioObjectPropertyAddress a = { s, sc, kAudioObjectPropertyElementMain }; return a;
}
static int devices(AudioDeviceID **out) {
  AudioObjectPropertyAddress a = addr(kAudioHardwarePropertyDevices, kAudioObjectPropertyScopeGlobal);
  UInt32 sz = 0;
  if (AudioObjectGetPropertyDataSize(kAudioObjectSystemObject, &a, 0, NULL, &sz)) return 0;
  *out = malloc(sz);
  if (AudioObjectGetPropertyData(kAudioObjectSystemObject, &a, 0, NULL, &sz, *out)) return 0;
  return sz / sizeof(AudioDeviceID);
}
static int hasStreams(AudioDeviceID d, AudioObjectPropertyScope sc) {
  AudioObjectPropertyAddress a = addr(kAudioDevicePropertyStreams, sc);
  UInt32 sz = 0;
  return AudioObjectGetPropertyDataSize(d, &a, 0, NULL, &sz) == 0 && sz > 0;
}
static void name(AudioDeviceID d, char *buf, size_t len) {
  AudioObjectPropertyAddress a = addr(kAudioObjectPropertyName, kAudioObjectPropertyScopeGlobal);
  CFStringRef s = NULL; UInt32 sz = sizeof s; buf[0] = 0;
  if (AudioObjectGetPropertyData(d, &a, 0, NULL, &sz, &s) == 0 && s) {
    CFStringGetCString(s, buf, len, kCFStringEncodingUTF8); CFRelease(s);
  }
}
static AudioDeviceID current(void) {
  AudioObjectPropertyAddress a = addr(kAudioHardwarePropertyDefaultOutputDevice, kAudioObjectPropertyScopeGlobal);
  AudioDeviceID d = 0; UInt32 sz = sizeof d;
  AudioObjectGetPropertyData(kAudioObjectSystemObject, &a, 0, NULL, &sz, &d);
  return d;
}
int main(int argc, char **argv) {
  const char *cmd = argc > 1 ? argv[1] : "current";
  AudioDeviceID *ids = NULL; int n = devices(&ids); char buf[256];
  if (!strcmp(cmd, "list")) {
    for (int i = 0; i < n; i++) if (hasStreams(ids[i], kAudioObjectPropertyScopeOutput)) { name(ids[i], buf, sizeof buf); puts(buf); }
  } else if (!strcmp(cmd, "current")) {
    name(current(), buf, sizeof buf); puts(buf);
  } else if (!strcmp(cmd, "set") && argc > 2) {
    for (int i = 0; i < n; i++) {
      if (!hasStreams(ids[i], kAudioObjectPropertyScopeOutput)) continue;
      name(ids[i], buf, sizeof buf);
      if (strcmp(buf, argv[2])) continue;
      AudioObjectPropertyAddress a = addr(kAudioHardwarePropertyDefaultOutputDevice, kAudioObjectPropertyScopeGlobal);
      return AudioObjectSetPropertyData(kAudioObjectSystemObject, &a, 0, NULL, sizeof ids[i], &ids[i]) ? 1 : 0;
    }
    return 1;
  } else if (!strcmp(cmd, "mic")) {
    int on = 0;
    for (int i = 0; i < n && !on; i++) {
      if (!hasStreams(ids[i], kAudioObjectPropertyScopeInput)) continue;
      AudioObjectPropertyAddress a = addr(kAudioDevicePropertyDeviceIsRunningSomewhere, kAudioObjectPropertyScopeGlobal);
      UInt32 v = 0, sz = sizeof v;
      if (AudioObjectGetPropertyData(ids[i], &a, 0, NULL, &sz, &v) == 0 && v) on = 1;
    }
    puts(on ? "on" : "off");
  } else return 2;
  return 0;
}
