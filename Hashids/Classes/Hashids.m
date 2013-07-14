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
#pragma mark NSNumber's lottery value

@interface NSNumber (Hashids)

- (NSNumber *) lotteryValue;

@end


@implementation NSNumber (Hashids)

- (NSNumber *) lotteryValue
{
    return [NSNumber numberWithLong:(self.longValue + 1) * 2];
}

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

@implementation NSString (Haashids)

-(NSUInteger) indexOf:(char) searchChar {
    NSRange searchRange;
    searchRange.location=(unsigned int)searchChar;
    searchRange.length=1;
    NSRange foundRange = [self rangeOfCharacterFromSet:[NSCharacterSet characterSetWithRange:searchRange]];
    return foundRange.location;
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

#pragma mark -
#pragma mark Init functions


+ (id)hashidWithSalt:(NSString *) salt
{
    return [[Hashids alloc] initWithSalt:salt
                               minLength:0
                                andAlpha:nil];
}

+ (id)hashidWithSalt:(NSString *) salt
        andMinLength:(NSInteger)minLength
{
    return [[Hashids alloc] initWithSalt:salt
                               minLength:minLength
                                andAlpha:nil];
}

+ (id)hashidWithSalt:(NSString *) salt
           minLength:(NSInteger) minLength
            andAlpha:(NSString *) alphabet
{
    return [[Hashids alloc] initWithSalt:salt
                               minLength:minLength
                                andAlpha:alphabet];
}



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
                                                reason:[NSString stringWithFormat:
                                                        @"Alphabet is too short, must be %d long",
                                                        HASHID_MIN_ALPHABET_LENGTH]
                                              userInfo:nil];
        
        if ( [self.alphabet componentsSeparatedByCharactersInSet:
                                [NSCharacterSet whitespaceAndNewlineCharacterSet]].count > 1 )
            @throw [HashidsException exceptionWithName:@"HashidsAlphabetSpaceException"
                                                reason:[NSString stringWithFormat:
                                                        @"Alphabet is not allowed to have whitespaces"]
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
        
        self.alphabet = [self consistentShuffle:self.alphabet withSalt:self.hashSalt];
        
    }
    
    return self;
}

#pragma mark -
#pragma mark Ecrypt functions

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
    
    if (self.clearData.count == 0) return nil;
    
    NSArray *retVal = [self encodeValues:self.clearData
                               withAlpha:self.alphabet
                                 andSalt:self.hashSalt];
    
    return [self ensureLength:[retVal objectAtIndex:0]
                   withValues:self.clearData
                  andAlphabet:[retVal objectAtIndex:1]];
 }

- (NSArray *) encodeValues:(NSArray *)values
                  withAlpha:(NSString *)inAlpha
                    andSalt:(NSString *)inSalt
{
    NSString *alphaStr = [NSString stringWithString:inAlpha];
    
    NSString *inSep = [self consistentShuffle:self.separators
                                     withSalt:[values componentsJoinedByString:@""]];
    
    // For lottery salt, iterate on the string and append as you go
    NSString *lotterySaltPre = [values componentsJoinedByString:@"-"];
    NSString *lotterySaltSuf = [[values valueForKey:@"lotteryValue"] componentsJoinedByString:@"-"];
    
    NSString *newOrder = [self consistentShuffle:alphaStr
                                        withSalt:[NSString stringWithFormat:@"%@-%@",
                                                  lotterySaltPre, lotterySaltSuf]];
    
    
    unichar lotteryChar = [newOrder characterAtIndex:0];

    NSString *hashed = [NSString stringWithFormat:@"%c", lotteryChar];
    NSString *newAlpha = [alphaStr stringByReplacingOccurrencesOfString:hashed
                                                             withString:@""];
    
    newAlpha = [NSString stringWithFormat:@"%c%@", lotteryChar, newAlpha];
    
    NSInteger i = 0;
    for (; i < values.count; i++) {
        
        NSNumber *value = [values objectAtIndex:i];
        NSString *alpha_salt = [NSString stringWithFormat:@"%ld%@", ((long)lotteryChar) & 12345, inSalt];
        newAlpha = [self consistentShuffle:newAlpha withSalt:alpha_salt];
        
        NSString *currHash = [self hashNumber:value withAlphabet:newAlpha];
        hashed = [hashed stringByAppendingString:currHash];
        
        if (i < values.count - 1) {
            hashed = [hashed stringByAppendingFormat:@"%c",
                      [inSep characterAtIndex:(value.intValue + i) % inSep.length]];
        }
    }
    return @[hashed, newAlpha];
    
}

