// Prints "on" if any camera is in use, else "off". Does not open the camera.
// Build: clang -O2 -framework CoreMediaIO -framework CoreFoundation -o camera camera.c
#include <CoreMediaIO/CMIOHardware.h>
#include <stdio.h>
#include <stdlib.h>
int main(void) {
  CMIOObjectPropertyAddress a = { kCMIOHardwarePropertyDevices, kCMIOObjectPropertyScopeGlobal, kCMIOObjectPropertyElementMain };
  UInt32 sz = 0, used = 0;
  if (CMIOObjectGetPropertyDataSize(kCMIOObjectSystemObject, &a, 0, NULL, &sz)) { puts("off"); return 0; }
  CMIODeviceID *ids = malloc(sz);
  CMIOObjectGetPropertyData(kCMIOObjectSystemObject, &a, 0, NULL, sz, &used, ids);
  int on = 0;
  for (UInt32 i = 0; i < used / sizeof *ids && !on; i++) {
    CMIOObjectPropertyAddress r = { kCMIODevicePropertyDeviceIsRunningSomewhere, kCMIOObjectPropertyScopeWildcard, kCMIOObjectPropertyElementWildcard };
    UInt32 v = 0, got = 0;
    if (CMIOObjectGetPropertyData(ids[i], &r, 0, NULL, sizeof v, &got, &v) == 0 && v) on = 1;
  }
  puts(on ? "on" : "off");
  return 0;
}
