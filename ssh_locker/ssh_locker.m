// Original implementation by Dave Dribin in 2007. Modifications to
// add locking on screensaver by Lena Singer and Keith Garner in 2011
//
#import <Foundation/Foundation.h>

#import "myListener.h"

int stop_agent(void)
{
    NSArray * arguments = [NSArray arrayWithObjects: @"stop",
                           @"com.openssh.ssh-agent", nil];
    
    NSTask * stopAgent = [NSTask launchedTaskWithLaunchPath: @"/bin/launchctl"
                                                  arguments: arguments];
    [stopAgent waitUntilExit];
    return [stopAgent terminationStatus];
}


@interface myListener (Private)
- (void) screensaverOrScreenLocked:(NSNotification *)theNotification;
@end

@implementation myListener

- init
{
    if (self = [super init]) {
        [[NSDistributedNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(screensaverOrScreenLocked:)
         name:@"com.apple.screenIsLocked"
         object:nil
         ];
    }
    return self;
}

- (void)dealloc
{
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)screensaverOrScreenLocked:(NSNotification *)theNotification
{
#if 1
    stop_agent();
#else
    NSLog(@"stop_agent: %d",  stop_agent());
#endif
}

@end

int main (int argc, const char * argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    [[myListener alloc] init];

    [[NSRunLoop currentRunLoop] run];

    [pool drain];
    return 0;
}
