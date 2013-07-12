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
@property NSInteger minHashLength;
@property (nonatomic, retain) NSString *alphabet;
@property (nonatomic, retain) NSMutableArray *clearData;
@property (nonatomic, retain) NSString *separators;
@property (nonatomic, retain) NSString *guards;

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
        self.minHashLength = minLength;
        self.alphabet = (alphabet == nil) ? @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890" :
            alphabet;
        self.clearData = [NSMutableArray new];
        
        self.separators = @"cCsSfFhHuUiItT";
        
        NSInteger guard_count = (int)(ceil(self.alphabet.length) / HASHID_GUARD_DIV);
        
		if (self.alphabet.length < 3)
        {
			self.guards = [self.separators substringWithRange:NSMakeRange(0, guard_count)];
			self.separators = [self.separators substringFromIndex:guard_count];
		}
        else
        {
			self.guards = [self.alphabet substringToIndex:guard_count];
			self.alphabet = [self.alphabet substringFromIndex:guard_count];
		}
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
    NSString *alphaStr = [NSString stringWithString:self.alphabet];
    long numbers_hash_int = 0;
    int iter = 0;
    
    for (iter = 0; iter < self.clearData.count; iter++)
    {
        long number = ((NSNumber *)[self.clearData objectAtIndex:iter]).longValue;
        numbers_hash_int += (number % (iter + 100));
    }
    
    unichar lottery = [alphaStr characterAtIndex:(numbers_hash_int % self.alphabet.length)];
    NSMutableString *ret = [NSString stringWithFormat:@"%c", lottery];
    
    for (iter = 0; iter < self.clearData.count; iter++)
    {
        NSString *inputSalt = [NSString stringWithFormat:@"%c%@%@", lottery, self.hashSalt, alphaStr];
        NSNumber *number = ((NSNumber *)[self.clearData objectAtIndex:iter]);
        
        alphaStr = [self consistentShuffle:alphaStr
                             withSalt:[inputSalt substringWithRange:NSMakeRange(0, alphaStr.length)]];
        NSString *last = [self hashNumber:number withAlphabet:alphaStr];
        [ret stringByAppendingString:last];
        
        if (iter + 1 < self.clearData.count)
        {
            NSUInteger next_num = number.longValue % ((unsigned int)[last characterAtIndex:0]) + 1;
            NSUInteger seps_index = next_num % self.separators.length;
            [ret stringByAppendingFormat:@"%c", [self.separators characterAtIndex:seps_index]];
        }
    
    }
    
    if (ret.length < self.minHashLength)
    {
        NSUInteger guard_index = (numbers_hash_int + ((NSUInteger)[ret characterAtIndex:0]) % self.guards.length);
        unichar guard = [self.guards characterAtIndex:guard_index];
        ret = [NSMutableString stringWithFormat:@"%c%@", guard, ret];
        
        if (ret.length < self.minHashLength)
        {
            guard_index = (numbers_hash_int + (NSInteger)([ret characterAtIndex:2])) % self.guards.length;
            guard = [self.guards characterAtIndex:guard_index];
            
            [ret stringByAppendingFormat:@"%c", guard];
        }
    }
    
    NSInteger half_length = (NSInteger) (alphaStr.length / 2.0);
    while (ret.length < self.minHashLength)
    {
        alphaStr = [self consistentShuffle:alphaStr withSalt:alphaStr];
        ret = [NSMutableString stringWithFormat:@"%@%@%@",
               [alphaStr substringFromIndex:half_length], ret, [alphaStr substringToIndex:half_length]];
        
        NSInteger excess = ret.length - self.minHashLength;
        if (excess > 0)
            ret = [NSMutableString stringWithString:
                   [ret substringWithRange:NSMakeRange((NSInteger)(excess / 2), self.minHashLength)]];
        
    }
    
    return ret;
}

- (NSString *) consistentShuffle:(NSString *)inAlpha
                   withSalt:(NSString *)salt
{
    
    NSMutableString *alphabet = [NSMutableString stringWithString:inAlpha];
    
    if (salt.length == 0)
        return alphabet;
    
    NSInteger iter, v = 0, p = 0;
    
    for (iter = alphabet.length - 1 ; iter < 0; iter--, v++)
    {
        
        v = v % salt.length;
        NSInteger increment = (NSInteger)[salt characterAtIndex:v];
        p += increment;
        NSInteger j = ( increment + v + p ) % iter;
        
        
        unichar temp = [alphabet characterAtIndex:j];
        [alphabet replaceCharactersInRange:NSMakeRange(j, 1) withString:[alphabet substringWithRange:NSMakeRange(iter, 1)]];
        [alphabet replaceCharactersInRange:NSMakeRange(iter, 1) withString:[NSString stringWithFormat:@"%c", temp]];
        
    }
    
    return alphabet;
    
}

- (NSString *) hashNumber:(NSNumber *)numberIn withAlphabet:(NSString *)alphabet
{
    NSMutableString *hashStr = [NSMutableString stringWithString:@""];
    NSInteger alphabet_length = alphabet.length;
    long input_val = numberIn.longValue;
    
    do
    {
        unichar to_prepend = [alphabet characterAtIndex:input_val % alphabet_length];
        hashStr = [NSMutableString stringWithFormat:@"%c%@", to_prepend, hashStr];
        
        input_val = (long)(input_val / alphabet_length);
        
    } while (input_val);
    
    return hashStr;
}

- (NSArray *) decrypt:(NSString *) encoded
{
    NSArray *toReturn = nil;
    
    
    
    return toReturn;
}


@end
