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

+ (BOOL)startsAbruptly:(NSData *)data {
    char *chars = (char *)data.bytes;
    unsigned long length = data.length;
    
    // check the first 20 characters for CRLF
    
    BOOL startsAbruptly = YES;
    
    for (unsigned long i = 0; i < MIN(20,length-1); i++) {
        if (chars[i] == '\r' && chars[i+1] == '\n') {
            startsAbruptly = NO;
            break;
        }
    }
    return startsAbruptly;
}

+ (BOOL)endsAbruptly:(NSData *)data {
    char *chars = (char *)data.bytes;
    unsigned long length = data.length;
    
    BOOL endsAbruptly = NO;
    
    unsigned long pos = length-1;
    
    while (pos > 0) {
        if (chars[pos-1] == '\r' && chars[pos] == '\n') {
            char currChar = chars[pos-2];
            
            unsigned long delimBufLength = kDelimiterBufferStartingLength;
            unsigned long delimBufCount = 0;
            char *delimBuf = malloc(sizeof(char *)*delimBufLength);
            
            while (currChar > '0' && currChar < '9') {
                if (pos == 0 || (chars[pos-1] == '\r' && chars[pos] == '\n')) break;
                // Expand buffer accordingly
                if (delimBufCount+1 > delimBufLength) {
                    delimBufLength += 2;
                    char *newbuf = malloc(sizeof(char *)*delimBufLength);
                    memcpy(newbuf, delimBuf, sizeof(char *)*delimBufCount);
                    if (delimBuf) free(delimBuf);
                    delimBuf = newbuf;
                }
                
                delimBuf[delimBufCount] = currChar;
                delimBufCount++;
                
                pos--;
                currChar = chars[pos];
            }
            
            int bufferLength = atoi(delimBuf);
            free(delimBuf);
            
            if (pos+delimBufCount+2+bufferLength != length) {
                endsAbruptly = YES;
            }
        }
        pos--;
    }
    
    return endsAbruptly;
}

+ (NSArray *)parseStreamData:(NSData *)data {
    NSMutableArray *messages = [NSMutableArray array];
    
    char *chars = (char *)data.bytes;
    unsigned long length = data.length;
    
    // @"Exceeded connection limit for user\r\n"
    if (chars[0] == 'E' && chars[length-3] == 'r') {
        return @[[@"{\"error\": \"Exceeded connection limit for user.\" }\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }

    // Newline: 10, Carriage Return: 13
    
    int inMessage = 0;
    
    unsigned long position = 0;
    unsigned long messageStart = 0;
    int bufferLength = 0;
    char *buffer = NULL;
    
    while (position < length) {
        char currChar = chars[position];
        if ((currChar > '0' && currChar < '9') && !inMessage) {
            unsigned long delimBufLength = kDelimiterBufferStartingLength;
            unsigned long delimBufCount = 0;
            char *delimBuf = malloc(sizeof(char *)*delimBufLength);

            while (currChar >= '0' && currChar <= '9') {
                // Expand buffer accordingly
                if (delimBufCount+1 > delimBufLength) {
                    delimBufLength += 2;
                    char *newbuf = malloc(sizeof(char *)*delimBufLength);
                    memcpy(newbuf, delimBuf, sizeof(char *)*delimBufCount);
                    if (delimBuf) free(delimBuf);
                    delimBuf = newbuf;
                }
                
                delimBuf[delimBufCount] = currChar;
                delimBufCount++;
                position++; // This will bleed over into the byte after the length delimiter (the CR)
                currChar = chars[position];
            }

            if (currChar == '\r' && chars[position+1] == '\n') {
                position += 2; // accommodate for the LF
                messageStart = position;
                
                bufferLength = atoi(delimBuf);
                free(delimBuf);
                delimBuf = NULL;
                
                if (buffer) {
                    free(buffer);
                    buffer = NULL;
                }
                
                buffer = malloc(sizeof(char *)*bufferLength);
                
                inMessage = 1;
            }
            
            if (delimBuf) {
                free(delimBuf);
                delimBuf = NULL;
            }
            
            continue;
        } else {
            if (!buffer) {
                printf("No buffer to accommodate character: %c (%d) at position: %lu\n",currChar,currChar,position);
            }
            buffer[position-messageStart] = currChar;
            
            if (position+1 == messageStart+bufferLength) {
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

@end
