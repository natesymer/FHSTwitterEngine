//
//  StreamParser.m
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 7/25/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import "StreamParser.h"

@implementation StreamParser

+ (NSArray *)parseStreamData:(NSData *)data {
    NSMutableArray *messages = [NSMutableArray array];
    
    char *chars = (char *)data.bytes;
    unsigned long length = data.length;
    
    // Newline: 10, Carriage Return: 13
    
    unsigned long position = 0;
    int inMessage = 0;
    unsigned long messageStart = 0;
    int bufferLength = 0;
    char *buffer = NULL;
    
    while (position < length) {
        char currChar = chars[position];
        if ((currChar > '0' && currChar < '9') && !inMessage) {
            // Handle numeric value
            
            unsigned long delimBufLength = 2;
            unsigned long delimBufCount = 0;
            char *delimBuf = malloc(sizeof(char *)*delimBufLength);

            while (currChar > '0' && currChar < '9') {
                // Expand buffer accordingly
                if (delimBufCount+1 > delimBufLength) {
                    delimBufLength += 2;
                    char *newbuf = malloc(sizeof(char *)*delimBufLength);
                    memcpy(newbuf, delimBuf, sizeof(char *)*delimBufCount);
                    free(delimBuf);
                    delimBuf = newbuf;
                }
                
                delimBuf[delimBufCount] = currChar;
                delimBufCount++;
                position++;
                currChar = chars[position];
            }

            position += 2;
            messageStart = position;
            
            bufferLength = strtold(delimBuf, NULL);
            bufferLength = atoi(delimBuf);
            free(delimBuf);
            
            if (buffer) {
                free(buffer);
                buffer = NULL;
            }
            
            buffer = malloc(sizeof(char *)*bufferLength);
            
            inMessage = 1;
            continue;
        } else {
            
            if (!buffer) {
                buffer = malloc(sizeof(char *)*bufferLength);
            }
            
            buffer[position-messageStart] = currChar;
            
            position++;
        }

        if (position == messageStart+bufferLength) {
            [messages addObject:[NSData dataWithBytes:buffer length:bufferLength]];
            inMessage = 0;
        }
    }
    
    return messages;
}

@end
