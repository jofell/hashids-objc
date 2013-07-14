hashids-objc
============

Hashids Implementation for Objective C

Website: [http://www.hashids.org](http://www.hashids.org)

Generate short hashes from unsigned integers (like YouTube and Bitly).

* obfuscate database IDs
* use them as forgotten password hashes
* invitation codes
* store shard numbers

Hashids was designed for use in URL shortening, tracking stuff, validating accounts, or making pages private. Instead of showing items as `1`, `2`, or `3`, you could show them as `b9iLXiAa`, `EATedTBy`, and `Aaco9cy5`. Hashes depend on your salt value as well.


Usage
=====

Installation
------------

You can install Hashids for Objective-C by downloading the files from the repository at [http://www.github.com/jofell/hashids-objc](http://www.github.com/jofell/hashids-objc). You can do either of the following:

* Download the zipped archive of the repository (check out the "Download as Zip" button on the right sidebar)
* Clone the repository by running:

    git clone https://github.com/jofell/hashids-objc.git

After you get access to the files from the repository, go to the folder `hashids-objc/Hashids/Classes` and add all the class files to your XCode project.

Basic Usage
-----------

As soon as you add the class files onto your XCode Project, just import Hashids to your Objective-C Source Codes.

```objectivec
    
    #import "Hashids.h"
    
```

Then create an instance of the `Hashids` class.

```objectivec
    
    Hashids *hashid = [Hashids new];
    
```

To encrypt a single integer:

```objectivec
    
    NSString *hash = [hashids encrypt:@123, nil]; // @"AjL"
    
```

Take note that as opposed to other hashids implmentations, you are to use an `NSNumber` instance as parameter for encryption. Also take note that the parameter is `nil` terminated, which means the `encrypt:` call can take an arbitrary number of parameters to it, like so:

```objectivec
    
    NSString *hash = [hashids encrypt:@123, @456, @789, nil]; // @"qa9t96h7G"
    
```

To decrypt an NSString hash:

```objectivec
    
    NSArray *ints = [hashids decrypt:@"qa9t96h7G"]; // @[ @123, @456, @789 ]
    
```

Note that this call only returns an instance of NSArray. This is to have a more consistent return value for this method.


Customising Hashes
------------------

Hashids supports personalizing your hashes by accepting a salt value, a minimum hash length, and a custom alphabet. Here is how you can customise your hashes:

```objectivec
    
    Hashids *hasher = [[Hashids alloc] initWithSalt:@"this is my salt"
                                          minLength:8
                                           andAlpha:myAlpha];
                                           
```                                     

In general, you can customise your hashes by providing any of the three parameters stated above. Salts and alphabets are `nil`, while hash lengths have a minimum of 0 by default, i.e. when you allocate `Hashids` instances via `new` or `init`. Below are examples to customise solely on these three parameters

### Using Custom Salt ###

```objectivec
    
    Hashids *hasher = [Hashids hashidWithSalt:@"this is my salt 1"];
    [hasher encrypt:@123, nil]; // @"rnR"
                                         
```

The generated hash changes whenever the salt is changed.

```objectivec
    
    Hashids *hasher = [Hashids hashidWithSalt:@"this is my salt 2"];
    [hasher encrypt:@123, nil]; // @"XBn"
                                     
```

A salt string between 6 and 32 characters provides decent randomization.

### Controlling Hash Length ###

By default, hashes are going to be the shortest possible. One reason you might want to increase the hash length is to obfuscate how large the integer behind the hash is.

This is done by passing the minimum hash length to the `init` call. Hashes are padded with extra characters to make them seem longer.

```objectivec
    
    Hashids *hasher = [Hashids hashidWithSalt:@"this is my salt" 
                                 andMinLength:16];
    [hasher encrypt:@1, nil]; // @"AA6Fb9iLXiAaBFB5"
                                            
```

### Using Custom Alphabet ###

It’s possible to set a custom alphabet for your hashes. The default alphabet is `@"xcS4F6h89aUbideAI7tkynuopqrXCgTE5GBKHLMjfRsz"`.

To have only lowercase letters in your hashes, pass in the following custom alphabet:

```objectivec
    
    Hashids *hasher = [Hashids hashidWithSalt:@"this is my salt" 
                                    minLength:16
                                     andAlpha:@"abcdefghijklmnopqrstuvwxyz"];
    [hasher encrypt:@123456789, nil]; // @"zdrnoaor"
     
```

$#!7 Stuff
----------

This code was written with the intent of placing generated hashes in visible places – like the URL.

Therefore, the algorithm tries to avoid generating most common English curse words by never placing the following letters next to each other: `c, C, s, S, f, F, h, H, u, U, i, I, t, T`.


Collisions
----------

There are no collisions. Your generated hashes should be unique.

Decryptable Hash ¿qué?
----------------------

A true cryptographic hash cannot be decrypted. However, to keep things simple the word hash is used loosely to refer to the random set of characters that are generated. Like a YouTube hash.