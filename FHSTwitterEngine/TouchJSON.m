//
//  TouchJSON.m
//  TouchCode
//
//  Created by Jonathan Wight on 12/08/2005.
//  Copyright 2005 toxicsoftware.com. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

#import "TouchJSON.h"

#define LF 0x000a // Line Feed
#define FF 0x000c // Form Feed
#define CR 0x000d // Carriage Return
#define NEL 0x0085 // Next Line
#define LS 0x2028 // Line Separator
#define PS 0x2029 // Paragraph Separator

#if !defined(TREAT_COMMENTS_AS_WHITESPACE)
#define TREAT_COMMENTS_AS_WHITESPACE 0
#endif // !defined(TREAT_COMMENTS_AS_WHITESPACE)

NSString *const kJSONDeserializerErrorDomain  = @"CJSONDeserializerErrorDomain";
NSString *const kJSONScannerErrorDomain = @"kJSONScannerErrorDomain";

inline static int HexToInt(char inCharacter) {
    int theValues[] = { 0x0 /* 48 '0' */, 0x1 /* 49 '1' */, 0x2 /* 50 '2' */, 0x3 /* 51 '3' */, 0x4 /* 52 '4' */, 0x5 /* 53 '5' */, 0x6 /* 54 '6' */, 0x7 /* 55 '7' */, 0x8 /* 56 '8' */, 0x9 /* 57 '9' */, -1 /* 58 ':' */, -1 /* 59 ';' */, -1 /* 60 '<' */, -1 /* 61 '=' */, -1 /* 62 '>' */, -1 /* 63 '?' */, -1 /* 64 '@' */, 0xa /* 65 'A' */, 0xb /* 66 'B' */, 0xc /* 67 'C' */, 0xd /* 68 'D' */, 0xe /* 69 'E' */, 0xf /* 70 'F' */, -1 /* 71 'G' */, -1 /* 72 'H' */, -1 /* 73 'I' */, -1 /* 74 'J' */, -1 /* 75 'K' */, -1 /* 76 'L' */, -1 /* 77 'M' */, -1 /* 78 'N' */, -1 /* 79 'O' */, -1 /* 80 'P' */, -1 /* 81 'Q' */, -1 /* 82 'R' */, -1 /* 83 'S' */, -1 /* 84 'T' */, -1 /* 85 'U' */, -1 /* 86 'V' */, -1 /* 87 'W' */, -1 /* 88 'X' */, -1 /* 89 'Y' */, -1 /* 90 'Z' */, -1 /* 91 '[' */, -1 /* 92 '\' */, -1 /* 93 ']' */, -1 /* 94 '^' */, -1 /* 95 '_' */, -1 /* 96 '`' */, 0xa /* 97 'a' */, 0xb /* 98 'b' */, 0xc /* 99 'c' */, 0xd /* 100 'd' */, 0xe /* 101 'e' */, 0xf /* 102 'f' */, };
    if (inCharacter >= '0' && inCharacter <= 'f') {
        return (theValues[inCharacter - '0']);
    } else {
        return -1;
    }
}

static id kNSYES = nil;
static id kNSNO = nil;
static NSData *kNULL = nil;
static NSData *kFalse = nil;
static NSData *kTrue = nil;

inline static unichar CharacterAtPointer(void *start) {
    const u_int8_t theByte = *(u_int8_t *)start;
    if (theByte & 0x80) {
        // TODO -- UNICODE!!!! (well in theory nothing todo here)
    }
    const unichar theCharacter = theByte;
    return theCharacter;
}

static NSCharacterSet *sDoubleCharacters = nil;




@implementation CDataScanner

- (id)init {
    self = [super init];
    return self;
}

- (id)initWithData:(NSData *)inData {
    self = [super init];
    if (self) {
        [self setData:inData];
    }
    return(self);
}

+ (void)initialize {
    if (sDoubleCharacters == nil) {
        sDoubleCharacters = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789eE-+."]retain];
    }
}

- (void)dealloc {
    [data release];
    data = nil;
    [super dealloc];
}

- (NSUInteger)scanLocation
{
    return (current-start);
}

- (NSUInteger)bytesRemaining
{
    return (end-current);
}

- (NSData *)data {
    return data;
}

- (void)setData:(NSData *)inData {
    
    //if (data != inData) {
    if (![data isEqualToData:inData]) {
        [data release];
        data = [inData retain];
    }
    
    if (data) {
        start = (u_int8_t *)data.bytes;
        end = start + data.length;
        current = start;
        length = data.length;
    } else {
        start = nil;
        end = nil;
        current = nil;
        length = 0;
    }
}

- (void)setScanLocation:(NSUInteger)inScanLocation
{
    current = start + inScanLocation;
}

- (BOOL)isAtEnd
{
    return (self.scanLocation >= length);
}

- (unichar)currentCharacter
{
    return CharacterAtPointer(current);
}

#pragma mark -

- (unichar)scanCharacter {
    const unichar theCharacter = CharacterAtPointer(current++);
    return theCharacter ;
}

