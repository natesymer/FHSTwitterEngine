//
//  StreamParser.m
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 7/25/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import "StreamParser.h"

static unsigned long const kDelimiterBufferStartingLength = 3;

@implementation StreamParser

+ (NSArray *)parseStreamData:(NSData *)data {
    return [self parseStreamData:data leftoverData:NULL];
}

+ (NSArray *)parseStreamData:(NSData *)data leftoverData:(NSData **)leftoverData {
    NSMutableArray *messages = [NSMutableArray array];
    
    char *chars = (char *)data.bytes;
    unsigned long length = data.length;
    
    //
    // TODO: Check for delimiting kind
    //       (Right now `length` delimiting is assumed)
    //
    
    // Check for data not delimited by length
    // It's impossible to determine if this data is
    // cut off or not, unless you want to track brackets.
    /*for (unsigned long i = 0; i < length; i++) {
        
    }*/
    
    // @"Exceeded connection limit for user\r\n"
    if (chars[0] == 'E' && chars[length-3] == 'r') {
        return @[[@"{\"error\": \"Exceeded connection limit for user.\" }\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }

    int inMessage = 0;
    
    unsigned long position = 0;
    unsigned long messageStart = -1;
    int bufferLength = -1;
    char *buffer = NULL;
    
    while (position < length) {
        char currChar = chars[position];
        if ((currChar > '0' && currChar < '9') && !inMessage) {
            unsigned long delimBufLength = kDelimiterBufferStartingLength;
            unsigned long delimBufCount = 0;
            char *delimBuf = malloc(sizeof(char)*delimBufLength);

            while (currChar >= '0' && currChar <= '9') {
                // Expand buffer accordingly
                if (delimBufCount+1 > delimBufLength) {
                    delimBufLength += 2;
                    char *newbuf = malloc(sizeof(char)*delimBufLength);
                    memcpy(newbuf, delimBuf, sizeof(char)*delimBufCount);
                    if (delimBuf) free(delimBuf);
                    delimBuf = newbuf;
                }
                
                delimBuf[delimBufCount] = currChar;
                delimBufCount++;
                position++; // This will bleed over into the byte after the length delimiter (the CR)
                currChar = chars[position];
            }
            
            if (currChar == '\r' && chars[position+1] == '\n') {
                bufferLength = atoi(delimBuf);
                free(delimBuf);
                delimBuf = NULL;
                
                position += 2; // accommodate for the LF
                messageStart = position;
                currChar = chars[position];

                if (position+bufferLength > length) {
                    
                    unsigned long numLeftoverBytes = bufferLength-(length-(position+1));
                    NSLog(@"Leftover Bytes: %lu",numLeftoverBytes);
                    
                    if (leftoverData) {
                        // capture leftover data
                        if (numLeftoverBytes > 0) {
                            char *leftoverBytes = malloc(sizeof(char)*numLeftoverBytes);
                        
                            for (unsigned long i = 0; i < numLeftoverBytes; i++) {
                                leftoverBytes[i] = chars[position+i];
                            }
                            
                            *leftoverData = [NSData dataWithBytes:leftoverBytes length:numLeftoverBytes];
                            free(leftoverBytes);
                            leftoverBytes = NULL;
                        }
                    }
                    return messages;
                }
                
                if (buffer) {
                    free(buffer);
                    buffer = NULL;
                }
                
                buffer = malloc(sizeof(char)*bufferLength);
                
                inMessage = 1;
            } else if (delimBuf) {
                free(delimBuf);
                delimBuf = NULL;
            }
            
            continue;
        } else {
            if (!buffer) {
                // It's the second half of some leftover data...
                // Let's skip it.
                
                // look for next \r\n and set position to that place
                while (currChar != '\r') {
                    position++;
                    
                    // Could not find a CR
                    if (position == length) {
                        // Return some error JSON
                        NSMutableData *errorJson = [[@"{\"error\":\"" dataUsingEncoding:NSUTF8StringEncoding]mutableCopy];
                        [errorJson appendData:data];
                        [errorJson appendData:[@"\"}" dataUsingEncoding:NSUTF8StringEncoding]];
                        return @[errorJson];
                    } else {
                        currChar = chars[position];
                    }
                }
                
                position += 2;
                inMessage = 0;
                continue;
            }
            buffer[position-messageStart] = currChar;
            
            if (position == messageStart+bufferLength-1) {
                [messages addObject:[NSData dataWithBytes:buffer length:bufferLength]];
                inMessage = 0;
            }
            
            position++;
            continue;
        }
    }
    
    if (buffer) {
        free(buffer);
        buffer = NULL;
    }
    
    return messages;
}

- (NSArray *)parseUndelemitedData:(NSData *)data {
    NSString *dString = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    NSArray *parts = [dString componentsSeparatedByString:@"\r\n"];
    NSMutableArray *messages = [NSMutableArray array];
    
    for (NSString *s in parts) {
        [messages addObject:[s dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    return parts;
}

@end
