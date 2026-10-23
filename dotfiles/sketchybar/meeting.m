// Push the next calendar event with a video link to SketchyBar.
// It runs as its own launchd agent so macOS asks for Calendar access on its
// behalf rather than SketchyBar's.
#import <EventKit/EventKit.h>
#import <Foundation/Foundation.h>

static NSString *bar;
static EKEventStore *store;

static void set(NSArray<NSString *> *args) {
  NSTask *task = [NSTask new];
  task.executableURL = [NSURL fileURLWithPath:bar];
  task.arguments = [@[ @"--set", @"meeting" ] arrayByAddingObjectsFromArray:args];
  if ([task launchAndReturnError:nil]) [task waitUntilExit];
}

static NSString *joinURL(EKEvent *event) {
  // Excluding quotes keeps the URL safe inside the single-quoted click_script.
  static NSRegularExpression *pattern;
  if (!pattern)
    pattern = [NSRegularExpression
        regularExpressionWithPattern:@"https://(meet\\.google\\.com|([a-z0-9-]+\\.)*zoom\\.us|"
                                     @"teams\\.microsoft\\.com|teams\\.live\\.com)/[^\\s'\"<>]+"
                             options:NSRegularExpressionCaseInsensitive
                               error:nil];
  // Google puts the Meet link in the notes, others in the URL or location.
  for (NSString *text in @[ event.URL.absoluteString ?: @"", event.location ?: @"", event.notes ?: @"" ]) {
    NSTextCheckingResult *match = [pattern firstMatchInString:text options:0 range:NSMakeRange(0, text.length)];
    if (match) return [text substringWithRange:match.range];
  }
  return nil;
}

static BOOL declined(EKEvent *event) {
  for (EKParticipant *person in event.attendees)
    if (person.isCurrentUser) return person.participantStatus == EKParticipantStatusDeclined;
  return NO;
}

static void update(void) {
  if ([EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent] != EKAuthorizationStatusFullAccess) {
    set(@[
      @"drawing=on", @"label=Ingen kalenderåtkomst", @"icon.color=0xffed8796",
      @"click_script=/usr/bin/open 'x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars'"
    ]);
    return;
  }
  NSDate *now = [NSDate date];
  // A meeting stays for 10 minutes after it starts, long enough to join late.
  NSDate *earliest = [now dateByAddingTimeInterval:-600];
  NSPredicate *range = [store predicateForEventsWithStartDate:earliest
                                                      endDate:[now dateByAddingTimeInterval:86400]
                                                    calendars:nil];
  NSArray *events = [[store eventsMatchingPredicate:range] sortedArrayUsingSelector:@selector(compareStartDateWithEvent:)];
  for (EKEvent *event in events) {
    if (event.allDay || declined(event) || [event.startDate compare:earliest] == NSOrderedAscending) continue;
    NSString *url = joinURL(event);
    if (!url) continue;

    NSTimeInterval until = [event.startDate timeIntervalSinceDate:now];
    NSString *when;
    if (until <= 0) {
      when = @"nu";
    } else if (until < 3600) {
      when = [NSString stringWithFormat:@"om %.0f min", ceil(until / 60)];
    } else {
      NSDateFormatter *format = [NSDateFormatter new];
      format.dateFormat = @"HH:mm";
      when = [format stringFromDate:event.startDate];
      if (![NSCalendar.currentCalendar isDateInToday:event.startDate]) when = [@"imorgon " stringByAppendingString:when];
    }
    NSString *title = event.title.length ? event.title : @"Möte";
    if (title.length > 24) title = [[title substringToIndex:23] stringByAppendingString:@"…"];
    set(@[
      @"drawing=on", [NSString stringWithFormat:@"label=%@ · %@", when, title],
      [@"icon.color=" stringByAppendingString:until < 300 ? @"0xffeed49f" : @"0xff91d7e3"],
      [NSString stringWithFormat:@"click_script=/usr/bin/open '%@'", url]
    ]);
    return;
  }
  set(@[ @"drawing=off" ]);
}

int main(int argc, char *argv[]) {
  @autoreleasepool {
    if (argc != 2) {
      fprintf(stderr, "usage: %s <sketchybar>\n", argv[0]);
      return 64;
    }
    bar = @(argv[1]);
    store = [EKEventStore new];
    [store requestFullAccessToEventsWithCompletion:^(BOOL granted, NSError *error) {
      dispatch_async(dispatch_get_main_queue(), ^{
        // The store only sees calendars granted before it loaded them.
        [store reset];
        update();
      });
    }];
    [NSNotificationCenter.defaultCenter addObserverForName:EKEventStoreChangedNotification
                                                    object:store
                                                     queue:NSOperationQueue.mainQueue
                                                usingBlock:^(NSNotification *note) { update(); }];
    // The countdown and SketchyBar restarts need a periodic refresh.
    [NSTimer scheduledTimerWithTimeInterval:30 repeats:YES block:^(NSTimer *timer) { update(); }];
    [NSRunLoop.mainRunLoop run];
  }
  return 0;
}
