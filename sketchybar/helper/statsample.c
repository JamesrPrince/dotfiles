// One sample of everything plugins/stats.sh shows, in one process, printed as one line:
//
//   statsample CPUSTATE      ->  CPU MEMFREE LEVEL GPU EPOCH DAY IN OUT
//
//   CPU      user+system percent (0-100) since the last call (tick counts kept in CPUSTATE, as cpu.c does)
//   MEMFREE  system-wide free memory percentage (what `memory_pressure -Q` prints; Activity Monitor's)
//   LEVEL    kernel memory pressure level: 1 normal, 2 warning, 4 critical
//   GPU      busiest accelerator's "Device Utilization %" (what `ioreg -c IOAccelerator` shows)
//   EPOCH    seconds since 1970;  DAY  local date YYYY-MM-DD
//   IN OUT   en0 byte counters, 64-bit (what `netstat -ibn -I en0` shows); 0 0 when en0 is absent
//
// Replaces the memory_pressure, sysctl, ioreg, grep, cut, sort, tail, netstat, awk and date
// processes (and helper/cpu) that stats.sh used to start on every run.
// Build: clang -O2 -o statsample statsample.c -framework IOKit -framework CoreFoundation
#include <mach/mach.h>
#include <IOKit/IOKitLib.h>
#include <CoreFoundation/CoreFoundation.h>
#include <net/if.h>
#include <net/if_var.h>
#include <net/if_mib.h>
#include <sys/socket.h>
#include <sys/sysctl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

static unsigned long long cpu_percent(const char *path) {
  host_cpu_load_info_data_t c; mach_msg_type_number_t n = HOST_CPU_LOAD_INFO_COUNT;
  if (host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, (host_info_t)&c, &n)) return 0;
  unsigned long long u = c.cpu_ticks[CPU_STATE_USER] + c.cpu_ticks[CPU_STATE_NICE],
                     s = c.cpu_ticks[CPU_STATE_SYSTEM], i = c.cpu_ticks[CPU_STATE_IDLE];
  unsigned long long pu = 0, ps = 0, pi = 0; int have = 0;
  if (path) { FILE *f = fopen(path, "r"); if (f) { have = fscanf(f, "%llu %llu %llu", &pu, &ps, &pi) == 3; fclose(f); } }
  if (!have || u < pu || s < ps || i < pi) { pu = ps = pi = 0; }
  unsigned long long busy = (u - pu) + (s - ps), total = busy + (i - pi);
  if (path) { FILE *f = fopen(path, "w"); if (f) { fprintf(f, "%llu %llu %llu\n", u, s, i); fclose(f); } }
  return total ? (busy * 100 + total / 2) / total : 0;
}

static int sysctl_int(const char *name, int dflt) {
  int v; size_t l = sizeof v;
  return sysctlbyname(name, &v, &l, NULL, 0) == 0 ? v : dflt;
}

static int gpu_percent(void) {
  int best = 0;
  io_iterator_t it;
  if (IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOAccelerator"), &it)) return 0;
  io_object_t svc;
  while ((svc = IOIteratorNext(it))) {
    CFTypeRef p = IORegistryEntryCreateCFProperty(svc, CFSTR("PerformanceStatistics"), kCFAllocatorDefault, 0);
    if (p && CFGetTypeID(p) == CFDictionaryGetTypeID()) {
      CFTypeRef v = CFDictionaryGetValue((CFDictionaryRef)p, CFSTR("Device Utilization %"));
      int n = 0;
      if (v && CFGetTypeID(v) == CFNumberGetTypeID() && CFNumberGetValue(v, kCFNumberIntType, &n) && n > best) best = n;
    }
    if (p) CFRelease(p);
    IOObjectRelease(svc);
  }
  IOObjectRelease(it);
  return best;
}

static void en0_bytes(unsigned long long *in, unsigned long long *out) {
  *in = *out = 0;
  unsigned idx = if_nametoindex("en0");
  if (!idx) return;
  // The same 64-bit counters netstat reads (NET_RT_IFLIST2 rounds them to 32 bits on macOS 15)
  int mib[6] = { CTL_NET, PF_LINK, NETLINK_GENERIC, IFMIB_IFDATA, (int)idx, IFDATA_GENERAL };
  struct ifmibdata d; size_t len = sizeof d;
  if (sysctl(mib, 6, &d, &len, NULL, 0) == 0) { *in = d.ifmd_data.ifi_ibytes; *out = d.ifmd_data.ifi_obytes; }
}

int main(int argc, char **argv) {
  unsigned long long cpu = cpu_percent(argc > 1 ? argv[1] : NULL);
  int memfree = sysctl_int("kern.memorystatus_level", 100);
  int level = sysctl_int("kern.memorystatus_vm_pressure_level", 1);
  int gpu = gpu_percent();
  unsigned long long in, out; en0_bytes(&in, &out);
  time_t now = time(NULL); char day[16]; strftime(day, sizeof day, "%Y-%m-%d", localtime(&now));
  printf("%llu %d %d %d %lld %s %llu %llu\n", cpu, memfree, level, gpu, (long long)now, day, in, out);
  return 0;
}
