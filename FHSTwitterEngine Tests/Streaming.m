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

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testStreamParsing {
    NSData *streamData = [@"6\r\ntest\r\nsomeotherbs" dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString *body = [[NSString alloc]initWithData:[StreamParser parseStreamData:streamData].firstObject encoding:NSUTF8StringEncoding];
    NSLog(@"body: %@",body);
    
    XCTAssert([body isEqualToString:@"test\r\n"], @"Failed to parse stream data.");
}

- (void)testStreamEndsAbruptly {
    NSData *streamDataAbrupt = [@"6\r\nte" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *streamData = [@"6\r\ntest\r\n" dataUsingEncoding:NSUTF8StringEncoding];
    
    XCTAssert([StreamParser endsAbruptly:streamDataAbrupt], @"Abruptly ending data should return true.");
    XCTAssert(![StreamParser endsAbruptly:streamData], @"Normal data should return false.");
}

@end
