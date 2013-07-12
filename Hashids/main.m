//
//  main.m
//  Hashids
//
//  Created by Jofell Gallardo on 7/13/13.
//  Copyright (c) 2013 Jofell Gallardo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Hashids.h"

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        
        Hashids *test = [[Hashids alloc] initWithSalt:@"dmwqp9340hwdn2871e(&*_&@bihBI&T@^TG@O*&)"
                                            minLength:8
                                             andAlpha:@"9HJDEXY2ZT3AFUOSR5Q6CN4BMV7GL8PW"];
        
        NSLog(@"%@", [test encrypt:@245, nil]);
        
        // insert code here...
        NSLog(@"Hello, World!");
        
    }
    return 0;
}

