//
//  NSMutableURLRequest+NSMutableURLRequest_sendSync.h
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 9/6/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableURLRequest (NSMutableURLRequest_sendSync)

- (NSData *)sendSynchronousConnection;

@end
