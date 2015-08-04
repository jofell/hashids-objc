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
        
        Hashids *hashids = [Hashids hashidWithSalt:@"this is my salt"];
        
        NSString *hash = [hashids encode:@1, @2, @3, nil];
        NSLog(@"%@", hash);
        NSLog(@"%@", [hashids decode:hash]);
        
        /*
         Output: 
         laHquq
         (
             1,
             2,
             3
         )

         */
        
    }
    return 0;
}

