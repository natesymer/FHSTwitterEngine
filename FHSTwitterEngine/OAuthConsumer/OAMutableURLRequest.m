//
//  OAMutableURLRequest.m
//  OAuthConsumer
//
//  Created by Jon Crosby on 10/19/07.
//  Copyright 2007 Kaboomerang LLC. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


#import "OAMutableURLRequest.h"
#import "OARequestParameter.h"


@interface OAMutableURLRequest (Private)
- (void)_generateTimestamp;
- (void)_generateNonce;
- (NSString *)_signatureBaseString;
@end

@implementation OAMutableURLRequest
@synthesize signature, nonce, timestamp;

#pragma mark init

- (id)initWithURL:(NSURL *)aUrl
		 consumer:(OAConsumer *)aConsumer
			token:(OAToken *)aToken
            realm:(NSString *)aRealm
signatureProvider:(id<OASignatureProviding, NSObject>)aProvider 
{
    self = [super initWithURL:aUrl cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0];
    
    if (self) {    
		consumer = [aConsumer retain];
		
		// empty token for Unauthorized Request Token transaction
		if (aToken == nil) {
			token = [[OAToken alloc]init];
		} else {
			token = [aToken retain];
        }
		
		if (aRealm == nil) {
			realm = [[NSString alloc] initWithString:@""];
		} else {
			realm = [aRealm retain];
        }
		
		// default to HMAC-SHA1
		if (aProvider == nil) {
			signatureProvider = [[OAHMAC_SHA1SignatureProvider alloc] init];
		} else {
			signatureProvider = [aProvider retain];
        }
		
		[self _generateTimestamp];
		[self _generateNonce];
	}
    return self;
}

// Setting a timestamp and nonce to known
// values can be helpful for testing
- (id)initWithURL:(NSURL *)aUrl
		 consumer:(OAConsumer *)aConsumer
			token:(OAToken *)aToken
            realm:(NSString *)aRealm
signatureProvider:(id<OASignatureProviding, NSObject>)aProvider
            nonce:(NSString *)aNonce
        timestamp:(NSString *)aTimestamp 
{
	
    self = [super initWithURL:aUrl cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0];
    
    if (self) {    
		consumer = [aConsumer retain];
		
		// empty token for Unauthorized Request Token transaction
		if (aToken == nil) {
			token = [[OAToken alloc] init];
		} else {
			token = [aToken retain];
        }
		
		if (aRealm == nil) {
			realm = [[NSString alloc]initWithString:@""];
		} else {
			realm = [aRealm retain];
        }
		
		// default to HMAC-SHA1
		if (aProvider == nil) {
			signatureProvider = [[OAHMAC_SHA1SignatureProvider alloc] init];
		} else {
			signatureProvider = [aProvider retain];
        }
		
		timestamp = [aTimestamp retain];
		nonce = [aNonce retain];
	}
    return self;
}

- (void)dealloc {
    
	[extraOAuthParameters release];
    extraOAuthParameters = nil;
    
    [consumer release];
    consumer = nil;
    [token release];
    token = nil;
    [realm release];
    realm = nil;
    [signatureProvider release];
    signatureProvider = nil;
    
    [self setTimestamp:nil];
    [self setNonce:nil];
    [self setSignature:nil];
    
	[super dealloc];
}

#pragma mark -
#pragma mark Public

- (void)setOAuthParameterName:(NSString*)parameterName withValue:(NSString*)parameterValue {
	assert(parameterName && parameterValue);
	
	if (extraOAuthParameters == nil) {
		extraOAuthParameters = [NSMutableDictionary new];
	}
	
	[extraOAuthParameters setObject:parameterValue forKey:parameterName];
}