- (NSString *) consistentShuffle:(NSString *)inAlpha
                   withSalt:(NSString *)inSalt
{
    
    NSString *salt = [NSString stringWithString:inSalt];
    NSMutableString *alpha = [inAlpha mutableCopy];
    
    NSString *toReturn = @"";
    
    NSMutableArray *sorting = [NSMutableArray arrayWithCapacity:inSalt.length];
    NSInteger i;
    
    for ( i = 0; i < salt.length; i++ )
        [sorting addObject:[NSNumber numberWithInteger:(NSInteger)[salt characterAtIndex:i]]];
    
    NSInteger len_sorting = sorting.count;
    
    if (len_sorting == 0) [sorting addObject:[NSNumber numberWithInteger:0]];
    len_sorting = sorting.count;
    
    for ( i = 0; i < len_sorting; i++ )
    {
        BOOL add = YES;
        NSInteger k;
        for ( k = i; k < (len_sorting + i - 1); k++ )
        {
            NSInteger diff = ((NSNumber *)[sorting objectAtIndex:((k+1) % len_sorting)]).intValue;
            NSInteger toIns = (((NSNumber *)[sorting objectAtIndex:i]).intValue) - diff;
            if (add) toIns = ((NSNumber *)[sorting objectAtIndex:i]).intValue + diff + (k * i);
            [sorting replaceObjectAtIndex:i withObject:[NSNumber numberWithInteger:toIns]];
            add = !add;
        }
        
        int currSortval = ((NSNumber *)[sorting objectAtIndex:i]).intValue;
        [sorting replaceObjectAtIndex:i withObject:@(abs(currSortval))];
        
    }
    
    i = -1;
    
    while ( alpha.length > 0 )
    {
        i = (i + 1) % len_sorting;
        NSInteger pos = ((NSNumber *)[sorting objectAtIndex:i]).intValue % alpha.length;
        toReturn = [toReturn stringByAppendingFormat:@"%c", [alpha characterAtIndex:pos]];
        [alpha replaceIndex:pos withString:@""];
    }
    
    return toReturn;
    
}

- (NSString *) ensureLength:(NSString *)hashid
                 withValues:(NSArray *)values
                andAlphabet:(NSString *)inAlpha
{
    NSInteger length = self.minHashLength;
    NSString *salt = [NSString stringWithString:self.hashSalt];
    NSInteger hashLength = hashid.length;
    
    
    if (hashLength < length)
    {
        NSInteger i = 0, sum = 0;
        for (; i < self.clearData.count; i++)
            sum += ((NSNumber *)[self.clearData objectAtIndex:i]).intValue * (i + 1);
        
        NSInteger guard_index = sum % self.guards.length;
        hashid = [NSString stringWithFormat:@"%c%@",
                                            [self.guards characterAtIndex:guard_index],
                                            hashid];
        hashLength++;
        
        if (hashLength < length)
        {
            hashid = [hashid stringByAppendingFormat:@"%c",
                      [guards characterAtIndex:(guard_index + hashLength) % guards.length]];
            hashLength++;
        }
            
    }
    
    
    while (hashLength < length)
    {
        NSArray *pad = @[ @((NSInteger)[inAlpha characterAtIndex:1]),
                          @((NSInteger)[inAlpha characterAtIndex:0])] ;
        
        NSString *padLeft = [[self encodeValues:pad
                                      withAlpha:inAlpha
                                        andSalt:salt] objectAtIndex:0];
        NSString *padRight = [[self encodeValues:pad
                                       withAlpha:inAlpha
                                         andSalt:[pad componentsJoinedByString:@""]] objectAtIndex:0];
        
        hashid = [NSString stringWithFormat:@"%@%@%@", padLeft, hashid, padRight];
        hashLength = hashid.length;
        NSInteger excess = hashLength - length;
        if (excess > 0)
        {
            hashid = [hashid substringFromIndex:(NSInteger)(excess / 2)];
            hashid =[hashid substringToIndex:hashid.length - (NSInteger)(excess / 2)];
        }
        
        inAlpha = [self consistentShuffle:inAlpha withSalt:[salt stringByAppendingString:hashid]];
        
    }
    
    return hashid;
}

