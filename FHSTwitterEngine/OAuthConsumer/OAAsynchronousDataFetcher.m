//
//  OAAsynchronousDataFetcher.m
//  OAuthConsumer
//
//  Created by Zsombor Szabó on 12/3/08.
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

@synthesize response, request, responseData, connection;

#pragma mark -
#pragma mark Object creation methods

+ (id)asynchronousDataFetcherWithRequest:(OAMutableURLRequest *)aRequest {
    return [[[OAAsynchronousDataFetcher alloc]initWithRequest:aRequest]autorelease];
}

- (id)initWithRequest:(OAMutableURLRequest *)aRequest {
    self = [super init];
	if (self) {
		self.request = [aRequest retain];
        self.responseData = [[NSMutableData alloc]init];
	}
	return self;
}

- (id)init {
    self = [super init];
    if (self) {
        self.responseData = [[NSMutableData alloc]init];
    }
    return self;
}

- (void)dealloc {
    [self setRequest:nil];
    [self setConnection:nil];
    [self setResponse:nil];
    [self.responseData setLength:0];
	[self setResponseData:nil];
	[super dealloc];
}

- (void)callBlockWithTicket:(OAServiceTicket *)ticket data:(NSData *)data error:(NSError *)error {
    requestFinishedBlock(ticket, data, error);
    [self setRequest:nil];
    [self setConnection:nil];
    [self setResponse:nil];
    [self.responseData setLength:0];
    Block_release(requestFinishedBlock);
}

#pragma mark -
#pragma mark Connection management methods

- (void)startWithBlock:(void (^)(OAServiceTicket *, NSData *, NSError *))block {
    
    requestFinishedBlock = Block_copy(block);
    
    [self.request prepare];
	
    [self setConnection:[NSURLConnection connectionWithRequest:self.request delegate:self]];
    
	if (self.connection) {
		[self.responseData setLength:0];
	} else {
        OAServiceTicket *ticket = [[OAServiceTicket alloc]initWithRequest:request response:nil didSucceed:NO];
        [self callBlockWithTicket:ticket data:nil error:[NSError errorWithDomain:@"Connection could not be created." code:1 userInfo:nil]];
        [ticket release];
	}
}

- (void)cancel {
    [self.connection cancel];
    [self setConnection:nil];
    [self.responseData setLength:0];
}

#pragma mark -
#pragma mark NSURLConnection Delegate methods

- (void)connection:(NSURLConnection *)aConnection didReceiveResponse:(NSURLResponse *)aResponse {
    [self setResponse:aResponse];
	[self.responseData setLength:0];
}

- (void)connection:(NSURLConnection *)aConnection didReceiveData:(NSData *)data {
	[self.responseData appendData:data];
}

- (void)connection:(NSURLConnection *)aConnection didFailWithError:(NSError *)error {
	OAServiceTicket *ticket = [[OAServiceTicket alloc]initWithRequest:request response:response didSucceed:NO];
    [self callBlockWithTicket:ticket data:nil error:error];
	[ticket release];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection {
	OAServiceTicket *ticket = [[OAServiceTicket alloc]initWithRequest:request response:response didSucceed:[(NSHTTPURLResponse *)response statusCode] < 400];
    [self callBlockWithTicket:ticket data:responseData error:nil];
	[ticket release];
}

@end
