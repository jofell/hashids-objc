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
        
        Hashids *test = [[Hashids alloc] initWithSalt:nil
                                            minLength:0
                                             andAlpha:nil];
        
        NSString *hashed = [test encrypt:@123456789, nil];
        NSLog(@"%@", hashed);
        
        NSLog(@"%@", [test decrypt:hashed]);
        
    }
    return 0;
}

