//
//  TouchJSON.h
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

#import <Foundation/Foundation.h>

extern NSString *const kJSONScannerErrorDomain /* = @"kJSONScannerErrorDomain" */;
extern NSString *const kJSONDeserializerErrorDomain /* = @"CJSONDeserializerErrorDomain" */;

enum {
    kJSONSerializationOptions_EncodeSlashes = 0x01,
};
typedef NSUInteger EJSONSerializationOptions;

typedef enum {
    CJSONSerializerErrorCouldNotSerializeDataType = -1,
    CJSONSerializerErrorCouldNotSerializeObject = -1
} CJSONSerializerError;

enum {
    kJSONScannerOptions_MutableContainers = 0x1,
    kJSONScannerOptions_MutableLeaves = 0x2,
};
typedef NSUInteger EJSONScannerOptions;

enum {
    kJSONDeserializationOptions_MutableContainers = kJSONScannerOptions_MutableContainers,
    kJSONDeserializationOptions_MutableLeaves = kJSONScannerOptions_MutableLeaves,
};
typedef NSUInteger EJSONDeserializationOptions;

typedef enum {
    
    // Fundamental scanning errors
    kJSONScannerErrorCode_NothingToScan = -11,
    kJSONScannerErrorCode_CouldNotDecodeData = -12,
    kJSONScannerErrorCode_CouldNotSerializeData = -13,
    kJSONScannerErrorCode_CouldNotSerializeObject = -14,
    kJSONScannerErrorCode_CouldNotScanObject = -15,
    
    // Dictionary scanning
    kJSONScannerErrorCode_DictionaryStartCharacterMissing = -101,
    kJSONScannerErrorCode_DictionaryKeyScanFailed = -102,
    kJSONScannerErrorCode_DictionaryKeyNotTerminated = -103,
    kJSONScannerErrorCode_DictionaryValueScanFailed = -104,
    kJSONScannerErrorCode_DictionaryKeyValuePairNoDelimiter = -105,
    kJSONScannerErrorCode_DictionaryNotTerminated = -106,
    
    // Array scanning
    kJSONScannerErrorCode_ArrayStartCharacterMissing = -201,
    kJSONScannerErrorCode_ArrayValueScanFailed = -202,
    kJSONScannerErrorCode_ArrayValueIsNull = -203,
    kJSONScannerErrorCode_ArrayNotTerminated = -204,
    
    // String scanning
    kJSONScannerErrorCode_StringNotStartedWithBackslash = -301,
    kJSONScannerErrorCode_StringUnicodeNotDecoded = -302,
    kJSONScannerErrorCode_StringUnknownEscapeCode = -303,
    kJSONScannerErrorCode_StringNotTerminated = -304,
    
    // Number scanning
    kJSONScannerErrorCode_NumberNotScannable = -401
    
} EJSONScannerErrorCode;



@protocol JSONRepresentation

@optional
- (id)initWithJSONDataRepresentation:(NSData *)inJSONData;
- (NSData *)JSONDataRepresentation;
@end

@interface CDataScanner : NSObject {
	NSData *data;
    
	u_int8_t *start;
	u_int8_t *end;
	u_int8_t *current;
	NSUInteger length;
}

@property (readwrite, nonatomic, retain) NSData *data;
@property (readwrite, nonatomic, assign) NSUInteger scanLocation;
@property (readonly, nonatomic, assign) NSUInteger bytesRemaining;
@property (readonly, nonatomic, assign) BOOL isAtEnd;

- (id)initWithData:(NSData *)inData;

- (unichar)currentCharacter;
- (unichar)scanCharacter;
- (BOOL)scanCharacter:(unichar)inCharacter;

- (BOOL)scanUTF8String:(const char *)inString intoString:(NSString **)outValue;
- (BOOL)scanString:(NSString *)inString intoString:(NSString **)outValue;
- (BOOL)scanCharactersFromSet:(NSCharacterSet *)inSet intoString:(NSString **)outValue; // inSet must only contain 7-bit ASCII characters

- (BOOL)scanUpToString:(NSString *)string intoString:(NSString **)outValue;
- (BOOL)scanUpToCharactersFromSet:(NSCharacterSet *)set intoString:(NSString **)outValue; // inSet must only contain 7-bit ASCII characters