- (BOOL)scanCharacter:(unichar)inCharacter {
    unichar theCharacter = CharacterAtPointer(current);
    if (theCharacter == inCharacter) {
        ++current;
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)scanUTF8String:(const char *)inString intoString:(NSString **)outValue {
    const size_t theLength = strlen(inString);
    if ((size_t)(end - current) < theLength) {
        return NO;
    }

    if (strncmp((char *)current, inString, theLength) == 0) {
        current += theLength;
        if (outValue) {
            *outValue = [NSString stringWithUTF8String:inString];
        }
        return YES;
    }
    return NO;
}

- (BOOL)scanString:(NSString *)inString intoString:(NSString **)outValue {
    
    if ((size_t)(end - current) < inString.length) {
        return NO;
    }

    if (strncmp((char *)current, [inString UTF8String], inString.length) == 0) {
        current += inString.length;
        if (outValue) {
            *outValue = inString;
        }
        return YES;
    }
    
    return NO;
}

- (BOOL)scanCharactersFromSet:(NSCharacterSet *)inSet intoString:(NSString **)outValue
{
    u_int8_t *P;
    for (P = current; P < end && [inSet characterIsMember:*P] == YES; ++P);
    
    if (P == current) {
        return NO;
    }
    
    if (outValue) {
        *outValue = [[[NSString alloc]initWithBytes:current length:P - current encoding:NSUTF8StringEncoding]autorelease];
    }
    
    current = P;
    
    return YES;
}

- (BOOL)scanUpToString:(NSString *)inString intoString:(NSString **)outValue {
    const char *theToken = [inString UTF8String];
    const char *theResult = strnstr((char *)current, theToken, end - current);
    
    if (theResult == nil){
        return NO;
    }
    
    if (outValue) {
        *outValue = [[[NSString alloc]initWithBytes:current length:theResult - (char *)current encoding:NSUTF8StringEncoding]autorelease];
    }
    
    current = (u_int8_t *)theResult;
    
    return(YES);
}

- (BOOL)scanUpToCharactersFromSet:(NSCharacterSet *)inSet intoString:(NSString **)outValue {
    u_int8_t *P;
    for (P = current; P < end && [inSet characterIsMember:*P] == NO; ++P);
    
    if (P == current) {
        return NO;
    }
    
    if (outValue) {
        *outValue = [[[NSString alloc]initWithBytes:current length:P - current encoding:NSUTF8StringEncoding]autorelease];
    }
    
    current = P;
    
    return YES;
}

- (BOOL)scanNumber:(NSNumber **)outValue {
    
    NSString *theString = nil;
    
    if ([self scanCharactersFromSet:sDoubleCharacters intoString:&theString]) {
        if ([theString rangeOfString:@"."].location != NSNotFound) {
            if (outValue) {
                *outValue = [NSDecimalNumber decimalNumberWithString:theString];
            }
            return YES;
        } else if ([theString rangeOfString:@"-"].location != NSNotFound) {
            if (outValue != nil) {
                *outValue = [NSNumber numberWithLongLong:[theString longLongValue]];
            }
            return YES;
        } else {
            if (outValue != nil) {
                *outValue = [NSNumber numberWithUnsignedLongLong:strtoull([theString UTF8String], NULL, 0)];
            }
            return YES;
        }
        
    }
    return NO;
}

- (BOOL)scanDecimalNumber:(NSDecimalNumber **)outValue {
    NSString *theString = nil;
    if ([self scanCharactersFromSet:sDoubleCharacters intoString:&theString]) {
        if (outValue) {
            *outValue = [NSDecimalNumber decimalNumberWithString:theString];
        }
        return YES;
    }
    return NO;
}

- (BOOL)scanDataOfLength:(NSUInteger)inLength intoPointer:(void **)outPointer {
    if (self.bytesRemaining < inLength) {
        return NO;
    }
    
    if (outPointer) {
        *outPointer = current;
    }
    
    current += inLength;
    return YES;
}

- (BOOL)scanDataOfLength:(NSUInteger)inLength intoData:(NSData **)outData {
    if (self.bytesRemaining < inLength) {
        return NO;
    }
    
    if (outData) {
        *outData = [NSData dataWithBytes:current length:inLength];
    }
    
    current += inLength;
    return YES;
}

- (void)skipWhitespace {
    u_int8_t *P;
    for (P = current; P < end && (isspace(*P)); ++P);
    current = P;
}

- (NSString *)remainingString {
    NSData *theRemainingData = [NSData dataWithBytes:current length:end - current];
    return [[[NSString alloc]initWithData:theRemainingData encoding:NSUTF8StringEncoding]autorelease];
}

- (NSData *)remainingData; {
    return [NSData dataWithBytes:current length:end - current];
}

@end

@interface CJSONScanner ()
- (BOOL)scanNotQuoteCharactersIntoString:(NSString **)outValue;
- (NSError *)error:(NSInteger)inCode description:(NSString *)inDescription;
@end

@implementation CJSONScanner

@synthesize strictEscapeCodes;
@synthesize nullObject;
@synthesize allowedEncoding;
@synthesize options;

+ (void)initialize
{
    NSAutoreleasePool *thePool = [[NSAutoreleasePool alloc] init];
    
    if (kNSYES == nil) {
        kNSYES = [NSNumber numberWithBool:YES];
    }
    
    if (kNSNO == nil) {
        kNSNO = [NSNumber numberWithBool:NO];
    }
    
    [thePool release];
}

- (id)init {
    
    self = [super init];
    
    if (self) {
        strictEscapeCodes = NO;
        nullObject = [[NSNull null] retain];
    }
    
    return self;
}

- (void)dealloc {
    [nullObject release];
    nullObject = NULL;
    [super dealloc];
}

#pragma mark -

- (BOOL)setData:(NSData *)inData error:(NSError **)outError {
    NSData *theData = inData;
    if (theData && theData.length >= 4) {
        // This code is lame, but it works. Because the first character of any JSON string will always be a (ascii) control character we can work out the Unicode encoding by the bit pattern. See section 3 of http://www.ietf.org/rfc/rfc4627.txt
        const char *theChars = theData.bytes;
        NSStringEncoding theEncoding = NSUTF8StringEncoding;
        if (theChars[0] != 0 && theChars[1] == 0) {
            if (theChars[2] != 0 && theChars[3] == 0) {
                theEncoding = NSUTF16LittleEndianStringEncoding;
            } else if (theChars[2] == 0 && theChars[3] == 0) {
                theEncoding = NSUTF32LittleEndianStringEncoding;
            }
        } else if (theChars[0] == 0 && theChars[2] == 0 && theChars[3] != 0) {
            if (theChars[1] == 0) {
                theEncoding = NSUTF32BigEndianStringEncoding;
            } else if (theChars[1] != 0) {
                theEncoding = NSUTF16BigEndianStringEncoding;
            }
        }
        
        NSString *theString = [[NSString alloc]initWithData:theData encoding:theEncoding];
        if (theString == nil && self.allowedEncoding != 0) {
            theString = [[NSString alloc]initWithData:theData encoding:self.allowedEncoding];
        }
        theData = [theString dataUsingEncoding:NSUTF8StringEncoding];
        [theString release];
    }
    
    if (theData) {
        [super setData:theData];
        return YES;
    } else {
        if (outError) {
            *outError = [self error:kJSONScannerErrorCode_CouldNotDecodeData description:@"Could not scan data. Data wasn't encoded properly?"];
        }
        return NO;
    }
}

- (void)setData:(NSData *)inData
{
    [self setData:inData error:nil];
}

- (BOOL)scanJSONObject:(id *)outObject error:(NSError **)outError {
    BOOL theResult = YES;
    
    [self skipWhitespace];
    
    id theObject = nil;
    
    const unichar C = [self currentCharacter];
    switch (C)
    {
        case 't':
            if ([self scanUTF8String:"true" intoString:nil]) {
                theObject = kNSYES;
            }
            break;
        case 'f':
            if ([self scanUTF8String:"false" intoString:nil]) {
                theObject = kNSNO;
            }
            break;
        case 'n':
            if ([self scanUTF8String:"null" intoString:nil]) {
                theObject = self.nullObject;
            }
            break;
        case '\"':
        case '\'':
            theResult = [self scanJSONStringConstant:&theObject error:outError];
            break;
        case '0':
        case '1':
        case '2':
        case '3':
        case '4':
        case '5':
        case '6':
        case '7':
        case '8':
        case '9':
        case '-':
            theResult = [self scanJSONNumberConstant:&theObject error:outError];
            break;
        case '{':
            theResult = [self scanJSONDictionary:&theObject error:outError];
            break;
        case '[':
            theResult = [self scanJSONArray:&theObject error:outError];
            break;
        default:
            theResult = NO;
            if (outError) {
                *outError = [self error:kJSONScannerErrorCode_CouldNotScanObject description:@"Could not scan object. Character not a valid JSON character."];
                NSMutableDictionary *theUserInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"Could not scan object. Character not a valid JSON character.", NSLocalizedDescriptionKey, nil];
                [theUserInfo addEntriesFromDictionary:self.userInfoForScanLocation];
                *outError = [NSError errorWithDomain:kJSONScannerErrorDomain code:kJSONScannerErrorCode_CouldNotScanObject userInfo:theUserInfo];
            }
            break;
    }
    
    if (outObject != nil) {
        *outObject = theObject;
    }
    
    return theResult;
}