- (void)prepare {
    // sign
	// Secrets must be urlencoded before concatenated with '&'
	// TODO: if later RSA-SHA1 support is added then a little code redesign is needed
    signature = [[signatureProvider signClearText:[self _signatureBaseString] withSecret:[NSString stringWithFormat:@"%@&%@", [consumer.secret URLEncodedString], [token.secret URLEncodedString]]]retain];
    
    // set OAuth headers
	NSString *oauthToken;
    
	if ([token.key isEqualToString:@""]) {
		oauthToken = @"oauth_callback=\"oob\", ";
	} else if(token.verifier == nil || [token.verifier isEqualToString:@""]) {
		oauthToken = [NSString stringWithFormat:@"oauth_token=\"%@\", ", [token.key URLEncodedString]];
	} else {
		oauthToken = [NSString stringWithFormat:@"oauth_token=\"%@\", oauth_verifier=\"%@\", ", [token.key URLEncodedString], [token.verifier URLEncodedString]];
    }
    
	NSMutableString *extraParameters = [NSMutableString string];
	
	// Adding the optional parameters in sorted order isn't required by the OAuth spec, but it makes it possible to hard-code expected values in the unit tests.
	for (NSString *parameterName in [[extraOAuthParameters allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
		[extraParameters appendFormat:@", %@=\"%@\"",[parameterName URLEncodedString],[[extraOAuthParameters objectForKey:parameterName] URLEncodedString]];
	}	
    
    NSString *oauthHeader = [NSString stringWithFormat:@"OAuth realm=\"%@\", oauth_consumer_key=\"%@\", %@oauth_signature_method=\"%@\", oauth_signature=\"%@\", oauth_timestamp=\"%@\", oauth_nonce=\"%@\", oauth_version=\"1.0\"%@", [realm URLEncodedString], [consumer.key URLEncodedString], oauthToken, [[signatureProvider name] URLEncodedString], [signature URLEncodedString], timestamp, nonce, extraParameters];
	
    [self setValue:oauthHeader forHTTPHeaderField:@"Authorization"];
}

- (NSArray *)parameters {
    
    NSString *encodedParameters;
    
    if ([self.HTTPMethod isEqualToString:@"GET"] || [self.HTTPMethod isEqualToString:@"DELETE"]) {
        encodedParameters = [self.URL.query retain];
	} else {
        // POST, PUT
        encodedParameters = [[NSString alloc]initWithData:self.HTTPBody encoding:NSASCIIStringEncoding];
    }
    
    if ((encodedParameters == nil) || ([encodedParameters isEqualToString:@""])) {
        [encodedParameters release];
        return nil;
    }
    
    NSArray *encodedParameterPairs = [encodedParameters componentsSeparatedByString:@"&"];
    NSMutableArray *requestParameters = [[NSMutableArray alloc]initWithCapacity:16];
    
    for (NSString *encodedPair in encodedParameterPairs) {
        NSArray *encodedPairElements = [encodedPair componentsSeparatedByString:@"="];
        OARequestParameter *parameter = [OARequestParameter requestParameterWithName:[[encodedPairElements objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] value:[[encodedPairElements objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        [requestParameters addObject:parameter];
    }
    
    [encodedParameters release];
	
    return [requestParameters autorelease];
}

- (void)setParameters:(NSArray *)parameters {
    NSMutableString *encodedParameterPairs = [NSMutableString stringWithCapacity:256];
    
    int position = 1;
    for (OARequestParameter *requestParameter in parameters) {
        [encodedParameterPairs appendString:[requestParameter URLEncodedNameValuePair]];
        if (position < parameters.count) {
            [encodedParameterPairs appendString:@"&"];
        }
        position++;
    }
    
    if ([self.HTTPMethod isEqualToString:@"GET"] || [self.HTTPMethod isEqualToString:@"DELETE"]) {
        [self setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", [self.URL URLStringWithoutQuery], encodedParameterPairs]]];
    } else {
        // POST, PUT
        NSData *postData = [encodedParameterPairs dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
        [self setHTTPBody:postData];
        [self setValue:[NSString stringWithFormat:@"%d", postData.length] forHTTPHeaderField:@"Content-Length"];
        [self setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    }
}

- (NSData *)sendSynchronousConnection {
    NSError *error = nil;
    NSHTTPURLResponse *response = nil;
    
    NSData *responseData = [NSURLConnection sendSynchronousRequest:self returningResponse:&response error:&error];
    
    if (response == nil || responseData == nil || error != nil) {
        return nil;
    }
    
    return responseData;
}

#pragma mark -
#pragma mark Private

- (void)_generateTimestamp {
    [self setTimestamp:[NSString stringWithFormat:@"%ld", time(NULL)]];
}

- (void)_generateNonce {
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    [self setNonce:[NSString stringWithString:(NSString *)string]];
    CFRelease(string);
}

- (NSString *)_signatureBaseString {
    // OAuth Spec, Section 9.1.1 "Normalize Request Parameters"
    // build a sorted array of both request parameters and OAuth header parameters
    NSMutableArray *parameterPairs = [NSMutableArray  arrayWithCapacity:(6 + [self parameters].count)]; // 6 being the number of OAuth params in the Signature Base String
    
	[parameterPairs addObject:[[OARequestParameter requestParameterWithName:@"oauth_consumer_key" value:consumer.key] URLEncodedNameValuePair]];
	[parameterPairs addObject:[[OARequestParameter requestParameterWithName:@"oauth_signature_method" value:[signatureProvider name]] URLEncodedNameValuePair]];
	[parameterPairs addObject:[[OARequestParameter requestParameterWithName:@"oauth_timestamp" value:timestamp] URLEncodedNameValuePair]];
	[parameterPairs addObject:[[OARequestParameter requestParameterWithName:@"oauth_nonce" value:nonce] URLEncodedNameValuePair]];
	[parameterPairs addObject:[[OARequestParameter requestParameterWithName:@"oauth_version" value:@"1.0"] URLEncodedNameValuePair]];
    
	if (![token.key isEqualToString:@""]) {
        [parameterPairs addObject:[[OARequestParameter requestParameterWithName:@"oauth_token" value:token.key] URLEncodedNameValuePair]];
		if (token.verifier != nil && ![token.verifier isEqualToString:@""]) {
			[parameterPairs addObject:[[OARequestParameter requestParameterWithName:@"oauth_verifier" value:token.verifier] URLEncodedNameValuePair]];
		}
    } else {
		[parameterPairs addObject:[[OARequestParameter requestParameterWithName:@"oauth_callback" value:@"oob"] URLEncodedNameValuePair]];
	}

    for (OARequestParameter *param in [self parameters]) {
        [parameterPairs addObject:[param URLEncodedNameValuePair]];
    }

    NSArray *sortedPairs = [parameterPairs sortedArrayUsingSelector:@selector(compare:)];
    NSString *normalizedRequestParameters = [sortedPairs componentsJoinedByString:@"&"];
    
    // OAuth Spec, Section 9.1.2 "Concatenate Request Elements"
    NSString *ret = [NSString stringWithFormat:@"%@&%@&%@", self.HTTPMethod, [[self.URL URLStringWithoutQuery]URLEncodedString], [normalizedRequestParameters URLEncodedString]];
	return ret;
}

@end
