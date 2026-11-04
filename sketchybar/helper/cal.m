// Remaining events today (or over the next N days with "cal N") as "HH:MM<TAB>title", one per line. Exit 3 if access is denied.
// Build: clang -O2 -framework EventKit -framework Foundation -sectcreate __TEXT __info_plist cal.plist -o cal cal.m
#import <EventKit/EventKit.h>
int main(int argc, char **argv) {
  int days = argc > 1 ? atoi(argv[1]) : 1; if (days < 1) days = 1;
  @autoreleasepool {
    EKEventStore *store = [EKEventStore new];
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    __block BOOL ok = NO;
    [store requestFullAccessToEventsWithCompletion:^(BOOL granted, NSError *e) { ok = granted; dispatch_semaphore_signal(sem); }];
    dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 20 * NSEC_PER_SEC));
    if (!ok) { puts("DENIED"); return 3; }
    NSDate *now = [NSDate date];
    NSDate *end = [[NSCalendar currentCalendar] startOfDayForDate:[now dateByAddingTimeInterval:86400.0 * days]];
    NSPredicate *p = [store predicateForEventsWithStartDate:now endDate:end calendars:nil];
    NSArray *events = [[store eventsMatchingPredicate:p] sortedArrayUsingSelector:@selector(compareStartDateWithEvent:)];
    NSDateFormatter *f = [NSDateFormatter new]; f.dateFormat = days > 1 ? @"EEE HH:mm" : @"HH:mm";
    for (EKEvent *e in events) {
      NSDateFormatter *d = [NSDateFormatter new]; d.dateFormat = @"EEE";
      NSString *t = !e.allDay ? [f stringFromDate:e.startDate]
                  : days > 1 ? [NSString stringWithFormat:@"%@ all day", [d stringFromDate:e.startDate]] : @"All day";
      printf("%s\t%s\n", t.UTF8String, (e.title ?: @"Untitled").UTF8String);
    }
  }
  return 0;
}
