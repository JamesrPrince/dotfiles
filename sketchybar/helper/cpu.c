// CPU load since the last call, without blocking.
//   cpu STATEFILE   prints user+system percent (0-100) and saves the tick counts
// Build: clang -O2 -o cpu cpu.c
#include <mach/mach.h>
#include <stdio.h>

int main(int argc, char **argv) {
  host_cpu_load_info_data_t c; mach_msg_type_number_t n = HOST_CPU_LOAD_INFO_COUNT;
  if (host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, (host_info_t)&c, &n)) return 1;
  unsigned long long u = c.cpu_ticks[CPU_STATE_USER] + c.cpu_ticks[CPU_STATE_NICE],
                     s = c.cpu_ticks[CPU_STATE_SYSTEM], i = c.cpu_ticks[CPU_STATE_IDLE];
  unsigned long long pu = 0, ps = 0, pi = 0; int have = 0;
  const char *path = argc > 1 ? argv[1] : NULL;
  if (path) { FILE *f = fopen(path, "r"); if (f) { have = fscanf(f, "%llu %llu %llu", &pu, &ps, &pi) == 3; fclose(f); } }
  if (!have || u < pu || s < ps || i < pi) { pu = ps = pi = 0; }
  unsigned long long busy = (u - pu) + (s - ps), total = busy + (i - pi);
  printf("%llu\n", total ? (busy * 100 + total / 2) / total : 0);
  if (path) { FILE *f = fopen(path, "w"); if (f) { fprintf(f, "%llu %llu %llu\n", u, s, i); fclose(f); } }
  return 0;
}