- (BOOL)scanJSONDictionary:(NSDictionary **)outDictionary error:(NSError **)outError {
    
    NSUInteger theScanLocation = [self scanLocation];
    
    [self skipWhitespace];
    
    if ([self scanCharacter:'{'] == NO) {
        if (outError) {
            *outError = [self error:kJSONScannerErrorCode_DictionaryStartCharacterMissing description:@"Could not scan dictionary. Dictionary that does not start with '{' character."];
        }
        return NO;
    }
    
    NSMutableDictionary *theDictionary = [[NSMutableDictionary alloc] init];
    
    while ([self currentCharacter] != '}') {
        [self skipWhitespace];
        
        if ([self currentCharacter] == '}') {
            break;
        }
        
        NSString *theKey = nil;
        if ([self scanJSONStringConstant:&theKey error:outError] == NO) {
            [self setScanLocation:theScanLocation];
            if (outError) {
                *outError = [self error:kJSONScannerErrorCode_DictionaryKeyScanFailed description:@"Could not scan dictionary. Failed to scan a key."];
            }
            [theDictionary release];
            return NO;
        }
        
        [self skipWhitespace];
        
        if ([self scanCharacter:':'] == NO) {
            [self setScanLocation:theScanLocation];
            if (outError) {
                *outError = [self error:kJSONScannerErrorCode_DictionaryKeyNotTerminated description:@"Could not scan dictionary. Key was not terminated with a ':' character."];
            }
            [theDictionary release];
            return NO;
        }
        
        id theValue = nil;
        if ([self scanJSONObject:&theValue error:outError] == NO) {
            [self setScanLocation:theScanLocation];
            if (outError) {
                *outError = [self error:kJSONScannerErrorCode_DictionaryValueScanFailed description:@"Could not scan dictionary. Failed to scan a value."];
            }
            [theDictionary release];
            return NO;
        }
        
        if (theValue == nil && self.nullObject == nil) {
            // If the value is a null and nullObject is also null then we're skipping this key/value pair.
        } else {
            [theDictionary setValue:theValue forKey:theKey];
        }
        
        [self skipWhitespace];
        if ([self scanCharacter:','] == NO) {
            if ([self currentCharacter] != '}') {
                [self setScanLocation:theScanLocation];
                if (outError) {
                    *outError = [self error:kJSONScannerErrorCode_DictionaryKeyValuePairNoDelimiter description:@"Could not scan dictionary close delimiter."];
                }
                [theDictionary release];
                return NO;
            }
            break;
        } else {
            [self skipWhitespace];
            if ([self currentCharacter] == '}') {
                break;
            }
        }
    }
    
    if ([self scanCharacter:'}'] == NO) {
        [self setScanLocation:theScanLocation];
        if (outError) {
            *outError = [self error:kJSONScannerErrorCode_DictionaryNotTerminated description:@"Could not scan dictionary. Dictionary not terminated by a '}' character."];
        }
        [theDictionary release];
        return NO;
    }
    
    if (outDictionary != NULL) {
        if (self.options & kJSONScannerOptions_MutableContainers) {
            *outDictionary = [theDictionary autorelease];
        } else {
            *outDictionary = [[theDictionary copy] autorelease];
            [theDictionary release];
        }
    } else {
        [theDictionary release];
    }
    
    return YES;
}