- (NSString *) hashNumber:(NSNumber *)numberIn withAlphabet:(NSString *)inAlpha
{
    NSMutableString *hashStr = [NSMutableString stringWithString:@""];
    NSInteger alphabet_length = inAlpha.length;
    long input_val = numberIn.longValue;
    
    do
    {
        unichar to_prepend = [inAlpha characterAtIndex:input_val % alphabet_length];
        hashStr = [NSMutableString stringWithFormat:@"%c%@", to_prepend, hashStr];
        
        input_val = (long)(input_val / alphabet_length);
        
    } while (input_val);
    
    return hashStr;
}

#pragma mark -
#pragma mark Decrypt functions

- (NSArray *) decrypt:(NSString *) encoded
{
    if (encoded == nil || encoded.length == 0)
        return nil;
    
    return [self decode:encoded];
}


- (NSArray *) decode:(NSString *) encoded
{
    NSArray *parts = [encoded componentsSeparatedByCharactersInSet:
                      [NSCharacterSet characterSetWithCharactersInString:self.guards]];
    NSString *hashid = nil;
    if (parts.count == 2 || parts.count == 3)
        hashid = [parts objectAtIndex:1];
    else
        hashid = [parts objectAtIndex:0];
    
    unichar lottery_char = 0;
    
    NSArray *hash_parts = [hashid componentsSeparatedByCharactersInSet:
                           [NSCharacterSet characterSetWithCharactersInString:self.separators]];
    
    NSInteger i = 0;
    NSString *inAlpha = nil;
    
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:hash_parts.count];
    
    for (; i < hash_parts.count; i++) {
        NSString *subhash = [hash_parts objectAtIndex:i];
        if (i == 0)
        {
            lottery_char = [hashid characterAtIndex:0];
            subhash = [subhash substringFromIndex:1];
            inAlpha = [NSString stringWithFormat:@"%c%@", lottery_char,
                        [self.alphabet stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%c", lottery_char]
                                                                 withString:@""]];
        }
        
        if (lottery_char && inAlpha != nil && inAlpha.length > 0)
        {
            NSString *salt = [NSString stringWithFormat:@"%d%@", (lottery_char & 12345), self.hashSalt];
            inAlpha = [self consistentShuffle:inAlpha withSalt:salt];
            [results addObject:[self unhash:subhash withAlpha:inAlpha]];
        }
        
    }
    
    return results;
}

- (NSNumber *) unhash:(NSString *)currHash
            withAlpha:(NSString *)inAlpha
{
    NSInteger number = 0;
    NSInteger hashLength = currHash.length;
    NSInteger alphaLength = inAlpha.length;
    NSInteger i = 0;
    for (; i < hashLength; i++) {
        unichar charToFind = [currHash characterAtIndex:i];
        NSUInteger position = [inAlpha indexOf:(char)charToFind];
        if (position == NSNotFound)
            return nil;
        number += position * ((NSInteger) pow(alphaLength, (hashLength - i - 1)));
    }
    
    return @(number);
}

@end
