//
//  Hashids.m
//  Hashids
//
//  Created by Jofell Gallardo on 7/13/13.
//  Copyright (c) 2013 Jofell Gallardo. All rights reserved.
//

#import "Hashids.h"


#pragma mark -
#pragma mark Private properties for hashids class

@interface Hashids ()

@property (nonatomic, retain) NSString *hashSalt;
@property NSInteger minHashLength;
@property (nonatomic, retain) NSString *alphabet;
@property (nonatomic, retain) NSMutableArray *clearData;
@property (nonatomic, retain) NSString *separators;
@property (nonatomic, retain) NSString *guards;

@property (nonatomic, retain) NSArray *primes;

@end

#pragma mark -
#pragma mark Exception class

@implementation HashidsException
@end

#pragma mark -
#pragma mark NSString category for Hashids

@implementation NSMutableString (Hashids)

- (NSString *) replaceIndex:(NSInteger)index withString:(NSString *)replaceString
{
    if (index > self.length || index < 0 || index + replaceString.length > self.length)
        return nil;
    
    NSString *oldString = [self substringWithRange:NSMakeRange(index, 1)];
    
    [self replaceCharactersInRange:NSMakeRange(index, 1) withString:replaceString];
    
    return oldString;
}

@end


#pragma mark -
#pragma mark Implementation for Hashids class

@implementation Hashids

@synthesize hashSalt;
@synthesize minHashLength;
@synthesize alphabet;
@synthesize clearData;
@synthesize separators;
@synthesize guards;


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
          andAlpha:(NSString *) inAlpha
{
    self = [super init];
    if (self) {
        
        self.primes = @[@2, @3, @5, @7, @11, @13, @17, @19, @23, @29, @31, @37, @41, @43];
        
        self.hashSalt = ((salt == nil) ? @"" : salt);
        self.minHashLength = (minLength > 0) ? minLength : 0;
        self.alphabet = (inAlpha == nil) ? @"xcS4F6h89aUbideAI7tkynuopqrXCgTE5GBKHLMjfRsz" :
            inAlpha;
        self.clearData = [NSMutableArray new];
        self.separators = @"";
        
        NSMutableString *mAlpha = [NSMutableString stringWithString:self.alphabet];
        
        if ( self.alphabet.length < HASHID_MIN_ALPHABET_LENGTH )
            @throw [HashidsException exceptionWithName:@"HashidsAlphabetLengthException"
                                                reason:[NSString stringWithFormat:@"Alphabet is too short, must be %d long", HASHID_MIN_ALPHABET_LENGTH]
                                              userInfo:nil];
        
        if ( [self.alphabet componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].count > 1 )
            @throw [HashidsException exceptionWithName:@"HashidsAlphabetSpaceException"
                                                reason:[NSString stringWithFormat:@"Alphabet is not allowed to have whitespaces"]
                                              userInfo:nil];
        
        // Get the intersection, separators prolly the lower set
        for (NSNumber *prime in self.primes)
        {
            if (prime.intValue - 1 < mAlpha.length) {
                NSString *resAlpha = [mAlpha replaceIndex:prime.intValue-1 withString:@" "];
                self.separators = [self.separators stringByAppendingString:resAlpha];
            }
            
        }
        
        self.alphabet = [mAlpha stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        self.guards = @"";
        
        for (NSNumber *seps in @[@0, @4, @8, @12])
        {
            if (seps.intValue < self.separators.length) {
                unichar guard = [self.separators characterAtIndex:seps.intValue];
                self.guards = [self.guards stringByAppendingFormat:@"%c", guard];
                self.separators = [self.separators stringByReplacingCharactersInRange:NSMakeRange(seps.intValue, 1)
                                                                           withString:@""];
            }
        }
        
        NSLog(@"\n%@\n%@\n%@\n", self.alphabet, self.separators, self.guards);
        self.alphabet = [self consistentShuffle:self.alphabet withSalt:self.hashSalt];
        
    }
    
    return self;
}

- (NSString *) encrypt:(NSNumber *)firstEntry, ... NS_REQUIRES_NIL_TERMINATION
{
    [self.clearData removeAllObjects];
    
    va_list args;
    va_start(args, firstEntry);
    
    NSNumber *arg = nil;
    [self.clearData addObject:firstEntry];
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
    NSMutableString *ret = [NSMutableString stringWithFormat:@"%c", lottery];
    
    for (iter = 0; iter < self.clearData.count; iter++)
    {
        NSString *inputSalt = [NSString stringWithFormat:@"%c%@%@", lottery, self.hashSalt, alphaStr];
        NSNumber *number = ((NSNumber *)[self.clearData objectAtIndex:iter]);
        
        alphaStr = [self consistentShuffle:alphaStr
                             withSalt:[inputSalt substringWithRange:NSMakeRange(0, alphaStr.length)]];
        NSString *last = [self hashNumber:number withAlphabet:alphaStr];
        [ret appendString:last];
        
        if (iter + 1 < self.clearData.count)
        {
            NSUInteger next_num = number.longValue % ((unsigned int)[last characterAtIndex:0]) + 1;
            NSUInteger seps_index = next_num % self.separators.length;
            [ret stringByAppendingFormat:@"%c", [self.separators characterAtIndex:seps_index]];
        }
    
    }
    
    if (ret.length < self.minHashLength)
    {
        NSUInteger guard_index = (numbers_hash_int + ((NSUInteger)[ret characterAtIndex:0])) % self.guards.length;
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
    
    NSMutableString *alpha = [NSMutableString stringWithString:inAlpha];
    
    
    if (salt.length == 0)
        return alpha;
    
    
    NSInteger iter, v = 0, p = 0;
    
    for (iter = alpha.length - 1 ; iter > 0; iter--, v++)
    {
        
        v = v % salt.length;
        NSInteger increment = (NSInteger)[salt characterAtIndex:v];
        p += increment;
        NSInteger j = ( increment + v + p ) % iter;
        
        
        unichar temp = [alpha characterAtIndex:j];
        [alpha replaceCharactersInRange:NSMakeRange(j, 1) withString:[alphabet substringWithRange:NSMakeRange(iter, 1)]];
        [alpha replaceCharactersInRange:NSMakeRange(iter, 1) withString:[NSString stringWithFormat:@"%c", temp]];
        
    }
    
    return alpha;
    
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