- (BOOL)scanJSONArray:(NSArray **)outArray error:(NSError **)outError
{
    NSUInteger theScanLocation = [self scanLocation];
    
    [self skipWhitespace];
    
    if ([self scanCharacter:'['] == NO) {
        if (outError) {
            *outError = [self error:kJSONScannerErrorCode_ArrayStartCharacterMissing description:@"Could not scan array. Array not started by a '[' character."];
        }
        return NO;
    }
    
    NSMutableArray *theArray = [[NSMutableArray alloc] init];
    
    [self skipWhitespace];
    while ([self currentCharacter] != ']') {
        NSString *theValue = nil;
        if ([self scanJSONObject:&theValue error:outError] == NO) {
            [self setScanLocation:theScanLocation];
            if (outError) {
                *outError = [self error:kJSONScannerErrorCode_ArrayValueScanFailed description:@"Could not scan array. Could not scan a value."];
                NSMutableDictionary *theUserInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"Could not scan array. Could not scan a value.", NSLocalizedDescriptionKey, nil];
                [theUserInfo addEntriesFromDictionary:self.userInfoForScanLocation];
                *outError = [NSError errorWithDomain:kJSONScannerErrorDomain code:kJSONScannerErrorCode_ArrayValueScanFailed userInfo:theUserInfo];
            }
            [theArray release];
            return NO;
        }
        
        if (theValue == nil) {
            if (self.nullObject != nil) {
                if (outError) {
                    *outError = [self error:kJSONScannerErrorCode_ArrayValueIsNull description:@"Could not scan array. Value is NULL."];
                }
                [theArray release];
                return NO;
            }
        } else {
            [theArray addObject:theValue];
        }
        
        [self skipWhitespace];
        if ([self scanCharacter:','] == NO) {
            [self skipWhitespace];
            if ([self currentCharacter] != ']') {
                [self setScanLocation:theScanLocation];
                if (outError) {
                    *outError = [self error:kJSONScannerErrorCode_ArrayNotTerminated description:@"Could not scan array. Array not terminated by a ']' character."];
                }
                [theArray release];
                return NO;
            }
            break;
        }
        [self skipWhitespace];
    }
    
    [self skipWhitespace];
    
    if ([self scanCharacter:']'] == NO) {
        [self setScanLocation:theScanLocation];
        if (outError) {
            *outError = [self error:kJSONScannerErrorCode_ArrayNotTerminated description:@"Could not scan array. Array not terminated by a ']' character."];
        }
        [theArray release];
        return NO;
    }
    
    if (outArray != nil) {
        if (self.options & kJSONScannerOptions_MutableContainers) {
            *outArray = [theArray autorelease];
        } else {
            *outArray = [[theArray copy]autorelease];
            [theArray release];
        }
    } else {
        [theArray release];
    }
    return YES;
}

