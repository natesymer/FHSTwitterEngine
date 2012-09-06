//
//  OAAsynchronousDataFetcher.h
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

#import <Foundation/Foundation.h>

#import "OAMutableURLRequest.h"

@interface OAAsynchronousDataFetcher : NSObject {
    OAMutableURLRequest *request;
    NSURLResponse *response;
    NSURLConnection *connection;
    NSMutableData *responseData;
    id delegate;
    SEL didFinishSelector;
    SEL didFailSelector;	
}

@property (copy) void (^requestSucceededBlock)(id, id);
@property (copy) void (^requestFailedBlock)(id, id);

@property (nonatomic, assign) NSURLResponse *response;
@property (nonatomic, assign) OAMutableURLRequest *request;
@property (nonatomic, assign) NSMutableData *responseData;
@property (nonatomic, assign) NSURLConnection *connection;

+ (id)asynchronousDataFetcherWithRequest:(OAMutableURLRequest *)aRequest delegate:(id)aDelegate didFinishSelector:(SEL)finishSelector didFailSelector:(SEL)failSelector;
- (id)initWithRequest:(OAMutableURLRequest *)aRequest delegate:(id)aDelegate didFinishSelector:(SEL)finishSelector didFailSelector:(SEL)failSelector;

+ (id)asynchronousDataFetcherWithRequest:(OAMutableURLRequest *)aRequest didFinishBlock:(void (^)(id ticket, id data))finishBlock didFailBlock:(void (^)(id ticket, id error))failBlock;
- (id)initWithRequest:(OAMutableURLRequest *)aRequest didFinishBlock:(void (^)(id ticket, id data))finishBlock didFailBlock:(void (^)(id ticket, id error))failBlock;

- (void)setDidFinishSelector:(SEL)aSelector;
- (void)setDidFailSelector:(SEL)aSelector;
- (void)setDidFailBlock:(void (^)(id ticket, id error))failBlock;
- (void)setDidFinishBlock:(void (^)(id ticket, id data))finishBlock;
- (id)delegate;
- (void)setDelegate:(id)aDelegate;

- (void)start;
- (void)cancel;

@end
