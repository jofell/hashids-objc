//
//  Hashids.h
//  Hashids
//
//  Created by Jofell Gallardo on 7/13/13.
//  Copyright (c) 2013 Jofell Gallardo. All rights reserved.
//

#import <Foundation/Foundation.h>

#define HASHID_MIN_ALPHABET_LENGTH 4
#define HASHID_SEP_DIV 3.5
#define HASHID_GUARD_DIV 12
#define HASHID_MAX_INT_VALUE 1000000000

@interface HashidsException : NSException
@end

@interface NSMutableString (Hashids)

- (NSString *) replaceIndex:(NSInteger)index withString:(NSString *)replaceString;

@end

@interface Hashids : NSObject

+ (id)hashidWithSalt:(NSString *) salt;

+ (id)hashidWithSalt:(NSString *) salt
        andMinLength:(NSInteger)minLength;

+ (id)hashidWithSalt:(NSString *) salt
           minLength:(NSInteger) minLength
            andAlpha:(NSString *) alphabet;

- (id)initWithSalt:(NSString *) salt
         minLength:(NSInteger) minLength
          andAlpha:(NSString *) alphabet;

- (NSString *) encrypt:(NSNumber *)firstEntry, ... NS_REQUIRES_NIL_TERMINATION;
- (NSArray *) decrypt:(NSString *) encoded;


@end
