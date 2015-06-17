// Original implementation by Dave Dribin in 2007. Modifications to
// add locking on screensaver by Lena Singer and Keith Garner in 2011
//
#import <Foundation/Foundation.h>

#import "myListener.h"

int stop_agent(void)
{
    NSArray * arguments = [NSArray arrayWithObjects: @"stop",
                           @"org.openbsd.ssh-agent", nil];
    
    NSTask * stopAgent = [NSTask launchedTaskWithLaunchPath: @"/bin/launchctl"
                                                  arguments: arguments];
    [stopAgent waitUntilExit];
    return [stopAgent terminationStatus];
}

OSStatus lock_keychain(const char *keychainName)
{
    SecKeychainRef keychain = NULL;
    OSStatus result;
    
    if (keychainName)
	{
        result = SecKeychainOpen(keychainName, &keychain);
        
		if (!keychain)
		{
			result = 1;
			goto loser;
		}
	}
    
	result = SecKeychainLock(keychain);
    
	if (result)
	{
        NSLog(@"SecKeychainLock: %d", result);
	}
    
loser:
	if (keychain)
		CFRelease(keychain);
    
	return result;
}

OSStatus keychain_locked(SecKeychainEvent keychainEvent, SecKeychainCallbackInfo *info, void *context)
{
#if 1
    stop_agent();
#else
    NSLog(@"stop_agent: %d", stop_agent());
#endif
    
	return 0;
};


@interface myListener (Private)
- (void) scrensaverStarted:(NSNotification *)theNotification;
@end

@implementation myListener

- init
{
	if (self = [super init]) {
		[[NSDistributedNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(screensaverStarted:)
         name:@"com.apple.screensaver.didstart"
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

- (void)screensaverStarted:(NSNotification *)theNotification
{
#if 1
    lock_keychain(keychainName);
#else
    NSLog(@"lock_keychain: %d",  lock_keychain(keychainName));
#endif 
}

- (void)setKeychainName:(const char *)inKeychainName
{
    keychainName = inKeychainName;
}

@end

int main (int argc, const char * argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

	SecKeychainAddCallback(&keychain_locked, kSecLockEventMask, nil);
    
    myListener *theListener = [[myListener alloc] init];
    [theListener setKeychainName:argv[1]];

    [[NSRunLoop currentRunLoop] run];

    [pool drain];
    return 0;
}
