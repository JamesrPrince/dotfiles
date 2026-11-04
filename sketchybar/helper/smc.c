// Prints "<cpu °C> <fan rpm>" from the Intel SMC (AppleSMC), e.g. "54.2 1803".
// Build: clang -O2 -framework IOKit -o smc smc.c
#include <IOKit/IOKitLib.h>
#include <stdio.h>
#include <string.h>

typedef struct { char major, minor, build, reserved[1]; UInt16 release; } Vers;
typedef struct { UInt16 version, length; UInt32 cpuPLimit, gpuPLimit, memPLimit; } PLimit;
typedef struct { UInt32 dataSize, dataType; char dataAttributes; } KeyInfo;
typedef struct {
  UInt32 key; Vers vers; PLimit pLimitData; KeyInfo keyInfo;
  char result, status, data8; UInt32 data32; unsigned char bytes[32];
} SMCParam;

static io_connect_t conn;

static UInt32 k4(const char *s) { return (s[0] << 24) | (s[1] << 16) | (s[2] << 8) | s[3]; }

static int call(SMCParam *in, SMCParam *out) {
  size_t sz = sizeof(SMCParam);
  return IOConnectCallStructMethod(conn, 2, in, sizeof(SMCParam), out, &sz);
}

// Returns the value as a double, or -1 if the key is missing.
static double readKey(const char *key) {
  SMCParam in = {0}, out = {0};
  in.key = k4(key); in.data8 = 9;                       // read key info
  if (call(&in, &out) != kIOReturnSuccess || out.result) return -1;
  UInt32 size = out.keyInfo.dataSize, type = out.keyInfo.dataType;
  in.keyInfo.dataSize = size; in.data8 = 5;             // read bytes
  memset(&out, 0, sizeof out);
  if (call(&in, &out) != kIOReturnSuccess || out.result) return -1;
  unsigned char *b = out.bytes;
  if (type == k4("sp78")) return (double)(signed char)b[0] + b[1] / 256.0;
  if (type == k4("fpe2")) return ((b[0] << 8) | b[1]) / 4.0;
  if (type == k4("flt ")) { float f; memcpy(&f, b, 4); return f; }
  if (type == k4("ui8 ")) return b[0];
  if (type == k4("ui16")) return (b[0] << 8) | b[1];
  return -1;
}

int main(void) {
  io_service_t svc = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"));
  if (!svc || IOServiceOpen(svc, mach_task_self(), 0, &conn) != kIOReturnSuccess) return 1;
  IOObjectRelease(svc);
  const char *temps[] = {"TC0P", "TC0D", "TC0E", "TC0F", "TCXC"};
  double t = -1;
  for (int i = 0; i < 5 && t <= 0; i++) t = readKey(temps[i]);
  double fan = readKey("F0Ac");
  printf("%.1f %.0f\n", t, fan);
  IOServiceClose(conn);
  return 0;
}
