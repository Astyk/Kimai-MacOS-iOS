//
//  BMiCalExport.m
//  RunningApplications
//
//  Created by Vinzenz-Emanuel Weber on 24.04.13.
//  Copyright (c) 2013 blockhaus medienagentur. All rights reserved.
//

#import "BMiCalExport.h"
#import "BMApplication.h"


@implementation BMiCalExport


+ (NSString *)icalExportWithManagedObjectContext:(NSManagedObjectContext *)moc {
    
    NSMutableString *icalExportString = [NSMutableString stringWithString:[BMiCalExport header]];
    
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"BMApplication"
                                                         inManagedObjectContext:moc];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    
    NSError *error;
    NSArray *array = [moc executeFetchRequest:request error:&error];
    for (BMApplication *application in array) {
/*
        if ([application.bundleIdentifier isEqualToString:@"com.apple.loginwindow"] ||
            [application.bundleIdentifier isEqualToString:@"com.apple.ScreenSaver.Engine"]) {
            // do not track the login window or screensaver
            continue;
        }
*/        
        for (BMApplicationWindow *window in application.windows) {
            
            if (window.activeDuration.intValue == 0) {
                continue;
            }
            
            [icalExportString appendString:[BMiCalExport eventWithApplicationWindow:window]];
        }
        
    }
    
    [icalExportString appendString:[BMiCalExport footer]];
    
    
    
    //Create App directory if not exists:
    NSFileManager* fileManager = [[NSFileManager alloc] init];
    NSString* bundleID = [[NSBundle mainBundle] bundleIdentifier];
    NSArray* urlPaths = [fileManager URLsForDirectory:NSApplicationSupportDirectory
                                            inDomains:NSUserDomainMask];
    
    NSURL* appDirectory = [[urlPaths objectAtIndex:0] URLByAppendingPathComponent:bundleID isDirectory:YES];
    
    if (![fileManager fileExistsAtPath:[appDirectory path]]) {
        [fileManager createDirectoryAtURL:appDirectory withIntermediateDirectories:NO attributes:nil error:&error];
    }
    
    if (!error) {
        NSURL *icalExportFileURL = [appDirectory URLByAppendingPathComponent:@"export.ics"];
        [icalExportString writeToFile:[icalExportFileURL path] atomically:YES encoding:NSUTF8StringEncoding error:&error];
        if (error) {
            NSLog(@"%@", error.localizedDescription);
        }
        
    }

    
    return icalExportString;

}


+ (NSString *)header {
    return
    @"BEGIN:VCALENDAR\n" \
    @"METHOD:PUBLISH\n" \
    @"VERSION:2.0\n" \
    @"X-WR-CALNAME:TimeTracker\n" \
    @"PRODID:-//Apple Inc.//Mac OS X 10.8.3//EN\n" \
    @"X-WR-CALDESC:blockhausmedien.at_dcln7jnqgdl33g0cco9oopfr8g@group.calenda\n" \
    @"r.google.com\n" \
    @"X-APPLE-CALENDAR-COLOR:#44A703\n" \
    @"X-WR-TIMEZONE:Europe/Vienna\n" \
    @"CALSCALE:GREGORIAN\n" \
    @"BEGIN:VTIMEZONE\n" \
    @"TZID:Europe/Vienna\n" \
    @"BEGIN:DAYLIGHT\n" \
    @"TZOFFSETFROM:+0100\n" \
    @"RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=-1SU\n" \
    @"DTSTART:19810329T020000\n" \
    @"TZNAME:MESZ\n" \
    @"TZOFFSETTO:+0200\n" \
    @"END:DAYLIGHT\n" \
    @"BEGIN:STANDARD\n" \
    @"TZOFFSETFROM:+0200\n" \
    @"RRULE:FREQ=YEARLY;BYMONTH=10;BYDAY=-1SU\n" \
    @"DTSTART:19961027T030000\n" \
    @"TZNAME:MEZ\n" \
    @"TZOFFSETTO:+0100\n" \
    @"END:STANDARD\n" \
    @"END:VTIMEZONE\n";
}


+ (NSString *)eventWithApplicationWindow:(BMApplicationWindow *)window {
    
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uid = (NSString *)CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, uuid));

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMdd'T'HHmmss'Z'"; // 20130421T104052Z
    
    NSString *createdDateString = [formatter stringFromDate:[NSDate date]];
    NSString *activateDateString = [formatter stringFromDate:window.activateDate];
    NSString *deactivateDateString = [formatter stringFromDate:window.deactivateDate];
    
    return [NSString stringWithFormat:
            @"BEGIN:VEVENT\n" \
            @"UID:%@\n" \
            @"TRANSP:OPAQUE\n" \
            @"CREATED:%@\n" \
            @"LAST-MODIFIED:%@\n" \
            @"DTSTART;VALUE=DATE:%@\n" \
            @"DTEND;VALUE=DATE:%@\n" \
            @"DTSTAMP:%@\n" \
            @"SUMMARY:%@\n" \
            @"LOCATION:\n" \
            @"DESCRIPTION:%@\n" \
            @"STATUS:CONFIRMED\n" \
            @"SEQUENCE:0\n" \
            @"CLASS:PUBLIC\n" \
            @"END:VEVENT\n",
            uid,
            createdDateString, createdDateString,
            activateDateString, deactivateDateString, createdDateString,
            window.title, window.application.name];

}


+ (NSString *)footer {
    return @"END:VCALENDAR\n";
}


@end
