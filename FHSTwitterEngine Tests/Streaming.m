//
//  Streaming.m
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 7/26/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "StreamParser.h"

@interface Streaming : XCTestCase

@end

@implementation Streaming

- (void)testStreamParsing {
    NSData *streamData = [@"6\r\ntest\r\nsomeotherbs" dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString *body = [[NSString alloc]initWithData:[StreamParser parseStreamData:streamData].firstObject encoding:NSUTF8StringEncoding];
    
    XCTAssert([body isEqualToString:@"test\r\n"], @"Failed to parse stream data.");
}

@end