- (BOOL)scanJSONStringConstant:(NSString **)outStringConstant error:(NSError **)outError {
    NSUInteger theScanLocation = [self scanLocation];
    
    [self skipWhitespace];
    
    NSMutableString *theString = [[NSMutableString alloc]init];
    
    if ([self scanCharacter:'"'] == NO) {
        [self setScanLocation:theScanLocation];
        if (outError) {
            *outError = [self error:kJSONScannerErrorCode_StringNotStartedWithBackslash description:@"Could not scan string constant. String not started by a '\"' character."];
        }
        [theString release];
        return NO;
    }
    
    while ([self scanCharacter:'"'] == NO) {
        NSString *theStringChunk = nil;
        if ([self scanNotQuoteCharactersIntoString:&theStringChunk]) {
            CFStringAppend((CFMutableStringRef)theString, (CFStringRef)theStringChunk);
        } else if ([self scanCharacter:'\\'] == YES) {
            unichar theCharacter = [self scanCharacter];
            switch (theCharacter)
            {
                case '"':
                case '\\':
                case '/':
                    break;
                case 'b':
                    theCharacter = '\b';
                    break;
                case 'f':
                    theCharacter = '\f';
                    break;
                case 'n':
                    theCharacter = '\n';
                    break;
                case 'r':
                    theCharacter = '\r';
                    break;
                case 't':
                    theCharacter = '\t';
                    break;
                case 'u':
                {
                    theCharacter = 0;
                    
                    int theShift;
                    for (theShift = 12; theShift >= 0; theShift -= 4) {
                        const int theDigit = HexToInt([self scanCharacter]);
                        if (theDigit == -1) {
                            [self setScanLocation:theScanLocation];
                            if (outError) {
                                *outError = [self error:kJSONScannerErrorCode_StringUnicodeNotDecoded description:@"Could not scan string constant. Unicode character could not be decoded."];
                            }
                            [theString release];
                            return NO;
                        }
                        theCharacter |= (theDigit << theShift);
                    }
                }
                    break;
                default:
                {
                    if (strictEscapeCodes == YES) {
                        [self setScanLocation:theScanLocation];
                        if (outError) {
                            *outError = [self error:kJSONScannerErrorCode_StringUnknownEscapeCode description:@"Could not scan string constant. Unknown escape code."];
                        }
                        [theString release];
                        return NO;
                    }
                }
                    break;
            }
            CFStringAppendCharacters((CFMutableStringRef)theString, &theCharacter, 1);
        } else {
            if (outError) {
                *outError = [self error:kJSONScannerErrorCode_StringNotTerminated description:@"Could not scan string constant. No terminating double quote character."];
            }
            [theString release];
            return NO;
        }
    }
    
    if (outStringConstant != nil) {
        if (self.options & kJSONScannerOptions_MutableLeaves) {
            *outStringConstant = [theString autorelease];
        } else {
            *outStringConstant = [[theString copy]autorelease];
            [theString release];
        }
    } else {
        [theString release];
    }
    
    return YES;
}

- (BOOL)scanJSONNumberConstant:(NSNumber **)outNumberConstant error:(NSError **)outError
{
    NSNumber *theNumber = nil;
    
    [self skipWhitespace];
    
    if ([self scanNumber:&theNumber] == YES) {
        if (outNumberConstant != nil)
            *outNumberConstant = theNumber;
        return YES;
    } else {
        if (outError) {
            *outError = [self error:kJSONScannerErrorCode_NumberNotScannable description:@"Could not scan number constant."];
        }
        return NO;
    }
}

#if TREAT_COMMENTS_AS_WHITESPACE
- (void)skipWhitespace
{
    [super skipWhitespace];
    [self scanCStyleComment:nil];
    [self scanCPlusPlusStyleComment:nil];
    [super skipWhitespace];
}
#endif

- (BOOL)scanNotQuoteCharactersIntoString:(NSString **)outValue {
    u_int8_t *P;
    for (P = current; P < end && *P != '\"' && *P != '\\'; ++P);
    
    if (P == current) {
        return NO;
    }
    
    if (outValue) {
        *outValue = [[[NSString alloc]initWithBytes:current length:P - current encoding:NSUTF8StringEncoding]autorelease];
    }
    
    current = P;
    
    return YES;
}

- (NSError *)error:(NSInteger)inCode description:(NSString *)inDescription {
    NSParameterAssert(inDescription != nil);
    NSMutableDictionary *theUserInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:inDescription, NSLocalizedDescriptionKey, nil];
    [theUserInfo addEntriesFromDictionary:self.userInfoForScanLocation];
    NSError *theError = [NSError errorWithDomain:kJSONScannerErrorDomain code:inCode userInfo:theUserInfo];
    return theError;
}