- (BOOL)scanNumber:(NSNumber **)outValue;
- (BOOL)scanDecimalNumber:(NSDecimalNumber **)outValue;

- (BOOL)scanDataOfLength:(NSUInteger)inLength intoPointer:(void **)outPointer;
- (BOOL)scanDataOfLength:(NSUInteger)inLength intoData:(NSData **)outData;

- (void)skipWhitespace;

- (NSString *)remainingString;
- (NSData *)remainingData;

@end

@interface CDataScanner (CDataScanner_Extensions)

- (BOOL)scanCStyleComment:(NSString **)outComment;
- (BOOL)scanCPlusPlusStyleComment:(NSString **)outComment;

- (NSUInteger)lineOfScanLocation;
- (NSDictionary *)userInfoForScanLocation;

@end

// CDataScanner subclass that understands JSON syntax natively. You should generally use CJSONDeserializer instead of this class.
// (TODO - this could have been a category?)
@interface CJSONScanner : CDataScanner {
	BOOL strictEscapeCodes;
    id nullObject;
	NSStringEncoding allowedEncoding;
    EJSONScannerOptions options;
}

@property (readwrite, nonatomic, assign) BOOL strictEscapeCodes;
@property (readwrite, nonatomic, retain) id nullObject;
@property (readwrite, nonatomic, assign) NSStringEncoding allowedEncoding;
@property (readwrite, nonatomic, assign) EJSONScannerOptions options;

- (BOOL)setData:(NSData *)inData error:(NSError **)outError;

- (BOOL)scanJSONObject:(id *)outObject error:(NSError **)outError;
- (BOOL)scanJSONDictionary:(NSDictionary **)outDictionary error:(NSError **)outError;
- (BOOL)scanJSONArray:(NSArray **)outArray error:(NSError **)outError;
- (BOOL)scanJSONStringConstant:(NSString **)outStringConstant error:(NSError **)outError;
- (BOOL)scanJSONNumberConstant:(NSNumber **)outNumberConstant error:(NSError **)outError;

@end

@interface CJSONDeserializer : NSObject {
    CJSONScanner *scanner;
    EJSONDeserializationOptions options;
}

@property (readwrite, nonatomic, retain) CJSONScanner *scanner;
/// Object to return instead when a null encountered in the JSON. Defaults to NSNull. Setting to null causes the scanner to skip null values.
@property (readwrite, nonatomic, retain) id nullObject;
/// JSON must be encoded in Unicode (UTF-8, UTF-16 or UTF-32). Use this if you expect to get the JSON in another encoding.
@property (readwrite, nonatomic, assign) NSStringEncoding allowedEncoding;
@property (readwrite, nonatomic, assign) EJSONDeserializationOptions options;

+ (CJSONDeserializer *)deserializer;

- (id)deserialize:(NSData *)inData error:(NSError **)outError;

- (id)deserializeAsDictionary:(NSData *)inData error:(NSError **)outError;
- (id)deserializeAsArray:(NSData *)inData error:(NSError **)outError;

@end

@interface CJSONSerializer : NSObject {
    EJSONSerializationOptions options;
}

@property (readwrite, nonatomic, assign) EJSONSerializationOptions options;

+ (CJSONSerializer *)serializer;

- (BOOL)isValidJSONObject:(id)inObject;

/// Take any JSON compatible object (generally NSNull, NSNumber, NSString, NSArray and NSDictionary) and produce an NSData containing the serialized JSON.
- (NSData *)serializeObject:(id)inObject error:(NSError **)outError;

- (NSData *)serializeNull:(NSNull *)inNull error:(NSError **)outError;
- (NSData *)serializeNumber:(NSNumber *)inNumber error:(NSError **)outError;
- (NSData *)serializeString:(NSString *)inString error:(NSError **)outError;
- (NSData *)serializeArray:(NSArray *)inArray error:(NSError **)outError;
- (NSData *)serializeDictionary:(NSDictionary *)inDictionary error:(NSError **)outError;

@end

@interface NSDictionary (NSDictionary_JSONExtensions)

+ (id)dictionaryWithJSONData:(NSData *)inData error:(NSError **)outError;
+ (id)dictionaryWithJSONString:(NSString *)inJSON error:(NSError **)outError;

@end
