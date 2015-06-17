//
//  myListener.h
//  ssh_locker
//
//  Created by Lena Singer on 8/2/11.
//  Editing by Keith Garner on 11/8/2011
//  Copyright 2011. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface myListener : NSObject {
    const char *keychainName;
}

- (void) setKeychainName: (const char*) inKeychainName;
@end