@end

@implementation CJSONDeserializer

@synthesize scanner;
@synthesize options;

+ (CJSONDeserializer *)deserializer {
    return [[[self alloc]init]autorelease];
}

- (id)init {
    self = [super init];
    return self;
}

- (void)dealloc {
    [scanner release];
    scanner = nil;
    [super dealloc];
}

- (CJSONScanner *)scanner {
    if (scanner == nil) {
        scanner = [[CJSONScanner alloc] init];
    }
    return scanner;
}

- (id)nullObject {
    return self.scanner.nullObject;
}

- (void)setNullObject:(id)inNullObject {
    self.scanner.nullObject = inNullObject;
}

- (NSStringEncoding)allowedEncoding {
    return self.scanner.allowedEncoding;
}

- (void)setAllowedEncoding:(NSStringEncoding)inAllowedEncoding {
    self.scanner.allowedEncoding = inAllowedEncoding;
}

- (id)deserialize:(NSData *)inData error:(NSError **)outError {
    if (inData == nil || inData.length == 0) {
        if (outError) {
            *outError = [NSError errorWithDomain:kJSONDeserializerErrorDomain code:kJSONScannerErrorCode_NothingToScan userInfo:NULL];
        }
        return nil;
    }
    
    if ([self.scanner setData:inData error:outError] == NO) {
        return nil;
    }
    
    id theObject = nil;
    if ([self.scanner scanJSONObject:&theObject error:outError] == YES) {
        return theObject;
    } else {
        return nil;
    }
}

- (id)deserializeAsDictionary:(NSData *)inData error:(NSError **)outError {
    
    if (inData == nil || inData.length == 0) {
        if (outError) {
            *outError = [NSError errorWithDomain:kJSONDeserializerErrorDomain code:kJSONScannerErrorCode_NothingToScan userInfo:nil];
        }
        return nil;
    }
    
    if ([self.scanner setData:inData error:outError] == NO) {
        return nil;
    }
    
    NSDictionary *theDictionary = nil;
    if ([self.scanner scanJSONDictionary:&theDictionary error:outError] == YES) {
        return theDictionary;
    } else {
        return nil;
    }
}

- (id)deserializeAsArray:(NSData *)inData error:(NSError **)outError {
    
    if (inData == nil || inData.length == 0) {
        if (outError) {
            *outError = [NSError errorWithDomain:kJSONDeserializerErrorDomain code:kJSONScannerErrorCode_NothingToScan userInfo:NULL];
        }
        
        return nil;
    }
    
    if ([self.scanner setData:inData error:outError] == NO) {
        return nil;
    }
    
    NSArray *theArray = nil;
    if ([self.scanner scanJSONArray:&theArray error:outError] == YES) {
        return theArray;
    } else {
        return nil;
    }
}

@end

@implementation CJSONSerializer

@synthesize options;

+ (void)initialize {
    if (self == CJSONSerializer.class) {
        NSAutoreleasePool *thePool = [[NSAutoreleasePool alloc]init];
        
        if (kNULL == nil)
            kNULL = [[NSData alloc]initWithBytesNoCopy:(void *)"null" length:4 freeWhenDone:NO];
        if (kFalse == nil)
            kFalse = [[NSData alloc]initWithBytesNoCopy:(void *)"false" length:5 freeWhenDone:NO];
        if (kTrue == nil)
            kTrue = [[NSData alloc]initWithBytesNoCopy:(void *)"true" length:4 freeWhenDone:NO];
        
        [thePool release];
    }
}

+ (CJSONSerializer *)serializer {
    return [[[self alloc]init]autorelease];
}

- (BOOL)isValidJSONObject:(id)inObject {
    if ([inObject isKindOfClass:[NSNull class]]) {
        return YES;
    } else if ([inObject isKindOfClass:[NSNumber class]]) {
        return YES;
    } else if ([inObject isKindOfClass:[NSString class]]) {
        return YES;
    } else if ([inObject isKindOfClass:[NSArray class]]) {
        return YES;
    } else if ([inObject isKindOfClass:[NSDictionary class]]) {
        return YES;
    } else if ([inObject isKindOfClass:[NSData class]]) {
        return YES;
    } else if ([inObject respondsToSelector:@selector(JSONDataRepresentation)]) {
        return YES;
    }

    return NO;
}

