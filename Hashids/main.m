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
        
        Hashids *test = [[Hashids alloc] initWithSalt:@"this is my salt"
                                            minLength:0
                                             andAlpha:nil];
        
        NSLog(@"%@", [test encrypt:@1, @2, @3, nil]);
        
        // insert code here...
        NSLog(@"Hello, World!");
        
    }
    return 0;
}

