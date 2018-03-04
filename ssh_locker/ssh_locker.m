// Original implementation by Dave Dribin in 2007. Modifications to
// add locking on screensaver by Lena Singer and Keith Garner in 2011
// Further changes by Keith Garner in 2018
//
#import <Foundation/Foundation.h>

#import "myListener.h"
#include "sys/types.h"
#include "sys/un.h"
#include "sys/socket.h"

#define SSH_AGENT_SUCCESS 0x6
#define SSH_AGENTC_REMOVE_ALL_IDENTITIES 0x13

void remove_keys_from_agent(void)
{
    NSString *socketPath = [[NSProcessInfo processInfo] environment][@"SSH_AUTH_SOCK"];

    struct sockaddr_un socketInfo;
    socketInfo.sun_family = AF_UNIX;
    [socketPath getCString:socketInfo.sun_path maxLength:104 encoding:NSASCIIStringEncoding];
    socketInfo.sun_len = SUN_LEN(&socketInfo);

    NSLog(@"About to lock using %s", socketInfo.sun_path);

    int ssh_agent_socket = socket(PF_UNIX, SOCK_STREAM, 0);
    connect(ssh_agent_socket, (struct sockaddr *)&socketInfo, socketInfo.sun_len);

    // Per ssh communication, uint32 of message length (in our case the one byte following) and
    // then the message type which is SSH_AGENTC_REMOVE_ALL_IDENTITIES
    int8_t buffer[5];
    uint32_t messageLength = htonl(1);
    memcpy(buffer, &messageLength, 4);
    buffer[4] = SSH_AGENTC_REMOVE_ALL_IDENTITIES;

    send(ssh_agent_socket, buffer, 5, 0);
    recv(ssh_agent_socket, buffer, 5, MSG_WAITALL);

    memcpy(&messageLength, buffer, 4);
    messageLength = ntohl(messageLength);

    if ((messageLength != 1) || (buffer[4] != SSH_AGENT_SUCCESS))
    {
        NSLog(@"Failure removing keys from agent");
    }
    else
    {
        NSLog(@"Successfully removed keys");
    }

    close(ssh_agent_socket);
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
    remove_keys_from_agent();
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
