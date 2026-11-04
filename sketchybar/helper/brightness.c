// Built-in display brightness: "brightness" prints 0-100, "brightness 60" sets it.
// Build: clang -O2 -F /System/Library/PrivateFrameworks -framework DisplayServices -framework CoreGraphics -o brightness brightness.c
#include <CoreGraphics/CoreGraphics.h>
#include <stdio.h>
#include <stdlib.h>
extern int DisplayServicesGetBrightness(CGDirectDisplayID id, float *b);
extern int DisplayServicesSetBrightness(CGDirectDisplayID id, float b);
int main(int argc, char **argv) {
  CGDirectDisplayID d = CGMainDisplayID();
  CGDirectDisplayID list[8]; uint32_t n = 0;
  CGGetOnlineDisplayList(8, list, &n);
  for (uint32_t i = 0; i < n; i++) if (CGDisplayIsBuiltin(list[i])) { d = list[i]; break; }
  if (argc > 1) {
    float v = atof(argv[1]) / 100.0f; if (v < 0) v = 0; if (v > 1) v = 1;
    if (DisplayServicesSetBrightness(d, v)) return 1;
  }
  float b = -1;
  if (DisplayServicesGetBrightness(d, &b)) { puts("-1"); return 1; }
  printf("%.0f\n", b * 100);
  return 0;
}
