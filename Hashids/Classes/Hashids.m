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

#pragma -
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
        
        self.alphabet = [self consistentShuffle:self.alphabet withSalt:self.hashSalt];
        NSLog(@"\n%@\n%@\n%@", self.alphabet, self.separators, self.guards);
        
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
    
    NSString *inSep = [self consistentShuffle:self.separators
                                          withSalt:[self.clearData componentsJoinedByString:@""]];
    
    
    // For lottery salt, iterate on the string and append as you go
    NSString *lotterySaltPre = [self.clearData componentsJoinedByString:@"-"];
    NSString *lotterySaltSuf = [[self.clearData valueForKey:@"lotteryValue"] componentsJoinedByString:@"-"];
    
    NSString *newOrder = [self consistentShuffle:alphaStr
                                        withSalt:[NSString stringWithFormat:@"%@-%@",
                                                  lotterySaltPre, lotterySaltSuf]];
    
    unichar lotteryChar = [newOrder characterAtIndex:0];
    NSString *hashed = [NSString stringWithFormat:@"%c", lotteryChar];
    NSString *newAlpha = [alphaStr stringByReplacingOccurrencesOfString:hashed
                                                             withString:@""];
    newAlpha = [NSString stringWithFormat:@"%c%@", lotteryChar, alphaStr];
    
    NSInteger i = 0;
    for (; i < self.clearData.count; i++) {
        
        NSNumber *value = [self.clearData objectAtIndex:i];
        NSString *alpha_salt = [NSString stringWithFormat:@"%ld%@", ((long)lotteryChar) & 12345, self.hashSalt];
        newAlpha = [self consistentShuffle:newAlpha withSalt:alpha_salt];
        NSString *currHash = [self hashNumber:value withAlphabet:newAlpha];
        hashed = [hashed stringByAppendingFormat:currHash];
        
        if (i < self.clearData.count - 1) {
            hashed = [hashed stringByAppendingFormat:@"%c",
                      [inSep characterAtIndex:(value.intValue + i) % inSep.length]];
        }
    }
    
    return hashed;
}

- (NSDictionary *) consistentShuffle:(NSString *)inAlpha
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
    
    for ( i = 0; i < len_sorting; i++ )
    {
        BOOL add = YES;
        NSInteger k;
        for ( k = i; k < len_sorting + i - 1; k++ )
        {
            NSInteger diff = ((NSNumber *)[sorting objectAtIndex:((k+1) % len_sorting)]).intValue;
            NSInteger toIns = (add ? ((NSNumber *)[sorting objectAtIndex:i]).intValue + diff + (k * i) : -1 * diff);
            [sorting replaceObjectAtIndex:i withObject:[NSNumber numberWithInteger:toIns]];
            add = !add;
        }
        
        int currSortval = ((NSNumber *)[sorting objectAtIndex:i]).intValue;
        [sorting replaceObjectAtIndex:i withObject:[NSNumber numberWithInteger:abs(currSortval)]];
        
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

- (NSArray *) decrypt:(NSString *) encoded
{
    NSArray *toReturn = nil;
    
    
    
    return toReturn;
}


@end