- (NSData *)serializeObject:(id)inObject error:(NSError **)outError {
    NSData *theResult = nil;
    
    if ([inObject isKindOfClass:[NSNull class]]) {
        theResult = [self serializeNull:inObject error:outError];
    } else if ([inObject isKindOfClass:[NSNumber class]]) {
        theResult = [self serializeNumber:inObject error:outError];
    } else if ([inObject isKindOfClass:[NSString class]]) {
        theResult = [self serializeString:inObject error:outError];
    } else if ([inObject isKindOfClass:[NSArray class]]) {
        theResult = [self serializeArray:inObject error:outError];
    } else if ([inObject isKindOfClass:[NSDictionary class]]) {
        theResult = [self serializeDictionary:inObject error:outError];
    } else if ([inObject isKindOfClass:[NSData class]]) {
        NSString *theString = [[[NSString alloc] initWithData:inObject encoding:NSUTF8StringEncoding] autorelease];
        theResult = [self serializeString:theString error:outError];
    } else if ([inObject respondsToSelector:@selector(JSONDataRepresentation)]) {
        theResult = [inObject JSONDataRepresentation];
    } else {
        if (outError) {
            NSDictionary *theUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Cannot serialize data of type '%@'", NSStringFromClass([inObject class])], NSLocalizedDescriptionKey, nil];
            *outError = [NSError errorWithDomain:@"TODO_DOMAIN" code:CJSONSerializerErrorCouldNotSerializeDataType userInfo:theUserInfo];
        }
        return nil;
    }
    
    if (theResult == nil) {
        if (outError) {
            NSDictionary *theUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [NSString stringWithFormat:@"Could not serialize object '%@'", inObject], NSLocalizedDescriptionKey,
                                         NULL];
            *outError = [NSError errorWithDomain:@"TODO_DOMAIN" code:CJSONSerializerErrorCouldNotSerializeObject userInfo:theUserInfo];
        }
        return nil;
    }
    return theResult;
}

- (NSData *)serializeNull:(NSNull *)inNull error:(NSError **)outError {
    return kNULL;
}

- (NSData *)serializeNumber:(NSNumber *)inNumber error:(NSError **)outError {
    NSData *theResult = nil;
    switch (CFNumberGetType((CFNumberRef)inNumber))
    {
        case kCFNumberCharType:
        {
            int theValue = [inNumber intValue];
            if (theValue == 0) {
                theResult = kFalse;
            } else if (theValue == 1) {
                theResult = kTrue;
            } else {
                theResult = [[inNumber stringValue] dataUsingEncoding:NSASCIIStringEncoding];
            }
        }
            break;
        case kCFNumberFloat32Type:
        case kCFNumberFloat64Type:
        case kCFNumberFloatType:
        case kCFNumberDoubleType:
        case kCFNumberSInt8Type:
        case kCFNumberSInt16Type:
        case kCFNumberSInt32Type:
        case kCFNumberSInt64Type:
        case kCFNumberShortType:
        case kCFNumberIntType:
        case kCFNumberLongType:
        case kCFNumberLongLongType:
        case kCFNumberCFIndexType:
        default:
            theResult = [[inNumber stringValue]dataUsingEncoding:NSASCIIStringEncoding];
            break;
    }
    return theResult;
}

- (NSData *)serializeString:(NSString *)inString error:(NSError **)outError {
    const char *theUTF8String = [inString UTF8String];
    
    NSMutableData *theData = [NSMutableData dataWithLength:strlen(theUTF8String) * 2 + 2];
    
    char *theOutputStart = [theData mutableBytes];
    char *OUT = theOutputStart;
    
    *OUT++ = '"';
    
    for (const char *IN = theUTF8String; IN && *IN != '\0'; ++IN) {
        switch (*IN)
        {
            case '\\':
            {
                *OUT++ = '\\';
                *OUT++ = '\\';
            }
                break;
            case '\"':
            {
                *OUT++ = '\\';
                *OUT++ = '\"';
            }
                break;
            case '/':
            {
                if (self.options & kJSONSerializationOptions_EncodeSlashes) {
                    *OUT++ = '\\';
                    *OUT++ = '/';
                } else {
                    *OUT++ = *IN;
                }
            }
                break;
            case '\b':
            {
                *OUT++ = '\\';
                *OUT++ = 'b';
            }
                break;
            case '\f':
            {
                *OUT++ = '\\';
                *OUT++ = 'f';
            }
                break;
            case '\n':
            {
                *OUT++ = '\\';
                *OUT++ = 'n';
            }
                break;
            case '\r':
            {
                *OUT++ = '\\';
                *OUT++ = 'r';
            }
                break;
            case '\t':
            {
                *OUT++ = '\\';
                *OUT++ = 't';
            }
                break;
            default:
            {
                *OUT++ = *IN;
            }
                break;
        }
    }
    
    *OUT++ = '"';
    
    theData.length = OUT - theOutputStart;
    return theData;
}

- (NSData *)serializeArray:(NSArray *)inArray error:(NSError **)outError {
    NSMutableData *theData = [NSMutableData data];
    [theData appendBytes:"[" length:1];
    
    NSEnumerator *theEnumerator = [inArray objectEnumerator];
    id theValue = nil;
    NSUInteger i = 0;
    while ((theValue = [theEnumerator nextObject]) != nil) {
        NSData *theValueData = [self serializeObject:theValue error:outError];
        if (theValueData == nil) {
            return nil;
        }
        [theData appendData:theValueData];
        if (++i < [inArray count]) {
            [theData appendBytes:"," length:1];
        }
    }
    
    [theData appendBytes:"]" length:1];
    
    return theData;
}

