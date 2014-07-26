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
    unsigned long messageStart = 0;
    int bufferLength = 0;
    char *buffer = NULL;
    
    while (position < length) {
        char currChar = chars[position];
        if (currChar >= '0' && currChar <= '9' && inMessage == 0) {
            
            // Create a buffer to hold bytes that
            // Represent the length of the message
            unsigned long delimBufLength = kDelimiterBufferStartingLength;
            unsigned long delimBufCount = 0;
            char *delimBuf = malloc(sizeof(char)*delimBufLength);

            // Read characters into the buffer until
            // the characters are no longer numeric
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
            
            // If the next two characters are a CRLF
            // setup the message buffer
            if (currChar == '\r' && chars[position+1] == '\n') {
                // this is an assumption that delimBuf exists
                bufferLength = atoi(delimBuf);
                free(delimBuf);
                delimBuf = NULL;
                
                // Move to the first character in the message
                position += 2;
                messageStart = position;
                currChar = chars[position];
                inMessage = 1;

                // Check if the data includes the whole message
                unsigned long remainingBytes = length-position;

                // Return the leftover data using a pointer
                // and return the array of complete messages
                if (remainingBytes < bufferLength) {
                    if (leftoverData) {
                        // Read leftover bytes into a buffer
                        if (remainingBytes > 0) {
                            char *leftoverBytes = malloc(sizeof(char)*remainingBytes);
                            
                            for (unsigned long i = 0; i < remainingBytes; i++) {
                                leftoverBytes[i] = chars[position+i];
                            }
                            
                            // Use the pointer to return the leftover data.
                            *leftoverData = [NSData dataWithBytes:leftoverBytes length:remainingBytes];
                            
                            // Free that buffer
                            free(leftoverBytes);
                            leftoverBytes = NULL;
                        }
                    }
                    return messages;
                } else {
                    // otherwise, create the message buffer

                    if (buffer) {
                        // Sometimes crashes here
                        //
                        // FHSTwitterEngine(5166,0x102c9d310) malloc: *** error for object 0x10ac4ad28: incorrect checksum for freed object - object was probably modified after being freed.
                        // *** set a breakpoint in malloc_error_break to debug
                      //  NSLog(@"Buffer: %s",buffer);
                        free(buffer);
                        buffer = NULL;
                    }
                    
                    buffer = malloc(sizeof(char)*bufferLength);
                }
            } else if (delimBuf) {
                if (!buffer) {
                    // Ensure the message buffer length is always accurate.
                    // We might have changed it, and this may change it back.
                    bufferLength = 0;
                }
                free(delimBuf);
                delimBuf = NULL;
            }
            
            continue;
        } else if (inMessage == 1) {
            if (!buffer) {
                // If no message length has been established
                // (this means this payload contains the other
                // half of the previous payload's last and incomplete message)
                
                // Let's look for the next length delimiter.
                
                // Since all messages end with a CRLF (\r\n),
                // Let's look for it. It will tell us where the next
                // length delimiter is.
                while (currChar != '\r') {
                    position++;
                    
                    // Could not find a CR
                    if (position == length) {
                        // This means that this payload did not contain
                        // any messages, and therefore it's safe to say that
                        // it contains an error.
                        NSMutableData *errorJson = [[@"{\"error\":\"" dataUsingEncoding:NSUTF8StringEncoding]mutableCopy];
                        [errorJson appendData:data];
                        [errorJson appendData:[@"\"}" dataUsingEncoding:NSUTF8StringEncoding]];
                        return @[errorJson];
                    } else {
                        // advance the current character
                        currChar = chars[position];
                    }
                }
                
                // move to beginning of length delimiter from CR
                position += 2;
                inMessage = 0;
                continue;
            }
            buffer[position-messageStart] = currChar;

            // If we've got to the end of a message,
            // let's turn it into an ObjC object and
            // put it in an array.
            if (position == messageStart+bufferLength-1) {
                [messages addObject:[NSData dataWithBytes:buffer length:bufferLength]];
                inMessage = 0;
            }
            
            position++;
            continue;
        } else {
            // In the length delimiter field and there's a non-numerical character
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
