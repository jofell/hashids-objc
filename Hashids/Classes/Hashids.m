//
//  Hashids.m
//  Hashids
//
//  Created by Jofell Gallardo on 7/13/13.
//  Copyright (c) 2013 Jofell Gallardo. All rights reserved.
//

#import "Hashids.h"

@interface Hashids (Private)

@property (nonatomic, retain) NSString *hashSalt;
@property NSInteger minLength;
@property (nonatomic, retain) NSString *alphabet;
@property (nonatomic, retain) NSMutableArray *clearData;
@property (nonatomic, retain) NSString *separators;

@end

@implementation Hashids

- (id)init
{
    self = [[Hashids alloc] initWithSalt:nil
                               minLength:0
                                andAlpha:nil];
    if (self) {
        
    }
    return self;
}

- (id)initWithSalt:(NSString *) salt
         minLength:(NSInteger) minLength
          andAlpha:(NSString *) alphabet
{
    self = [super init];
    if (self) {
        self.hashSalt = salt;
        self.minLength = minLength;
        self.alphabet = (alphabet == nil) ? @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890" :
            alphabet;
        self.clearData = [NSMutableArray new];
        
        self.separators = @"cCsSfFhHuUiItT";
    }
    return self;
}

- (NSString *) encrypt:(NSNumber *)firstEntry, ... NS_REQUIRES_NIL_TERMINATION
{
    [self.clearData removeAllObjects];
    
    va_list args;
    va_start(args, firstEntry);
    
    NSNumber *arg = nil;
    while ((arg = va_arg(args, NSNumber*)))
    {
        if((strcmp([arg objCType], @encode(int))) != 0 ||
           arg.longValue < 0 || arg.longValue > HASHID_MAX_INT_VALUE)
            return nil;
        
        [self.clearData addObject:arg];
    }
    
    va_end(args);
    
    return (self.clearData > 0) ? [self encode] : nil;
 }

- (NSString *) encode
{
    NSMutableString *toReturn = [NSMutableString new];
    long numbers_hash_int = 0;
    int iter = 0;
    
    for (iter = 0; iter < self.clearData.count; iter++)
    {
        long number = ((NSNumber *)[self.clearData objectAtIndex:iter]).longValue;
        numbers_hash_int += (number % (iter + 100));
    }
    
    return toReturn;
}

- (NSArray *) decrypt:(NSString *) encoded
{
    NSArray *toReturn = nil;
    
    
    
    return toReturn;
}


@end