- (NSData *)serializeDictionary:(NSDictionary *)inDictionary error:(NSError **)outError {
    NSMutableData *theData = [NSMutableData data];
    [theData appendBytes:"{" length:1];
    
    NSArray *theKeys = [inDictionary allKeys];
    NSEnumerator *theEnumerator = [theKeys objectEnumerator];
    NSString *theKey = nil;
    while ((theKey = [theEnumerator nextObject]) != nil) {
        id theValue = [inDictionary objectForKey:theKey];
        
        NSData *theKeyData = [self serializeString:theKey error:outError];
        if (theKeyData == nil) {
            return nil;
        }
        NSData *theValueData = [self serializeObject:theValue error:outError];
        if (theValueData == nil) {
            return nil;
        }
        
        
        [theData appendData:theKeyData];
        [theData appendBytes:":" length:1];
        [theData appendData:theValueData];
        
        if (theKey != [theKeys lastObject]) {
            [theData appendData:[@"," dataUsingEncoding:NSASCIIStringEncoding]];
        }
    }
    
    [theData appendBytes:"}" length:1];
    
    return theData;
}

@end

@implementation CDataScanner (CDataScanner_Extensions)

- (BOOL)scanCStyleComment:(NSString **)outComment {
    if ([self scanString:@"/*" intoString:nil] == YES) {
        NSString *theComment = nil;
        if ([self scanUpToString:@"*/" intoString:&theComment] == NO) {
            [NSException raise:NSGenericException format:@"Started to scan a C style comment but it wasn't terminated."];
        }
		
        if ([theComment rangeOfString:@"/*"].location != NSNotFound) {
            [NSException raise:NSGenericException format:@"C style comments should not be nested."];
        }
        
        if ([self scanString:@"*/" intoString:nil] == NO) {
            [NSException raise:NSGenericException format:@"C style comment did not end correctly."];
        }
		
        if (outComment != nil) {
            *outComment = theComment;
        }
        
        return YES;
	} else {
        return NO;
	}
}

- (BOOL)scanCPlusPlusStyleComment:(NSString **)outComment {
    if ([self scanString:@"//" intoString:nil] == YES) {
        unichar theCharacters[] = { LF, FF, CR, NEL, LS, PS, };
        NSCharacterSet *theLineBreaksCharacterSet = [NSCharacterSet characterSetWithCharactersInString:[NSString stringWithCharacters:theCharacters length:sizeof(theCharacters)/sizeof(*theCharacters)]];
        
        NSString *theComment = nil;
        [self scanUpToCharactersFromSet:theLineBreaksCharacterSet intoString:&theComment];
        [self scanCharactersFromSet:theLineBreaksCharacterSet intoString:nil];
        
        if (outComment != nil)
            *outComment = theComment;
        
        return YES;
    } else {
        return NO;
    }
}

- (NSUInteger)lineOfScanLocation {
    NSUInteger theLine = 0;
    for (const u_int8_t *C = start; C < current; ++C) {
        // TODO: JIW What about MS-DOS line endings you bastard! (Also other unicode line endings)
        if (*C == '\n' || *C == '\r') {
            ++theLine;
        }
    }
    return theLine;
}

- (NSDictionary *)userInfoForScanLocation {
    NSUInteger theLine = 0;
    const u_int8_t *theLineStart = start;
    for (const u_int8_t *C = start; C < current; ++C) {
        if (*C == '\n' || *C == '\r') {
            theLineStart = C - 1;
            ++theLine;
        }
    }
    
    NSUInteger theCharacter = current - theLineStart;
    
    NSRange theStartRange = NSIntersectionRange((NSRange){ .location = MAX((NSInteger)self.scanLocation - 20, 0), .length = 20 + (NSInteger)self.scanLocation - 20 }, (NSRange){ .location = 0, .length = self.data.length });
    NSRange theEndRange = NSIntersectionRange((NSRange){ .location = self.scanLocation, .length = 20 }, (NSRange){ .location = 0, .length = self.data.length });
    
    
    NSString *theSnippet = [NSString stringWithFormat:@"%@!HERE>!%@",[[[NSString alloc]initWithData:[self.data subdataWithRange:theStartRange] encoding:NSUTF8StringEncoding]autorelease],[[[NSString alloc]initWithData:[self.data subdataWithRange:theEndRange] encoding:NSUTF8StringEncoding]autorelease]];
    
    NSDictionary *theUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInteger:theLine], @"line",[NSNumber numberWithUnsignedInteger:theCharacter], @"character", [NSNumber numberWithUnsignedInteger:self.scanLocation], @"location", theSnippet, @"snippet", nil];
    return theUserInfo;    
}

@end

@implementation NSDictionary (NSDictionary_JSONExtensions)

+ (id)dictionaryWithJSONData:(NSData *)inData error:(NSError **)outError {
    return [[CJSONDeserializer deserializer]deserialize:inData error:outError];
}

+ (id)dictionaryWithJSONString:(NSString *)inJSON error:(NSError **)outError {
    NSData *theData = [inJSON dataUsingEncoding:NSUTF8StringEncoding];
    return [self dictionaryWithJSONData:theData error:outError];
}

@end
