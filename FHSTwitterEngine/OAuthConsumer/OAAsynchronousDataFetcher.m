//
//  OAAsynchronousDataFetcher.m
//  OAuthConsumer
//
//  Created by Zsombor Szabó on 12/3/08.
//  Modified by Nathaniel Symer on 9/5/12.
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

#import "OAAsynchronousDataFetcher.h"

#import "OAServiceTicket.h"

@implementation OAAsynchronousDataFetcher

@synthesize requestFailedBlock, requestSucceededBlock;

+ (id)asynchronousFetcherWithRequest:(OAMutableURLRequest *)aRequest delegate:(id)aDelegate didFinishSelector:(SEL)finishSelector didFailSelector:(SEL)failSelector {
	return [[[OAAsynchronousDataFetcher alloc] initWithRequest:aRequest delegate:aDelegate didFinishSelector:finishSelector didFailSelector:failSelector] autorelease];
}

- (id)initWithRequest:(OAMutableURLRequest *)aRequest delegate:(id)aDelegate didFinishSelector:(SEL)finishSelector didFailSelector:(SEL)failSelector {
    self = [super init];
	if (self) {
		request = [aRequest retain];
		delegate = aDelegate;
		didFinishSelector = finishSelector;
		didFailSelector = failSelector;
        responseData = [[NSMutableData alloc]init];
	}
	return self;
}

+ (id)asynchronousFetcherWithRequest:(OAMutableURLRequest *)aRequest didFinishBlock:(void (^)(id ticket, id data))finishBlock didFailBlock:(void (^)(id ticket, id error))failBlock {
    return [[[OAAsynchronousDataFetcher alloc]initWithRequest:aRequest didFinishBlock:finishBlock didFailBlock:failBlock]autorelease];
}

- (id)initWithRequest:(OAMutableURLRequest *)aRequest didFinishBlock:(void (^)(id ticket, id data))finishBlock didFailBlock:(void (^)(id ticket, id error))failBlock {
    self = [super init];
	if (self) {
		request = [aRequest retain];
        self.requestSucceededBlock = finishBlock;
        self.requestFailedBlock = failBlock;
        responseData = [[NSMutableData alloc]init];
	}
	return self;
}

- (id)init {
    self = [super init];
    if (self) {
        responseData = [[NSMutableData alloc]init];
    }
    return self;
}

- (void)setRequest:(OAMutableURLRequest *)aRequest {
    if (request) {
        [request release];
    }
    request = [aRequest retain];
}

- (void)setDelegate:(id)aDelegate {
    delegate = aDelegate;
}

- (void)start {
    
    [request prepare];
	
	if (connection) {
		[connection release];
    }
	
	connection = [[NSURLConnection alloc]initWithRequest:request delegate:self];
    
	if (connection) {
		[responseData setLength:0];
	} else {
        OAServiceTicket *ticket = [[OAServiceTicket alloc]initWithRequest:request response:nil didSucceed:NO];
        if (delegate) {
            [delegate performSelector:didFailSelector withObject:ticket withObject:nil];
        } else {
            self.requestFailedBlock(ticket, nil);
        }
        
		[ticket release];
	}
}

- (void)cancel {
	if (connection) {
		[connection cancel];
		[connection release];
		connection = nil;
	}
    [responseData setLength:0];
}

- (void)dealloc {
	if (request) [request release];
	if (connection) [connection release];
	if (response) [response release];
	if (responseData) [responseData release];
    if (requestSucceededBlock) Block_release(requestSucceededBlock);
    if (requestFailedBlock) Block_release(requestFailedBlock);
    delegate = nil;
	[super dealloc];
}

#pragma mark -
#pragma mark NSURLConnection Delegate methods

- (void)connection:(NSURLConnection *)aConnection didReceiveResponse:(NSURLResponse *)aResponse {
	if (response) {
		[response release];
    }
	response = [aResponse retain];
    
	[responseData setLength:0];
}

- (void)connection:(NSURLConnection *)aConnection didReceiveData:(NSData *)data {
	[responseData appendData:data];
}

- (void)connection:(NSURLConnection *)aConnection didFailWithError:(NSError *)error {
	OAServiceTicket *ticket = [[OAServiceTicket alloc]initWithRequest:request response:response didSucceed:NO];
    
    if (delegate) {
        [delegate performSelector:didFailSelector withObject:ticket withObject:error];
    } else {
        self.requestFailedBlock(ticket, error);
    }
	
	[ticket release];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection {
	OAServiceTicket *ticket = [[OAServiceTicket alloc]initWithRequest:request response:response didSucceed:[(NSHTTPURLResponse *)response statusCode] < 400];
    
    if (delegate) {
        [delegate performSelector:didFinishSelector withObject:ticket withObject:responseData];
    } else {
        self.requestSucceededBlock(ticket, responseData);
    }
	
	[ticket release];
    
    [responseData setLength:0];
}

@end
