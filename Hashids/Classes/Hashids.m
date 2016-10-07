//
//  Hashids.m
//  Hashids
//
//  Created by Jofell Gallardo on 7/13/13.
//  Copyright (c) 2013 Jofell Gallardo. All rights reserved.
//

#import "Hashids.h"


static NSString * const DEFAULT_ALPHABET = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";
static NSString * const DEFAULT_SEPARATORS = @"cfhistuCFHISTU";
static NSString * const DEFAULT_SALT = @"";

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

-(NSUInteger) indexOf:(unichar)searchChar {
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

        self.hashSalt = ((salt == nil) ? DEFAULT_SALT : salt);
        self.minHashLength = (minLength > 0) ? minLength : 0;
        self.alphabet = (inAlpha == nil) ? DEFAULT_ALPHABET :
            inAlpha;
        self.clearData = [NSMutableArray new];
        self.separators = DEFAULT_SEPARATORS;
        
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
        
        NSMutableString *newSeparators = [separators mutableCopy];
        // Remove all separators from the alphabet. If the separator is not in the alphabet, don't use it
        for (int i = 0; i < separators.length; ++i) {
            unichar c = [separators characterAtIndex:i];
            NSUInteger index = [mAlpha indexOf:c];
            
            if (index == NSNotFound) {
                // separator not in alphabet. Remove char from separators.
                [newSeparators replaceIndex:[newSeparators indexOf:c] withString:@""];
            }else {
                // Remove the separator from the alphabet
                [mAlpha replaceIndex:index withString:@""];
            }
        }
        
        // Update the separators
        self.separators = [self consistentShuffle:newSeparators withSalt:self.hashSalt];
        
        self.alphabet = [mAlpha copy];
        
        double sepDiv = 3.5;
        if (self.separators.length == 0 || ((self.alphabet.length / self.separators.length) > sepDiv)) {
            int seps_len = (int)ceil(self.alphabet.length / sepDiv);
            
            if(seps_len == 1) {
                seps_len++;
            }
            
            if (seps_len > self.separators.length) {
                int diff = seps_len - (int)self.separators.length;
                self.separators = [self.separators stringByAppendingString:[alphabet substringFromIndex:diff]];
                self.alphabet = [alphabet substringToIndex:diff];
            } else {
                self.separators = [self.separators substringToIndex:seps_len];
            }
        }

        self.alphabet = [self consistentShuffle:self.alphabet withSalt:self.hashSalt];

        
        int guardDiv = 12;
        int guardCount = (int)ceil((double)alphabet.length / guardDiv);
        
        if(alphabet.length < 3){
            guards = [separators substringToIndex:guardCount];
            separators = [separators substringFromIndex:guardCount];
        } else {
            guards = [alphabet substringToIndex:guardCount];
            alphabet = [alphabet substringFromIndex:guardCount];
        }
        
    }
    
    return self;
}

#pragma mark -
#pragma mark Encode functions

- (NSString *) encode:(NSNumber *)firstEntry, ... NS_REQUIRES_NIL_TERMINATION
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
    
    return [self encodeValues:self.clearData
                               withAlpha:self.alphabet
                                 andSalt:self.hashSalt];
    
//    return [self ensureLength:[retVal objectAtIndex:0]
//                   withValues:self.clearData
//                  andAlphabet:[retVal objectAtIndex:1]];
 }

