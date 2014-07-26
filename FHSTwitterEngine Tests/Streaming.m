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

- (void)tearDown {
   // [NSThread sleepForTimeInterval:MAXFLOAT];
    [super tearDown];
}

- (void)testStreamParsing {
    NSString *streamingString = @"6\r\nfood\r\n8\r\nfoodie\r\n9999\r\nleftovers";
    NSLog(@"Test Data Length: %lu",(unsigned long)streamingString.length);
    NSData *streamData = [streamingString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSData *leftoverData;
    NSArray *messages = [StreamParser parseStreamData:streamData leftoverData:&leftoverData];
    
    NSLog(@"Parsed.");
    
    NSString *food = [[NSString alloc]initWithData:messages[0] encoding:NSUTF8StringEncoding];
    NSString *foodie = [[NSString alloc]initWithData:messages[1] encoding:NSUTF8StringEncoding];
    
    NSString *leftovers = [[NSString alloc]initWithData:leftoverData encoding:NSUTF8StringEncoding];
    
    XCTAssert([food isEqualToString:@"food\r\n"], @"Failed to parse stream data.");
    XCTAssert([foodie isEqualToString:@"foodie\r\n"], @"Failed to parse stream data.");
    XCTAssert([leftovers isEqualToString:@"leftovers"], @"Failed to capture leftover data (captured: %@)",leftovers);
}

@end