- (NSString *) encodeValues:(NSArray *)values
                  withAlpha:(NSString *)inAlpha
                    andSalt:(NSString *)inSalt
{
    int numberHashInt = 0;
    for(int i = 0; i < values.count; i++){
        numberHashInt += ([values[i] intValue] % (i+100));
    }
    unichar ret = [inAlpha characterAtIndex:(numberHashInt % alphabet.length)];

    NSNumber *num;
    int sepsIndex, guardIndex;
    NSString *buffer;
    NSMutableString *ret_str = [NSMutableString stringWithFormat:@"%C", ret];
    unichar guard;
    
    for(int i = 0; i < values.count; i++){
        num = values[i];
        buffer = [NSString stringWithFormat:@"%C%@%@", ret, inSalt, inAlpha];
        
        inAlpha = [self consistentShuffle:inAlpha withSalt:[buffer substringToIndex:inAlpha.length]];
        NSString *last = [self hashNumber:num withAlphabet:inAlpha];
        
        [ret_str appendString:last];
        
        if (i + 1 < values.count){
            num = @([num intValue] % ((int)[last characterAtIndex:0] + i));
            sepsIndex = (int)(num.intValue % separators.length);
            [ret_str appendFormat:@"%C", [separators characterAtIndex:sepsIndex]];
        }
    }
    
    if (ret_str.length < minHashLength){
        guardIndex = (numberHashInt + (int)([ret_str characterAtIndex:0])) % guards.length;
        guard = [guards characterAtIndex:guardIndex];
        
        ret_str = [NSMutableString stringWithFormat:@"%C%@", guard, ret_str];
        
        if(ret_str.length < minHashLength){
            guardIndex = (numberHashInt + (int)([ret_str characterAtIndex:2])) % guards.length;
            guard = [guards characterAtIndex:guardIndex];
            
            [ret_str appendFormat:@"%C", guard];
        }
    }
    
    int halfLen = (int)inAlpha.length / 2;
    while(ret_str.length < minHashLength){
        inAlpha = [self consistentShuffle:inAlpha withSalt:inAlpha];
        ret_str = [NSMutableString stringWithFormat:@"%@%@%@", [inAlpha substringFromIndex:halfLen], ret_str, [inAlpha substringToIndex:halfLen]];
        int excess = (int)ret_str.length - (int)minHashLength;
        if(excess > 0){
            int start_pos = excess / 2;
            
            ret_str = [[ret_str substringWithRange:NSMakeRange(start_pos,  minHashLength)] mutableCopy];
        }
    }
    
    return ret_str;
}

- (NSString *) consistentShuffle:(NSString *)inAlpha
                   withSalt:(NSString *)inSalt
{
    const char* saltArr = [inSalt cStringUsingEncoding:NSASCIIStringEncoding];
    
    int val, j;
    unichar tmp;
    
    for (int i = ((int)inAlpha.length)-1, v = 0, p = 0; i > 0; i--, v++) {
        v %= inSalt.length;
        val = saltArr[v];
        p += val;
        j = (val + v + p) % i;
        
        tmp = [inAlpha characterAtIndex:j];
        inAlpha = [NSString stringWithFormat:@"%@%C%@", [inAlpha substringToIndex:j], [inAlpha characterAtIndex:i], [inAlpha substringFromIndex:j+1]];
        inAlpha = [NSString stringWithFormat:@"%@%C%@", [inAlpha substringToIndex:i], tmp, [inAlpha substringFromIndex:i+1]];

    }
    
    return inAlpha;
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
#pragma mark Decode functions

- (NSArray *) decode:(NSString *) encoded
{
    if (encoded == nil || encoded.length == 0)
        return nil;

    NSArray *parts = [encoded componentsSeparatedByCharactersInSet:
                      [NSCharacterSet characterSetWithCharactersInString:self.guards]];
    NSString *hashid = nil;
    if (parts.count == 2 || parts.count == 3)
        hashid = [parts objectAtIndex:1];
    else
        hashid = [parts objectAtIndex:0];
    
    unichar lottery_char = [hashid characterAtIndex:0];
    
    hashid = [hashid substringFromIndex:1];
    NSArray *hash_parts = [hashid componentsSeparatedByCharactersInSet:
                           [NSCharacterSet characterSetWithCharactersInString:self.separators]];
    
    NSString *inAlpha = alphabet;
    NSString *buffer;
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:hash_parts.count];
    
    for (NSString *subhash in hash_parts) {
        if (lottery_char && inAlpha != nil && inAlpha.length > 0)
        {
            buffer = [NSString stringWithFormat:@"%C%@%@", lottery_char, hashSalt, inAlpha];
            inAlpha = [self consistentShuffle:inAlpha withSalt:[buffer substringToIndex:inAlpha.length]];
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
