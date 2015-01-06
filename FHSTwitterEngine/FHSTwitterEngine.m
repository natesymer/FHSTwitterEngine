//
//  FHSTwitterEngine.m
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 8/22/12.
//  Copyright (C) 2012 Nathaniel Symer.
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

#import "FHSTwitterEngine.h"

#import <QuartzCore/QuartzCore.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <CommonCrypto/CommonHMAC.h>
#import <objc/runtime.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <ifaddrs.h>

// Helper classes
#include "FHSStream.h"

static NSURLRequestCachePolicy const cachePolicy = NSURLRequestReloadRevalidatingCacheData;

static float const streamingTimeoutInterval = 30.0f;

static char const Encode[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

static NSString * const newPinJS = @"var d = document.getElementById('oauth-pin'); if (d == null) d = document.getElementById('oauth_pin'); if (d) { var d2 = d.getElementsByTagName('code'); if (d2.length > 0) d2[0].innerHTML; }";
static NSString * const oldPinJS = @"var d = document.getElementById('oauth-pin'); if (d == null) d = document.getElementById('oauth_pin'); if (d) d = d.innerHTML; d;";

NSString * const FHSProfileBackgroundColorKey = @"profile_background_color";
NSString * const FHSProfileLinkColorKey = @"profile_link_color";
NSString * const FHSProfileSidebarBorderColorKey = @"profile_sidebar_border_color";
NSString * const FHSProfileSidebarFillColorKey = @"profile_sidebar_fill_color";
NSString * const FHSProfileTextColorKey = @"profile_text_color";

NSString * const FHSProfileNameKey = @"name";
NSString * const FHSProfileURLKey = @"url";
NSString * const FHSProfileLocationKey = @"location";
NSString * const FHSProfileDescriptionKey = @"description";

NSString * const FHSErrorDomain = @"FHSErrorDomain";

static NSString * const authBlockKey = @"FHSTwitterEngineOAuthCompletion";

//
// URL constants
//

static NSString * const url_search_tweets = @"https://api.twitter.com/1.1/search/tweets.json";

static NSString * const url_users_search = @"https://api.twitter.com/1.1/users/search.json";
static NSString * const url_users_show = @"https://api.twitter.com/1.1/users/show.json";
static NSString * const url_users_report_spam = @"https://api.twitter.com/1.1/users/report_spam.json";
static NSString * const url_users_lookup = @"https://api.twitter.com/1.1/users/lookup.json";

static NSString * const url_lists_create = @"https://api.twitter.com/1.1/lists/create.json";
static NSString * const url_lists_show = @"https://api.twitter.com/1.1/lists/show.json";
static NSString * const url_lists_update = @"https://api.twitter.com/1.1/lists/update.json";
static NSString * const url_lists_members = @"https://api.twitter.com/1.1/lists/members.json";
static NSString * const url_lists_members_destroy_all = @"https://api.twitter.com/1.1/lists/members/destroy_all.json";
static NSString * const url_lists_members_create_all = @"https://api.twitter.com/1.1/lists/members/create_all.json";
static NSString * const url_lists_statuses = @"https://api.twitter.com/1.1/lists/statuses.json";
static NSString * const url_lists_list = @"https://api.twitter.com/1.1/lists/list.json";

static NSString * const url_statuses_home_timeline = @"https://api.twitter.com/1.1/statuses/home_timeline.json";
static NSString * const url_statuses_update = @"https://api.twitter.com/1.1/statuses/update.json";
static NSString * const url_statuses_retweets_of_me = @"https://api.twitter.com/1.1/statuses/retweets_of_me.json";
static NSString * const url_statuses_user_timeline = @"https://api.twitter.com/1.1/statuses/user_timeline.json";
static NSString * const url_statuses_metions_timeline = @"https://api.twitter.com/1.1/statuses/mentions_timeline.json";
static NSString * const url_statuses_update_with_media = @"https://api.twitter.com/1.1/statuses/update_with_media.json";
static NSString * const url_statuses_destroy = @"https://api.twitter.com/1.1/statuses/destroy.json";
static NSString * const url_statuses_show = @"https://api.twitter.com/1.1/statuses/show.json";

static NSString * const url_blocks_exists = @"https://api.twitter.com/1.1/blocks/exists.json";
static NSString * const url_blocks_blocking = @"https://api.twitter.com/1.1/blocks/blocking.json";
static NSString * const url_blocks_blocking_ids = @"https://api.twitter.com/1.1/blocks/blocking/ids.json";
static NSString * const url_blocks_destroy = @"https://api.twitter.com/1.1/blocks/destroy.json";
static NSString * const url_blocks_create = @"https://api.twitter.com/1.1/blocks/create.json";

static NSString * const url_help_languages = @"https://api.twitter.com/1.1/help/languages.json";
static NSString * const url_help_configuration = @"https://api.twitter.com/1.1/help/configuration.json";
static NSString * const url_help_privacy = @"https://api.twitter.com/1.1/help/privacy.json";
static NSString * const url_help_tos = @"https://api.twitter.com/1.1/help/tos.json";
static NSString * const url_help_test = @"https://api.twitter.com/1.1/help/test.json";

static NSString * const url_direct_messages_show = @"https://api.twitter.com/1.1/direct_messages/show.json";
static NSString * const url_direct_messages_new = @"https://api.twitter.com/1.1/direct_messages/new.json";
static NSString * const url_direct_messages_sent = @"https://api.twitter.com/1.1/direct_messages/sent.json";
static NSString * const url_direct_messages_destroy = @"https://api.twitter.com/1.1/direct_messages/destroy.json";
static NSString * const url_direct_messages = @"https://api.twitter.com/1.1/direct_messages.json";

static NSString * const url_friendships_no_retweets_ids = @"https://api.twitter.com/1.1/friendships/no_retweets/ids.json";
static NSString * const url_friendships_update = @"https://api.twitter.com/1.1/friendships/update.json";
static NSString * const url_friendships_outgoing = @"https://api.twitter.com/1.1/friendships/outgoing.json";
static NSString * const url_friendships_incoming = @"https://api.twitter.com/1.1/friendships/incoming.json";
static NSString * const url_friendships_lookup = @"https://api.twitter.com/1.1/friendships/lookup.json";
static NSString * const url_friendships_destroy = @"https://api.twitter.com/1.1/friendships/destroy.json";
static NSString * const url_friendships_create = @"https://api.twitter.com/1.1/friendships/create.json";

static NSString * const url_account_verify_credentials = @"https://api.twitter.com/1.1/account/verify_credentials.json";
static NSString * const url_account_update_profile_colors = @"https://api.twitter.com/1.1/account/update_profile_colors.json";
static NSString * const url_account_update_profile_background_image = @"https://api.twitter.com/1.1/account/update_profile_background_image.json";
static NSString * const url_account_update_profile_image = @"https://api.twitter.com/1.1/account/update_profile_image.json";
static NSString * const url_account_settings = @"https://api.twitter.com/1.1/account/settings.json";
static NSString * const url_account_update_profile = @"https://api.twitter.com/1.1/account/update_profile.json";

static NSString * const url_favorites_list = @"https://api.twitter.com/1.1/favorites/list.json";
static NSString * const url_favorites_create = @"https://api.twitter.com/1.1/favorites/create.json";
static NSString * const url_favorites_destroy = @"https://api.twitter.com/1.1/favorites/destroy.json";

static NSString * const url_application_rate_limit_status = @"https://api.twitter.com/1.1/application/rate_limit_status.json";

static NSString * const url_followers_ids = @"https://api.twitter.com/1.1/followers/ids.json";
static NSString * const url_followers_list = @"https://api.twitter.com/1.1/followers/list.json";

static NSString * const url_friends_ids = @"https://api.twitter.com/1.1/friends/ids.json";
static NSString * const url_friends_list = @"https://api.twitter.com/1.1/friends/list.json";


NSString * fhs_url_remove_params(NSURL *url) {
    if (url.absoluteString.length == 0) {
        return nil;
    }
    
    NSArray *parts = [url.absoluteString componentsSeparatedByString:@"?"];
    return (parts.count == 0)?nil:parts[0];
}

id removeNull(id rootObject) {
    if ([rootObject isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *sanitizedDictionary = [NSMutableDictionary dictionaryWithDictionary:rootObject];
        [rootObject enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            id sanitized = removeNull(obj);
            if (!sanitized) {
                [sanitizedDictionary setObject:@"" forKey:key];
            } else {
                [sanitizedDictionary setObject:sanitized forKey:key];
            }
        }];
        return [NSMutableDictionary dictionaryWithDictionary:sanitizedDictionary];
    }
    
    if ([rootObject isKindOfClass:[NSArray class]]) {
        NSMutableArray *sanitizedArray = [NSMutableArray arrayWithArray:rootObject];
        [rootObject enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            id sanitized = removeNull(obj);
            if (!sanitized) {
                [sanitizedArray replaceObjectAtIndex:[sanitizedArray indexOfObject:obj] withObject:@""];
            } else {
                [sanitizedArray replaceObjectAtIndex:[sanitizedArray indexOfObject:obj] withObject:sanitized];
            }
        }];
        return [NSMutableArray arrayWithArray:sanitizedArray];
    }

    if ([rootObject isKindOfClass:[NSNull class]]) {
        return (id)nil;
    } else {
        return rootObject;
    }
}

@interface FHSConsumer : NSObject

@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSString *secret;

+ (FHSConsumer *)consumerWithKey:(NSString *)key secret:(NSString *)secret;

@end

@implementation FHSConsumer

+ (FHSConsumer *)consumerWithKey:(NSString *)key secret:(NSString *)secret {
    return [[[self class]alloc]initWithKey:key secret:secret];
}

- (instancetype)initWithKey:(NSString *)key secret:(NSString *)secret {
    self = [super init];
    if (self) {
        self.key = key;
        self.secret = secret;
    }
    return self;
}

@end

@implementation FHSToken

+ (FHSToken *)tokenWithHTTPResponseBody:(NSString *)body {
    return [[[self class]alloc]initWithHTTPResponseBody:body];
}

- (id)initWithHTTPResponseBody:(NSString *)body {
    self = [super init];
	if (self) {
        
        if (body.length > 0) {
            NSArray *pairs = [body componentsSeparatedByString:@"&"];
            
            for (NSString *pair in pairs) {
                
                NSArray *elements = [pair componentsSeparatedByString:@"="];
                
                if (elements.count > 1) {
                    NSString *field = elements[0];
                    NSString *value = elements[1];
                    
                    if ([field isEqualToString:@"oauth_token"]) {
                        self.key = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                    } else if ([field isEqualToString:@"oauth_token_secret"]) {
                        self.secret = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                    }
                }
            }
        }
	}
    
    return self;
}

@end

@interface FHSTwitterEngineController : UIViewController <UIWebViewDelegate> 

@property (nonatomic, strong) UINavigationBar *navBar;
@property (nonatomic, strong) UIWebView *theWebView;
@property (nonatomic, strong) UILabel *loadingText;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) FHSToken *requestToken;

@end

@interface FHSTwitterEngine ()

// Login stuff
- (NSString *)getRequestTokenString;

// General Get request sender
- (id)sendRequest:(NSURLRequest *)request;

// These are here to obfuscate them from prying eyes
@property (strong, nonatomic) FHSConsumer *consumer;
@property (assign, nonatomic) BOOL shouldClearConsumer;

@end

@implementation NSError (FHSTwitterEngine)

+ (NSError *)badRequestError {
    return [NSError errorWithDomain:FHSErrorDomain code:400 userInfo:@{NSLocalizedDescriptionKey:@"The request has missing or malformed parameters."}];
}

+ (NSError *)noDataError {
    return [NSError errorWithDomain:FHSErrorDomain code:204 userInfo:@{NSLocalizedDescriptionKey:@"The request did not return any content."}];
}

+ (NSError *)imageTooLargeError {
    return [NSError errorWithDomain:FHSErrorDomain code:422 userInfo:@{NSLocalizedDescriptionKey:@"The image you are trying to upload is too large."}];
}

@end

@implementation NSString (FHSTwitterEngine)

- (NSString *)fhs_URLEncode {
    CFStringRef url = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)self, NULL, CFSTR("!*'();:@&=+$,/?%#[]"), kCFStringEncodingUTF8);
	return (__bridge NSString *)url;
}

- (NSString *)fhs_truncatedToLength:(int)length {
    return [self substringToIndex:MIN(length, self.length)];
}

- (NSString *)fhs_trimForTwitter {
    return [self fhs_truncatedToLength:140];
}

- (NSString *)fhs_stringWithRange:(NSRange)range {
    return [[self substringFromIndex:range.location]substringToIndex:range.length];
}

+ (NSString *)fhs_UUID {
    if ([[[UIDevice currentDevice]systemVersion]floatValue] >= 6.0f) {
        return [[NSUUID UUID]UUIDString];
    } else {
        CFUUIDRef theUUID = CFUUIDCreate(kCFAllocatorDefault);
        CFStringRef string = CFUUIDCreateString(kCFAllocatorDefault, theUUID);
        CFRelease(theUUID);
        NSString *uuid = [NSString stringWithString:(__bridge NSString *)string];
        CFRelease(string);
        return uuid;
    }
}

- (BOOL)fhs_isNumeric {
	const char *raw = (const char *)[self UTF8String];
    
	for (int i = 0; i < strlen(raw); i++) {
		if (raw[i] < '0' || raw[i] > '9') {
            return NO;
        }
	}
	return YES;
}

@end

@implementation NSData (FHSTwitterEngine)

- (NSString *)appropriateFileExtension {
    uint8_t c;
    [self getBytes:&c length:1];
    
    switch (c) {
        case 0xFF:
            return @"jpeg";
        case 0x89:
            return @"png";
        case 0x47:
            return @"gif";
        case 0x49:
        case 0x4D:
            return @"tiff";
    }
    return nil;
}

- (NSString *)base64Encode {
    int outLength = ((((self.length*4)/3)/4)*4)+(((self.length*4)/3)%4?4:0);
    const char *inputBuffer = self.bytes;
    char *outputBuffer = malloc(outLength+1);
    outputBuffer[outLength] = 0;
    
    int cycle = 0;
    int inpos = 0;
    int outpos = 0;
    char temp;
    
    outputBuffer[outLength-1] = '=';
    outputBuffer[outLength-2] = '=';
    
    while (inpos < self.length) {
        switch (cycle) {
            case 0:
                outputBuffer[outpos++] = Encode[(inputBuffer[inpos]&0xFC)>>2];
                cycle = 1;
                break;
            case 1:
                temp = (inputBuffer[inpos++]&0x03)<<4;
                outputBuffer[outpos] = Encode[temp];
                cycle = 2;
                break;
            case 2:
                outputBuffer[outpos++] = Encode[temp|(inputBuffer[inpos]&0xF0)>>4];
                temp = (inputBuffer[inpos++]&0x0F)<<2;
                outputBuffer[outpos] = Encode[temp];
                cycle = 3;
                break;
            case 3:
                outputBuffer[outpos++] = Encode[temp|(inputBuffer[inpos]&0xC0)>>6];
                cycle = 4;
                break;
            case 4:
                outputBuffer[outpos++] = Encode[inputBuffer[inpos++]&0x3f];
                cycle = 0;
                break;
            default:
                cycle = 0;
                break;
        }
    }
    NSString *pictemp = [NSString stringWithUTF8String:outputBuffer];
    free(outputBuffer);
    return pictemp;
}

@end

@implementation FHSTwitterEngine

- (id)listFollowersForUser:(NSString *)user isID:(BOOL)isID withCursor:(NSString *)cursor {
    
    if (user.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_followers_list];
    
    return [self sendGETRequestForURL:baseURL andParams:@{@"skip_status":@"true", @"include_entities":(_includeEntities?@"true":@"false"), (isID?@"user_id":@"screen_name"):user, @"cursor":cursor }];
}

- (id)listFriendsForUser:(NSString *)user isID:(BOOL)isID withCursor:(NSString *)cursor {
    
    if (user.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_friends_list];
    return [self sendGETRequestForURL:baseURL andParams:@{@"skip_status":@"true", @"include_entities":(_includeEntities?@"true":@"false"), (isID?@"user_id":@"screen_name"):user, @"cursor":cursor }];
}

- (id)searchUsersWithQuery:(NSString *)q andCount:(int)count {
    if (count == 0) {
        return nil;
    }
    
    if (q.length == 0) {
        return [NSError badRequestError];
    }
    
    if (q.length > 1000) {
        q = [q substringToIndex:1000];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_users_search];
    return [self sendGETRequestForURL:baseURL andParams:@{ @"include_entities":(_includeEntities?@"true":@"false"), @"count":@(count).stringValue, @"q":q }];
}

- (id)searchTweetsWithQuery:(NSString *)q count:(int)count resultType:(FHSTwitterEngineResultType)resultType unil:(NSDate *)untilDate sinceID:(NSString *)sinceID maxID:(NSString *)maxID {
    
    if (count == 0) {
        return nil;
    }
    
    if (q.length == 0) {
        return [NSError badRequestError];
    }
    
    if (q.length > 1000) {
        q = [q substringToIndex:1000];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_search_tweets];
    
    NSMutableDictionary *params = [@{ @"include_entities":(_includeEntities?@"true":@"false"), @"count":@(count).stringValue, @"q":q } mutableCopy];
    
    [_dateFormatter setDateFormat:@"YYYY-MM-DD"];
    params[@"until"] = [_dateFormatter stringFromDate:untilDate];
    [_dateFormatter setDateFormat:@"EEE MMM dd HH:mm:ss ZZZZ yyyy"];

    if (resultType == FHSTwitterEngineResultTypeMixed) {
        params[@"result_type"] = @"mixed";
    } else if (resultType == FHSTwitterEngineResultTypeRecent) {
        params[@"result_type"] = @"recent";
    } else if (resultType == FHSTwitterEngineResultTypePopular) {
        params[@"result_type"] = @"popular";
    }
    
    if (maxID.length > 0) {
        params[@"max_id"] = maxID;
    }
    
    if (sinceID.length > 0) {
        params[@"since_id"] = sinceID;
    }
    
    return [self sendGETRequestForURL:baseURL andParams:params];
}

- (NSError *)createListWithName:(NSString *)name isPrivate:(BOOL)isPrivate description:(NSString *)description {
    
    if (name.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_lists_create];
    
    NSMutableDictionary *params = [@{@"name": name, @"mode":isPrivate?@"private":@"public"} mutableCopy];

    if (description.length > 0) {
        params[@"description"] = description;
    }
    
    return [self sendPOSTRequestForURL:baseURL andParams:params];
}

- (id)getListWithID:(NSString *)listID {
    
    if (listID.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_lists_show];
    return [self sendGETRequestForURL:baseURL andParams:@{ @"list_id": listID }];
}

- (NSError *)updateListWithID:(NSString *)listID name:(NSString *)name {
    if (listID.length == 0) {
        return [NSError badRequestError];
    } else if (name.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_lists_update];
    return [self sendPOSTRequestForURL:baseURL andParams:@{@"list_id": listID, @"name": name}];
}

- (NSError *)updateListWithID:(NSString *)listID description:(NSString *)description {
    if (listID.length == 0) {
        return [NSError badRequestError];
    }
    
    if (description == nil) {
        description = @"";
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_lists_update];
    return [self sendPOSTRequestForURL:baseURL andParams:@{@"list_id": listID, @"description": description}];
}

- (NSError *)updateListWithID:(NSString *)listID mode:(BOOL)isPrivate {
    if (listID.length == 0) {
        return [NSError badRequestError];
    }

    NSURL *baseURL = [NSURL URLWithString:url_lists_update];
    return [self sendPOSTRequestForURL:baseURL andParams:@{@"list_id": listID, @"mode": isPrivate?@"private":@"public"}];
}

- (NSError *)updateListWithID:(NSString *)listID name:(NSString *)name description:(NSString *)description mode:(BOOL)isPrivate {
    if (listID.length == 0) {
        return [NSError badRequestError];
    } else if (name.length == 0) {
        return [NSError badRequestError];
    }
    
    if (description == nil) {
        description = @"";
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_lists_update];
    return [self sendPOSTRequestForURL:baseURL andParams:@{@"list_id": listID, @"name": name, @"description": description, @"mode": isPrivate?@"private":@"public"}];
}

- (id)listUsersInListWithID:(NSString *)listID {
    
    if (listID.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_lists_members];
    return [self sendGETRequestForURL:baseURL andParams:@{ @"list_id": listID }];
}

- (NSError *)removeUsersFromListWithID:(NSString *)listID users:(NSArray *)users {
    
    if (users.count > 100 || users.count == 0) {
        return [NSError badRequestError];
    } else if (listID.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_lists_members_destroy_all];
    return [self sendPOSTRequestForURL:baseURL andParams:@{@"screen_name": [users componentsJoinedByString:@","]}];
}

- (NSError *)addUsersToListWithID:(NSString *)listID users:(NSArray *)users {
    
    if (users.count > 100 || users.count == 0) {
        return [NSError badRequestError];
    } else if (listID.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_lists_members_create_all];
    return [self sendPOSTRequestForURL:baseURL andParams:@{@"screen_name": [users componentsJoinedByString:@","]}];
}

- (id)getTimelineForListWithID:(NSString *)listID count:(int)count {
    return [self getTimelineForListWithID:listID count:count sinceID:nil maxID:nil];
}

- (id)getTimelineForListWithID:(NSString *)listID count:(int)count sinceID:(NSString *)sinceID maxID:(NSString *)maxID {
    return [self getTimelineForListWithID:listID count:count sinceID:sinceID maxID:maxID excludeRetweets:YES excludeReplies:YES];
}

- (id)getTimelineForListWithID:(NSString *)listID count:(int)count excludeRetweets:(BOOL)excludeRetweets excludeReplies:(BOOL)excludeReplies {
    return [self getTimelineForListWithID:listID count:count sinceID:nil maxID:nil excludeRetweets:excludeRetweets excludeReplies:excludeReplies];
}

- (id)getTimelineForListWithID:(NSString *)listID count:(int)count sinceID:(NSString *)sinceID maxID:(NSString *)maxID excludeRetweets:(BOOL)excludeRetweets excludeReplies:(BOOL)excludeReplies {
    
    if (count == 0) {
        return nil;
    }
    
    if (listID.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_lists_statuses];
    NSMutableDictionary *params = [@{ @"count":@(count).stringValue, @"exclude_replies":(excludeReplies?@"true":@"false"), @"include_rts":(excludeRetweets?@"false":@"true"),@"list_id":listID } mutableCopy];

    if (sinceID.length > 0) {
        params[@"since_id"] = sinceID;
    }
    
    if (maxID.length > 0) {
        params[@"max_id"] = maxID;
    }
    
    return [self sendGETRequestForURL:baseURL andParams:params];
}

- (id)getListsForUser:(NSString *)user isID:(BOOL)isID {
    
    if (user.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_lists_list];
    return [self sendGETRequestForURL:baseURL andParams:@{ (isID?@"user_id":@"screen_name"): user }];
}

- (id)getRetweetsForTweet:(NSString *)identifier count:(int)count {
    
    if (count == 0) {
        return nil;
    }
    
    if (identifier.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.twitter.com/1.1/statuses/retweets/%@.json",identifier]];
    return [self sendGETRequestForURL:baseURL andParams:@{ @"count":@(count).stringValue }];
}

- (id)getRetweetedTimelineWithCount:(int)count {
    return [self getRetweetedTimelineWithCount:count sinceID:nil maxID:nil];
}

- (id)getRetweetedTimelineWithCount:(int)count sinceID:(NSString *)sinceID maxID:(NSString *)maxID {
    
    if (count == 0) {
        return nil;
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_statuses_retweets_of_me];
    NSMutableDictionary *params = [@{ @"count":@(count).stringValue, @"exclude_replies":@"false", @"include_rts":@"true"} mutableCopy];
    
    if (sinceID.length > 0) {
        params[@"since_id"] = sinceID;
    }
    
    if (maxID.length > 0) {
        params[@"max_id"] = maxID;
    }
    
    return [self sendGETRequestForURL:baseURL andParams:params];
}

- (id)getMentionsTimelineWithCount:(int)count {
    return [self getMentionsTimelineWithCount:count sinceID:nil maxID:nil];
}

- (id)getMentionsTimelineWithCount:(int)count sinceID:(NSString *)sinceID maxID:(NSString *)maxID {
    
    if (count == 0) {
        return nil;
    }

    NSURL *baseURL = [NSURL URLWithString:url_statuses_metions_timeline];
    
    NSMutableDictionary *params = [@{ @"count":@(count).stringValue, @"exclude_replies":@"false", @"include_rts":@"true" } mutableCopy];
    
    if (sinceID.length > 0) {
        params[@"since_id"] = sinceID;
    }
    
    if (maxID.length > 0) {
        params[@"max_id"] = maxID;
    }
    
    return [self sendGETRequestForURL:baseURL andParams:params];
}

- (NSError *)postTweet:(NSString *)tweetString withImageData:(NSData *)theData {
    return [self postTweet:tweetString withImageData:theData inReplyTo:nil];
}

- (NSError *)postTweet:(NSString *)tweetString withImageData:(NSData *)theData inReplyTo:(NSString *)tweetID {
    
    if (tweetString.length == 0) {
        return [NSError badRequestError];
    } else if (theData.length == 0) {
        if (tweetID.length == 0) {
            return [self postTweet:tweetString];
        } else {
            return [self postTweet:tweetString inReplyTo:tweetID];
        }
    }

    NSURL *baseURL = [NSURL URLWithString:url_statuses_update_with_media];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"status"] = tweetString;
    params[@"media[]"] = theData;
    
    if (tweetID.length > 0) {
        params[@"in_reply_to_status_id"] = tweetID;
    }
    
    return [self sendPOSTRequestForURL:baseURL andParams:params];
}

- (NSError *)destroyTweet:(NSString *)identifier {
    
    if (identifier.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_statuses_destroy];
    return [self sendPOSTRequestForURL:baseURL andParams:@{@"id": identifier}];
}

- (id)getDetailsForTweet:(NSString *)identifier {
    
    if (identifier.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_statuses_show];
    return [self sendGETRequestForURL:baseURL andParams:@{ @"id":identifier, @"include_my_retweet":@"true" }];
}

- (NSError *)retweet:(NSString *)identifier {
    
    if (identifier.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.twitter.com/1.1/statuses/retweet/%@.json",identifier]];
    return [self sendPOSTRequestForURL:baseURL andParams:nil];
}

- (id)getTimelineForUser:(NSString *)user isID:(BOOL)isID count:(int)count {
    return [self getTimelineForUser:user isID:isID count:count sinceID:nil maxID:nil];
}

- (id)getTimelineForUser:(NSString *)user isID:(BOOL)isID count:(int)count sinceID:(NSString *)sinceID maxID:(NSString *)maxID {
    
    if (count == 0) {
        return nil;
    }
    
    if (user.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_statuses_user_timeline];
    NSMutableDictionary *params = [@{ @"count":@(count).stringValue, (isID?@"user_id":@"screen_name"):user, @"exclude_replies":@"false", @"include_rts":@"true" } mutableCopy];
    
    if (sinceID.length > 0) {
        params[@"since_id"] = sinceID;
    }
    
    if (maxID.length > 0) {
        params[@"max_id"] = maxID;
    }
    
    return [self sendGETRequestForURL:baseURL andParams:params];
}

- (id)getProfileImageForUsername:(NSString *)username andSize:(FHSTwitterEngineImageSize)size {
    
    if (username.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_users_show];
    id userShowReturn = [self sendGETRequestForURL:baseURL andParams:@{ @"screen_name":username }];
    
    if ([userShowReturn isKindOfClass:[NSError class]]) {
        return userShowReturn;
    } else if ([userShowReturn isKindOfClass:[NSDictionary class]]) {
        NSString *url = userShowReturn[@"profile_image_url"]; // normal
        
        if (size == 0) { // mini
            url = [url stringByReplacingOccurrencesOfString:@"_normal" withString:@"_mini"];
        } else if (size == 2) { // bigger
            url = [url stringByReplacingOccurrencesOfString:@"_normal" withString:@"_bigger"];
        } else if (size == 3) { // original
            url = [url stringByReplacingOccurrencesOfString:@"_normal" withString:@""];
        }
        
        id ret = [self sendRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
        
        if ([ret isKindOfClass:[NSData class]]) {
            return [UIImage imageWithData:(NSData *)ret];
        }

        return ret;
    }
    
    return [NSError badRequestError];
}

- (id)getProfileImageURLStringForUsername:(NSString *)username andSize:(FHSTwitterEngineImageSize)size {
    
    if (username.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_users_show];
    id userShowReturn = [self sendGETRequestForURL:baseURL andParams:@{ @"screen_name":username }];
    
    if ([userShowReturn isKindOfClass:[NSError class]]) {
        return userShowReturn;
    } else if ([userShowReturn isKindOfClass:[NSDictionary class]]) {
        NSString *url = userShowReturn[@"profile_image_url"]; // normal
        
        if (size == 0) { // mini
            url = [url stringByReplacingOccurrencesOfString:@"_normal" withString:@"_mini"];
        } else if (size == 2) { // bigger
            url = [url stringByReplacingOccurrencesOfString:@"_normal" withString:@"_bigger"];
        } else if (size == 3) { // original
            url = [url stringByReplacingOccurrencesOfString:@"_normal" withString:@""];
        }
        
        return url;
    }
    
    return [NSError badRequestError];
}

- (id)authenticatedUserIsBlocking:(NSString *)user isID:(BOOL)isID {
    if (user.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_blocks_exists];
    return [self sendGETRequestForURL:baseURL andParams:@{ (isID?@"user_id":@"screen_name"):@"true", @"skip_status":@"true" }];
}

- (id)listBlockedUsers {
    NSURL *baseURL = [NSURL URLWithString:url_blocks_blocking];
    return [self sendGETRequestForURL:baseURL andParams:@{ @"skip_status":@"true" }];
}

- (id)listBlockedIDs {
    NSURL *baseURL = [NSURL URLWithString:url_blocks_blocking_ids];
    return [self sendGETRequestForURL:baseURL andParams:@{ @"stringify_ids": @"true" }];
}

- (id)getLanguages {
    NSURL *baseURL = [NSURL URLWithString:url_help_languages];
    return [self sendGETRequestForURL:baseURL andParams:nil];
}

- (id)getConfiguration {
    NSURL *baseURL = [NSURL URLWithString:url_help_configuration];
    return [self sendGETRequestForURL:baseURL andParams:nil];
}

- (NSError *)reportUserAsSpam:(NSString *)user isID:(BOOL)isID {
    
    if (user.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_users_report_spam];
    return [self sendPOSTRequestForURL:baseURL andParams:@{(isID?@"user_id":@"screen_name"): user}];
}

- (id)showDirectMessage:(NSString *)messageID {
    if (messageID.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_direct_messages_show];
    return [self sendGETRequestForURL:baseURL andParams:@{ @"id":messageID }];
}

- (NSError *)sendDirectMessage:(NSString *)body toUser:(NSString *)user isID:(BOOL)isID {
    
    if (user.length == 0) {
        return [NSError badRequestError];
    }
    
    if (body.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_direct_messages_new];
    return [self sendPOSTRequestForURL:baseURL andParams:@{@"text": [body fhs_trimForTwitter], (isID?@"user_id":@"screen_name"):user}];
}

- (id)getSentDirectMessages:(int)count {
    
    if (count == 0) {
        return nil;
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_direct_messages_sent];
    return [self sendGETRequestForURL:baseURL andParams:@{ @"count":@(count).stringValue }];
}

- (NSError *)deleteDirectMessage:(NSString *)messageID {
    
    if (messageID.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_direct_messages_destroy];
    return [self sendPOSTRequestForURL:baseURL andParams:@{@"id": messageID, @"include_entities": (_includeEntities?@"true":@"false")}];
}

- (id)getDirectMessages:(int)count {
    if (count == 0) {
        return nil;
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_direct_messages];
    return [self sendGETRequestForURL:baseURL andParams:@{ @"count":@(count).stringValue,@"skip_status":@"true" }];
}

- (id)getPrivacyPolicy {
    NSURL *baseURL = [NSURL URLWithString:url_help_privacy];
    return [self sendGETRequestForURL:baseURL andParams:nil];
}

- (id)getTermsOfService {
    NSURL *baseURL = [NSURL URLWithString:url_help_tos];
    return [self sendGETRequestForURL:baseURL andParams:nil];
}

- (id)getNoRetweetIDs {
    NSURL *baseURL = [NSURL URLWithString:url_friendships_no_retweets_ids];
    return [self sendGETRequestForURL:baseURL andParams:@{ @"stringify_ids":@"true" }];
}

- (NSError *)enableRetweets:(BOOL)enableRTs andDeviceNotifs:(BOOL)devNotifs forUser:(NSString *)user isID:(BOOL)isID {
    
    if (user.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_friendships_update];
    return [self sendPOSTRequestForURL:baseURL andParams:@{(isID?@"user_id":@"screen_name"): user, @"retweets": (enableRTs?@"true":@"false"), @"device": (devNotifs?@"true":@"false")}];
}

- (id)getPendingOutgoingFollowers {
    NSURL *baseURL = [NSURL URLWithString:url_friendships_outgoing];
    return [self sendGETRequestForURL:baseURL andParams:@{ @"stringify_ids":@"true" }];
}

- (id)getPendingIncomingFollowers {
    NSURL *baseURL = [NSURL URLWithString:url_friendships_incoming];
    return [self sendGETRequestForURL:baseURL andParams:@{ @"stringify_ids":@"true" }];
}

- (id)lookupFriendshipStatusForUsers:(NSArray *)users areIDs:(BOOL)areIDs {
    if (users.count == 0) {
        return nil;
    }
    
    NSMutableArray *returnedDictionaries = [NSMutableArray array];
    NSArray *reqStrings = [self generateRequestStringsFromArray:users];
    
    NSURL *baseURL = [NSURL URLWithString:url_friendships_lookup];
    
    for (NSString *reqString in reqStrings) {
        
        id retObj = [self sendGETRequestForURL:baseURL andParams:@{ (areIDs?@"user_id":@"screen_name"):reqString }];
        
        if ([retObj isKindOfClass:[NSArray class]]) {
            [returnedDictionaries addObjectsFromArray:(NSArray *)retObj];
        } else if ([retObj isKindOfClass:[NSError class]]) {
            return retObj;
        }
    }
    
    return returnedDictionaries;
}

- (NSError *)unfollowUser:(NSString *)user isID:(BOOL)isID {
    if (user.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_friendships_destroy];
    return [self sendPOSTRequestForURL:baseURL andParams:@{(isID?@"user_id":@"screen_name"): user}];
}

- (NSError *)followUser:(NSString *)user isID:(BOOL)isID {
    if (user.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_friendships_create];
    return [self sendPOSTRequestForURL:baseURL andParams:@{(isID?@"user_id":@"screen_name"): user}];
}

- (id)verifyCredentials {
    NSURL *baseURL = [NSURL URLWithString:url_account_verify_credentials];
    return [self sendGETRequestForURL:baseURL andParams:nil];
}

- (id)getFavoritesForUser:(NSString *)user isID:(BOOL)isID andCount:(int)count {
    return [self getFavoritesForUser:user isID:isID andCount:count sinceID:nil maxID:nil];
}

- (id)getFavoritesForUser:(NSString *)user isID:(BOOL)isID andCount:(int)count sinceID:(NSString *)sinceID maxID:(NSString *)maxID {
    if (count == 0) {
        return nil;
    }
    
    if (user.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_favorites_list];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:5];
    params[@"count"] = [NSString stringWithFormat:@"%d",count];
    params[(isID?@"user_id":@"screen_name")] = user;
    params[@"include_entities"] = _includeEntities?@"true":@"false";
    
    if (sinceID.length > 0) {
        params[@"since_id"] = sinceID;
    }
    
    if (maxID.length > 0) {
        params[@"max_id"] = maxID;
    }
    
    return [self sendGETRequestForURL:baseURL andParams:params];
}

- (NSError *)markTweet:(NSString *)tweetID asFavorite:(BOOL)flag {
    
    if (tweetID.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:flag?url_favorites_create:url_favorites_destroy];
    return [self sendPOSTRequestForURL:baseURL andParams:@{@"id": tweetID}];
}

- (id)getRateLimitStatus {
    NSURL *baseURL = [NSURL URLWithString:url_application_rate_limit_status];
    return [self sendGETRequestForURL:baseURL andParams:nil];
}

- (NSError *)updateProfileColorsWithDictionary:(NSDictionary *)dictionary {
    
    if (!dictionary) {
        return [NSError badRequestError];
    }
    
    // Each parameter is a hex color
    NSString *profile_background_color = dictionary[FHSProfileBackgroundColorKey];
    NSString *profile_link_color = dictionary[FHSProfileLinkColorKey];
    NSString *profile_sidebar_border_color = dictionary[FHSProfileSidebarBorderColorKey];
    NSString *profile_sidebar_fill_color = dictionary[FHSProfileSidebarFillColorKey];
    NSString *profile_text_color = dictionary[FHSProfileTextColorKey];
    
    NSURL *baseURL = [NSURL URLWithString:url_account_update_profile_colors];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:6];
    params[@"skip_status"] = @"true";

    if (profile_background_color.length > 0) {
        params[@"profile_background_color"] = profile_background_color;
    }
    
    if (profile_link_color.length > 0) {
        params[@"profile_link_color"] = profile_link_color;
    }
    
    if (profile_sidebar_border_color.length > 0) {
        params[@"profile_sidebar_border_color"] = profile_sidebar_border_color;
    }
    
    if (profile_sidebar_fill_color.length > 0) {
        params[@"profile_sidebar_fill_color"] = profile_sidebar_fill_color;
    }
    
    if (profile_text_color.length > 0) {
        params[@"profile_text_color"] = profile_text_color;
    }
    
    return [self sendPOSTRequestForURL:baseURL andParams:params];
}

- (NSError *)setUseProfileBackgroundImage:(BOOL)shouldUseBGImg {
    NSURL *baseURL = [NSURL URLWithString:url_account_update_profile_background_image];
    return [self sendPOSTRequestForURL:baseURL andParams:@{@"skip_status": @"true", @"use": (shouldUseBGImg?@"true":@"false")}];
}

- (NSError *)setProfileBackgroundImageWithImageData:(NSData *)data tiled:(BOOL)isTiled {
    if (data.length == 0) {
        return [NSError badRequestError];
    }
    
    if (data.length >= 800000) {
        return [NSError imageTooLargeError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_account_update_profile_background_image];
    return [self sendPOSTRequestForURL:baseURL andParams:@{@"skip_status":@"true", @"use":@"true", @"include_entities":_includeEntities?@"true":@"false", @"tiled":(isTiled?@"true":@"false"), @"image":[data base64Encode]}];
}

- (NSError *)setProfileBackgroundImageWithImageAtPath:(NSString *)file tiled:(BOOL)isTiled {
    return [self setProfileBackgroundImageWithImageData:[NSData dataWithContentsOfFile:file] tiled:isTiled];
}

- (NSError *)setProfileImageWithImageData:(NSData *)data {
    if (data.length == 0) {
        return [NSError badRequestError];
    }
    
    if (data.length >= 700000) {
        return [NSError imageTooLargeError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_account_update_profile_image];
    return [self sendPOSTRequestForURL:baseURL andParams:@{@"skip_status":@"true", @"include_entities":(_includeEntities?@"true":@"false"), @"image":[data base64Encode]}];
}

- (NSError *)setProfileImageWithImageAtPath:(NSString *)file {
    return [self setProfileImageWithImageData:[NSData dataWithContentsOfFile:file]];
}

- (id)getUserSettings {
    NSURL *baseURL = [NSURL URLWithString:url_account_settings];
    return [self sendGETRequestForURL:baseURL andParams:nil];
}

- (NSError *)updateUserProfileWithDictionary:(NSDictionary *)settings {
    
    if (!settings) {
        return [NSError badRequestError];
    }
    
    // all of the values are just strings.
    //   parameter    length in characters
    // name                 20
    // url                  100
    // location             30
    // description          160
    
    NSString *name = settings[FHSProfileNameKey];
    NSString *url = settings[FHSProfileURLKey];
    NSString *location = settings[FHSProfileLocationKey];
    NSString *description = settings[FHSProfileDescriptionKey];
    
    NSURL *baseURL = [NSURL URLWithString:url_account_update_profile];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:6];
    params[@"skip_status"] = @"true";
    params[@"include_entities"] = (_includeEntities?@"true":@"false");
    
    if (name.length > 0) {
        params[@"name"] = name;
    }
    
    if (url.length > 0) {
        params[@"url"] = url;
    }
    
    if (location.length > 0) {
        params[@"location"] = location;
    }
    
    if (description.length > 0) {
        params[@"description"] = description;
    }
    
    return [self sendPOSTRequestForURL:baseURL andParams:params];
}

- (NSError *)updateSettingsWithDictionary:(NSDictionary *)settings {
    
    if (!settings) {
        return [NSError badRequestError];
    }
    
    // Dictionary with keys:
    // All strings... You could have guessed that.
    // sleep_time_enabled - true/false
    // start_sleep_time - UTC time
    // end_sleep_time - UTC time
    // time_zone - Europe/Copenhagen, Pacific/Tongatapu
    // lang - en, it, es
    
    NSString *sleep_time_enabled = settings[@"sleep_time_enabled"];
    NSString *start_sleep_time = settings[@"start_sleep_time"];
    NSString *end_sleep_time = settings[@"end_sleep_time"];
    NSString *time_zone = settings[@"time_zone"];
    NSString *lang = settings[@"lang"];
    
    NSURL *baseURL = [NSURL URLWithString:url_account_settings];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:5];
    
    if (sleep_time_enabled.length > 0) {
        params[@"sleep_time_enabled"] = sleep_time_enabled;
    }
    
    if (start_sleep_time.length > 0) {
        params[@"start_sleep_time"] = start_sleep_time;
    }
    
    if (end_sleep_time.length > 0) {
        params[@"end_sleep_time"] = end_sleep_time;
    }
    
    if (time_zone.length > 0) {
        params[@"time_zone"] = time_zone;
    }
    
    if (lang.length > 0) {
        params[@"lang"] = lang;
    }
    
    return [self sendPOSTRequestForURL:baseURL andParams:params];
}

- (id)lookupUsers:(NSArray *)users areIDs:(BOOL)areIDs {
    
    if (users.count == 0) {
        return nil;
    }
    
    if (users.count > 100) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_users_lookup];
    return [self sendGETRequestForURL:baseURL andParams:@{ (areIDs?@"user_id":@"screen_name"):[users componentsJoinedByString:@","] }];
}

- (NSError *)unblock:(NSString *)username {
    if (username.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_blocks_destroy];
    return [self sendPOSTRequestForURL:baseURL andParams:@{@"screen_name":username}];
}

- (NSError *)block:(NSString *)username {
    
    if (username.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_blocks_create];
    return [self sendPOSTRequestForURL:baseURL andParams:@{@"screen_name":username}];
}

- (id)testService {
    NSURL *baseURL = [NSURL URLWithString:url_help_test];
    return [self sendGETRequestForURL:baseURL andParams:nil];
}

- (id)getHomeTimelineSinceID:(NSString *)sinceID count:(int)count {
    
    if (count == 0) {
        return nil;
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_statuses_home_timeline];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:2];
    params[@"count"] = [NSString stringWithFormat:@"%d",count];
    
    if (sinceID.length > 0) {
        params[@"since_id"] = sinceID;
    }
    
    return [self sendGETRequestForURL:baseURL andParams:params];
}

- (NSError *)postTweet:(NSString *)tweetString inReplyTo:(NSString *)tweetID {
    if (tweetString.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_statuses_update];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:2];
    params[@"status"] = tweetString;
    
    if (tweetID.length > 0) {
        params[@"in_reply_to_status_id"] = tweetID;
    }

    return [self sendPOSTRequestForURL:baseURL andParams:params];
}

- (NSError *)postTweet:(NSString *)tweetString {
    return [self postTweet:tweetString inReplyTo:nil];
}

- (id)getFollowersIDs {
    NSURL *baseURL = [NSURL URLWithString:url_followers_ids];
    return [self sendGETRequestForURL:baseURL andParams:@{ @"screen_name": _authenticatedUsername, @"stringify_ids":@"true"}];
}

- (id)getFriendsIDs {
    NSURL *baseURL = [NSURL URLWithString:url_friends_ids];
    return [self sendGETRequestForURL:baseURL andParams:@{ @"screen_name": _authenticatedUsername, @"stringify_ids":@"true"}];
}

- (id)uploadImageToTwitPic:(NSData *)imageData withMessage:(NSString *)message twitPicAPIKey:(NSString *)twitPicAPIKey {
    
    NSString *appropriateExtension = [imageData appropriateFileExtension];
    
    if (appropriateExtension == nil) {
        return [NSError badRequestError];
    }
    
    NSString *nonce = [NSString fhs_UUID];
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/account/verify_credentials.json"];
    
    NSString *timestamp = [NSString stringWithFormat:@"%ld", time(nil)];
    
    NSMutableArray *parameterPairs = [NSMutableArray arrayWithCapacity:6];
    [parameterPairs addObject:[NSString stringWithFormat:@"oauth_consumer_key=%@",_consumer.key.fhs_URLEncode]];
    [parameterPairs addObject:@"oauth_signature_method=HMAC-SHA1"];
    [parameterPairs addObject:[NSString stringWithFormat:@"oauth_nonce=%@",nonce.fhs_URLEncode]];
    [parameterPairs addObject:[NSString stringWithFormat:@"oauth_timestamp=%@",timestamp.fhs_URLEncode]];
    [parameterPairs addObject:@"oauth_version=1.0"];
    [parameterPairs addObject:[NSString stringWithFormat:@"oauth_token=%@",_accessToken.key]];
    
    NSArray *sortedPairs = [parameterPairs sortedArrayUsingSelector:@selector(compare:)];
    NSString *normalizedRequestParameters = [sortedPairs componentsJoinedByString:@"&"];
    
    NSString *signatureBaseString = [NSString stringWithFormat:@"%@&%@&%@", @"GET", [@"https://api.twitter.com/1.1/account/verify_credentials.json" fhs_URLEncode],normalizedRequestParameters.fhs_URLEncode];
    
    NSString *secretForSigning = [NSString stringWithFormat:@"%@&%@", _consumer.secret.fhs_URLEncode, _accessToken.secret.fhs_URLEncode];
    
    NSData *secretData = [secretForSigning dataUsingEncoding:NSUTF8StringEncoding];
    NSData *clearTextData = [signatureBaseString dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char result[20];
	CCHmac(kCCHmacAlgSHA1, secretData.bytes, secretData.length, clearTextData.bytes, clearTextData.length, result);
    NSString *signature = [[NSData dataWithBytes:result length:20]base64Encode];
    
    NSString *oauthToken = [NSString stringWithFormat:@"oauth_token=\"%@\", ", _accessToken.key.fhs_URLEncode];
    
    NSString *oauthHeaders = [NSString stringWithFormat:@"OAuth realm=\"%@\", oauth_consumer_key=\"%@\", %@oauth_signature_method=\"HMAC-SHA1\", oauth_signature=\"%@\", oauth_timestamp=\"%@\", oauth_nonce=\"%@\", oauth_version=\"1.0\"", @"http://api.twitter.com/".fhs_URLEncode, _consumer.key.fhs_URLEncode, oauthToken, signature.fhs_URLEncode, timestamp, nonce];
    
    NSURL *url = [NSURL URLWithString:@"http://api.twitpic.com/2/upload.json"];
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"POST"];
    [req setValue:oauthHeaders forHTTPHeaderField:@"X-Verify-Credentials-Authorization"];
    [req setValue:baseURL.absoluteString forHTTPHeaderField:@"X-Auth-Service-Provider"];
    
    NSString *boundary = @"---------------------------14737809831466499882746641449";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
    
    [req addValue:contentType forHTTPHeaderField:@"Content-Type"];
    
    NSMutableData *body = [NSMutableData data];
    
    // message
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"message\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[message dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    // key
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"key\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[twitPicAPIKey dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    // picture
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"media\"; filename=\"%@.%@\"\r\n",nonce,appropriateExtension] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Type: image/%@\r\n",appropriateExtension] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Transfer-Encoding: binary\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:imageData];
    [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [req setHTTPBody:body];
    
    [req setValue:[NSString stringWithFormat:@"%d",body.length] forHTTPHeaderField:@"Content-Length"];
    
    NSError *error = nil;
    NSHTTPURLResponse *response = nil;
    
    NSData *responseData = [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:&error];
    
    id parsedJSONResponse = removeNull([NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:nil]);
    
    if (error) {
        return error;
    }
    
    if (response.statusCode >= 304) {
        return error;
    }
    
    if ([parsedJSONResponse isKindOfClass:[NSDictionary class]]) {
        NSString *errorMessage = [parsedJSONResponse objectForKey:@"error"];
        NSArray *errorArray = [parsedJSONResponse objectForKey:@"errors"];
        if (errorMessage.length > 0) {
            return [NSError errorWithDomain:errorMessage code:[[parsedJSONResponse objectForKey:@"code"]intValue] userInfo:[NSDictionary dictionaryWithObject:req forKey:@"request"]];
        } else if (errorArray.count > 0) {
            if (errorArray.count > 1) {
                return [NSError errorWithDomain:@"Multiple Errors" code:1337 userInfo:[NSDictionary dictionaryWithObject:req forKey:@"request"]];
            } else {
                NSDictionary *theError = [errorArray objectAtIndex:0];
                return [NSError errorWithDomain:[theError objectForKey:@"message"] code:[[theError objectForKey:@"code"]integerValue] userInfo:[NSDictionary dictionaryWithObject:req forKey:@"request"]];
            }
        }
    }
    
    return parsedJSONResponse;
}

//
// Streaming API
//

// check out the streaming parameters here:
// https://dev.twitter.com/docs/streaming-apis/parameters

- (NSString *)generateTrackParameter:(NSArray *)keywords {
    NSMutableArray *sanitized = [NSMutableArray arrayWithCapacity:keywords.count];
    
    for (NSString *string in keywords) {
        [sanitized addObject:[string fhs_truncatedToLength:60]];
    }
    
    return [sanitized componentsJoinedByString:@","];
}


// Actual calls to the Twitter API

- (void)streamUserMessagesWith:(NSArray *)with replies:(BOOL)replies keywords:(NSArray *)keywords locationBox:(NSArray *)locBox block:(StreamBlock)block {
    NSMutableDictionary *params = @{ @"stringify_friend_ids": @"true" }.mutableCopy;
    
    if (with.count > 0) {
        params[@"with"] = [with componentsJoinedByString:@","];
    }
    
    if (keywords.count > 0) {
        params[@"track"] = [self generateTrackParameter:keywords];
    }
    
    if (locBox.count == 4) {
        params[@"locations"] = [locBox componentsJoinedByString:@","];
    }
    
    [[FHSStream streamWithURL:@"https://userstream.twitter.com/1.1/user.json" httpMethod:@"POST" parameters:params timeout:streamingTimeoutInterval block:block]start]; // Twitter says it should be GET, but on further investigation of the docs, POST works too.
}

- (void)streamPublicStatusesForUsers:(NSArray *)users keywords:(NSArray *)keywords locationBox:(NSArray *)locBox block:(StreamBlock)block {
    BOOL usersValid = users.count > 0 && users.count < 5000;
    BOOL keywordsValid = keywords.count > 0 && keywords.count < 400;
    BOOL locBoxValid = locBox.count == 4;
    
    if (!usersValid && !keywordsValid && !locBoxValid) {
        NSError *error = [NSError errorWithDomain:FHSErrorDomain code:400 userInfo:@{NSLocalizedDescriptionKey: @"Bad Request: invalid parameters: POST statuses/filter requires at least one predicate parameter (follow, locations, or track)."}];
        block(error, NULL);
        return;
    }
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:5];

    if (usersValid) {
        params[@"follow"] = [users componentsJoinedByString:@","];
    }
    
    if (keywordsValid) {
        params[@"track"] = [self generateTrackParameter:keywords];
    }
    
    if (locBoxValid) {
        params[@"locations"] = [locBox componentsJoinedByString:@","];
    }
    
    [[FHSStream streamWithURL:@"https://stream.twitter.com/1.1/statuses/filter.json" httpMethod:@"POST" parameters:params timeout:streamingTimeoutInterval block:block]start];
}

- (void)streamSampleStatusesWithBlock:(StreamBlock)block {
    [[FHSStream streamWithURL:@"https://stream.twitter.com/1.1/statuses/sample.json" httpMethod:@"GET" parameters:nil timeout:streamingTimeoutInterval block:block]start];
}

- (void)streamFirehoseWithBlock:(StreamBlock)block {
    [[FHSStream streamWithURL:@"https://stream.twitter.com/1.1/statuses/firehose.json" httpMethod:@"GET" parameters:nil timeout:streamingTimeoutInterval block:block]start];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // Twitter API datestamps are UTC
        // Don't question this code.
        self.dateFormatter = [[NSDateFormatter alloc]init];
        _dateFormatter.locale = [[NSLocale alloc]initWithLocaleIdentifier:@"en_US"];
        _dateFormatter.dateStyle = NSDateFormatterLongStyle;
        _dateFormatter.formatterBehavior = NSDateFormatterBehavior10_4;
        _dateFormatter.dateFormat = @"EEE MMM dd HH:mm:ss ZZZZ yyyy";
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancelTouched:) name:@"FHSTwitterEngineControllerDidCancel" object:nil];
    }
    return self;
}

+ (FHSTwitterEngine *)sharedEngine {
    static FHSTwitterEngine *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[[self class]alloc]init];
    });
    return sharedInstance;
}

- (NSArray *)generateRequestStringsFromArray:(NSArray *)array {
    
    NSString *initialString = [array componentsJoinedByString:@","];
    
    if (array.count <= 100) {
        return [NSArray arrayWithObjects:initialString, nil];
    }
    
    int offset = 0;
    int remainder = fmod(array.count, 100);
    int numberOfStrings = (array.count-remainder)/100;
    
    NSMutableArray *reqStrs = [NSMutableArray array];
    
    for (int i = 1; i <= numberOfStrings; ++i) {
        NSString *ninetyNinththItem = (NSString *)[array objectAtIndex:(i*100)-1];
        NSRange range = [initialString rangeOfString:ninetyNinththItem];
        int endOffset = range.location+range.length;
        NSRange rangeOfAString = NSMakeRange(offset, endOffset-offset);
        offset = endOffset;
        NSString *endResult = [initialString fhs_stringWithRange:rangeOfAString];
        
        if ([[endResult substringToIndex:1]isEqualToString:@","]) {
            endResult = [endResult substringFromIndex:1];
        }
        
        [reqStrs addObject:endResult];
    }
    
    NSString *remainderString = [initialString stringByReplacingOccurrencesOfString:[reqStrs componentsJoinedByString:@","] withString:@""];
    
    if ([[remainderString substringToIndex:1]isEqualToString:@","]) {
        remainderString = [remainderString substringFromIndex:1];
    }
    
    [reqStrs addObject:remainderString];
    
    return reqStrs;
}

//
// sendRequest:
//

- (id)sendRequest:(NSURLRequest *)request {
    
    if (_shouldClearConsumer) {
        self.shouldClearConsumer = NO;
        self.consumer = nil;
    }
    
    NSHTTPURLResponse *response = nil;
    NSError *error = nil;
    
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    if (error) {
        return error;
    }
    
    if (response == nil) {
        return error;
    }
    
    if (response.statusCode >= 304) {
        return error;
    }
    
    if (data.length == 0) {
        return error;
    }
    
    return data;
}

- (void)signRequest:(NSMutableURLRequest *)request {
    [self signRequest:request withToken:_accessToken.key tokenSecret:_accessToken.secret verifier:nil];
}

- (void)signRequest:(NSMutableURLRequest *)request withToken:(NSString *)tokenString tokenSecret:(NSString *)tokenSecretString verifier:(NSString *)verifierString {
    
    NSString *consumerKey = [_consumer.key fhs_URLEncode];
    NSString *nonce = [NSString fhs_UUID];
    NSString *timestamp = [NSString stringWithFormat:@"%ld",time(nil)];
    NSString *urlWithoutParams = [fhs_url_remove_params(request.URL) fhs_URLEncode];
    
    // OAuth Spec, Section 9.1.1 "Normalize Request Parameters"
    // build a sorted array of both request parameters and OAuth header parameters
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionary];
    
    mutableParams[@"oauth_consumer_key"] = consumerKey;
    mutableParams[@"oauth_signature_method"] = @"HMAC-SHA1";
    mutableParams[@"oauth_timestamp"] = timestamp;
    mutableParams[@"oauth_nonce"] = nonce;
    mutableParams[@"oauth_version"] = @"1.0";
    
    if (tokenString.length > 0) {
        mutableParams[@"oauth_token"] = [tokenString fhs_URLEncode];
        if (verifierString.length > 0) {
            mutableParams[@"oauth_verifier"] = [verifierString fhs_URLEncode];
        }
    } else {
        mutableParams[@"oauth_callback"] = @"oob";
    }
    
    NSMutableArray *paramPairs = [NSMutableArray arrayWithCapacity:mutableParams.count];
    
    for (NSString *key in mutableParams.allKeys) {
        [paramPairs addObject:[NSString stringWithFormat:@"%@=%@",[key fhs_URLEncode],[mutableParams[key] fhs_URLEncode]]];
    }
    
    if ([request.HTTPMethod isEqualToString:@"GET"]) {
        
        NSArray *halves = [request.URL.absoluteString componentsSeparatedByString:@"?"];
        
        if (halves.count > 1) {
            NSArray *parameters = [halves[1] componentsSeparatedByString:@"&"];
            
            if (parameters.count > 0) {
                [paramPairs addObjectsFromArray:parameters];
            }
        }
    }
    
    [paramPairs sortUsingSelector:@selector(compare:)];
    
    NSString *normalizedRequestParameters = [[paramPairs componentsJoinedByString:@"&"]fhs_URLEncode];
    
    // OAuth Spec, Section 9.1.2 "Concatenate Request Elements"
    // Sign request elements using HMAC-SHA1
    NSString *signatureBaseString = [NSString stringWithFormat:@"%@&%@&%@",request.HTTPMethod,urlWithoutParams,normalizedRequestParameters];
    
    NSString *tokenSecretSantized = (tokenSecretString.length > 0)?[tokenSecretString fhs_URLEncode]:@""; // this way a nil token won't make a bad signature
    
    NSString *secret = [NSString stringWithFormat:@"%@&%@",[_consumer.secret fhs_URLEncode],tokenSecretSantized];
    
    NSData *secretData = [secret dataUsingEncoding:NSUTF8StringEncoding];
    NSData *clearTextData = [signatureBaseString dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char result[20];
	CCHmac(kCCHmacAlgSHA1, secretData.bytes, secretData.length, clearTextData.bytes, clearTextData.length, result);
    NSData *theData = [[[NSData dataWithBytes:result length:20]base64Encode]dataUsingEncoding:NSUTF8StringEncoding];

    NSString *signature = [[[NSString alloc]initWithData:theData encoding:NSUTF8StringEncoding]fhs_URLEncode];
    
	NSString *oauthToken = (tokenString.length > 0)?[NSString stringWithFormat:@"oauth_token=\"%@\", ",[tokenString fhs_URLEncode]]:@"oauth_callback=\"oob\", ";
    NSString *oauthVerifier = (verifierString.length > 0)?[NSString stringWithFormat:@"oauth_verifier=\"%@\", ",verifierString]:@"";

    NSString *oauthHeader = [NSString stringWithFormat:@"OAuth oauth_consumer_key=\"%@\", %@%@oauth_signature_method=\"HMAC-SHA1\", oauth_signature=\"%@\", oauth_timestamp=\"%@\", oauth_nonce=\"%@\", oauth_version=\"1.0\"",consumerKey,oauthToken,oauthVerifier,signature,timestamp,nonce];
    
    [request setValue:oauthHeader forHTTPHeaderField:@"Authorization"];
}

- (int)parameterLengthForURL:(NSString *)url params:(NSMutableDictionary *)params {
    int length = url.length;

    for (NSString *key in params) {
        length += [key fhs_URLEncode].length;
        length += [params[key] fhs_URLEncode].length;
        length += 1; // for the equal sign
    }
    
    return length;
}

- (NSError *)checkAuth {
    if (![self isAuthorized]) {
        [self loadAccessToken];
        if (![self isAuthorized]) {
            return [NSError errorWithDomain:FHSErrorDomain code:401 userInfo:@{NSLocalizedDescriptionKey:@"You are not authorized via OAuth."}];
        }
    }
    return nil;
}

- (NSError *)checkError:(id)json {
    if ([json isKindOfClass:[NSDictionary class]]) {
        NSArray *errors = json[@"errors"];
        
        if (errors.count > 0) {
            return [NSError errorWithDomain:FHSErrorDomain code:418 userInfo:@{NSLocalizedDescriptionKey: @"Multiple Errors", @"errors": errors}];
        }
    }
    return nil;
}

- (NSData *)POSTBodyWithParams:(NSDictionary *)params boundary:(NSString *)boundary {
    NSMutableData *body = [NSMutableData dataWithLength:0];
    
    for (NSString *key in params.allKeys) {
        id obj = params[key];
        
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        
        NSData *data = nil;
        
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n",key] dataUsingEncoding:NSUTF8StringEncoding]];
        
        if ([obj isKindOfClass:[NSData class]]) {
            [body appendData:[@"Content-Type: application/octet-stream\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
            data = (NSData *)obj;
        } else if ([obj isKindOfClass:[NSString class]]) {
            data = [[NSString stringWithFormat:@"%@",(NSString *)obj]dataUsingEncoding:NSUTF8StringEncoding];
        }
        
        [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:data];
        [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    return body;
}

- (NSError *)sendPOSTRequestForURL:(NSURL *)url andParams:(NSDictionary *)params {
    
    NSError *authError = [self checkAuth];
    
    if (authError) {
        return authError;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0f];
    [request setHTTPMethod:@"POST"];
    [request setHTTPShouldHandleCookies:NO];
    
    NSString *boundary = [NSString fhs_UUID];
    
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
    [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
    
    [self signRequest:request];
    
    NSData *body = [self POSTBodyWithParams:params boundary:boundary];
    [request setValue:@(body.length).stringValue forHTTPHeaderField:@"Content-Length"];
    request.HTTPBody = body;
    
    id retobj = [self sendRequest:request];
    
    if (!retobj) {
        return [NSError noDataError];
    } else if ([retobj isKindOfClass:[NSError class]]) {
        return retobj;
    }
    
    id parsed = removeNull([NSJSONSerialization JSONObjectWithData:(NSData *)retobj options:NSJSONReadingMutableContainers error:nil]);
    
    NSError *error = [self checkError:parsed];
    
    if (error) {
        return error;
    }
    
    return nil; // eventually return the parsed response
}

- (id)sendGETRequestForURL:(NSURL *)url andParams:(NSDictionary *)params {
    
    NSError *authError = [self checkAuth];
    
    if (authError) {
        return authError;
    }
    
    if (params.count > 0) {
        NSMutableArray *paramPairs = [NSMutableArray arrayWithCapacity:params.count];
        
        for (NSString *key in params) {
            NSString *paramPair = [NSString stringWithFormat:@"%@=%@",[key fhs_URLEncode],[params[key] fhs_URLEncode]];
            [paramPairs addObject:paramPair];
        }
        
        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@",fhs_url_remove_params(url), [paramPairs componentsJoinedByString:@"&"]]];
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0f];
    [request setHTTPMethod:@"GET"];
    [request setHTTPShouldHandleCookies:NO];
    [self signRequest:request];

    id retobj = [self sendRequest:request];
    
    if (!retobj) {
        return [NSError noDataError];
    } else if ([retobj isKindOfClass:[NSError class]]) {
        return retobj;
    }
    
    id parsed = removeNull([NSJSONSerialization JSONObjectWithData:(NSData *)retobj options:NSJSONReadingMutableContainers error:nil]);
    
    NSError *error = [self checkError:parsed];
    
    if (error) {
        return error;
    }
    
    return parsed;
}

- (id)streamingRequestForURL:(NSURL *)url HTTPMethod:(NSString *)method parameters:(NSDictionary *)params {
    
    NSError *authError = [self checkAuth];
    
    if (authError) {
        return authError;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:cachePolicy timeoutInterval:MAXFLOAT]; // timeouts are handled manually
    [request setHTTPMethod:method];
    [request setHTTPShouldHandleCookies:NO];
    
    // Only POST and GET are relevant to the Twitter API
    
    if ([method isEqualToString:@"POST"]) {
        NSString *boundary = [NSString fhs_UUID];
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
        [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
        NSData *body = [self POSTBodyWithParams:params boundary:boundary];
        [request setValue:@(body.length).stringValue forHTTPHeaderField:@"Content-Length"];
        request.HTTPBody = body;
    } else if ([method isEqualToString:@"GET"]) {
        if (params.count > 0) {
            NSMutableArray *paramPairs = [NSMutableArray arrayWithCapacity:params.count];
            
            for (NSString *key in params) {
                NSString *paramPair = [NSString stringWithFormat:@"%@=%@",[key fhs_URLEncode],[params[key] fhs_URLEncode]];
                [paramPairs addObject:paramPair];
            }
            
            url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@",fhs_url_remove_params(url), [paramPairs componentsJoinedByString:@"&"]]];
        }
    } else {
        return [NSError errorWithDomain:FHSErrorDomain code:-400 userInfo:@{}];
    }
    
    [self signRequest:request];
    return request;
}

//
// OAuth
//

- (NSString *)getRequestTokenString {
    
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/oauth/request_token"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0f];
    [request setHTTPMethod:@"POST"];
    [request setHTTPShouldHandleCookies:NO];
    [self signRequest:request withToken:nil tokenSecret:nil verifier:nil];

    id retobj = [self sendRequest:request];
    
    if ([retobj isKindOfClass:[NSData class]]) {
        return [[NSString alloc]initWithData:(NSData *)retobj encoding:NSUTF8StringEncoding];
    }
    
    return nil;
}

- (BOOL)finishAuthWithRequestToken:(FHSToken *)reqToken {

    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0f];
    [request setHTTPMethod:@"POST"];
    [request setHTTPShouldHandleCookies:NO];
    [self signRequest:request withToken:reqToken.key tokenSecret:reqToken.secret verifier:reqToken.verifier];
    
    if (_shouldClearConsumer) {
        self.shouldClearConsumer = NO;
        self.consumer = nil;
    }
    
    id retobj = [self sendRequest:request];
    
    if ([retobj isKindOfClass:[NSError class]]) {
        return NO;
    }
    
    NSString *response = [[NSString alloc]initWithData:(NSData *)retobj encoding:NSUTF8StringEncoding];
    
    if (response.length == 0) {
        return NO;
    }
    
    [self storeAccessToken:response];
    
    return YES;
}

//
// XAuth
//

- (NSError *)getXAuthAccessTokenForUsername:(NSString *)username password:(NSString *)password {
    
    if (password.length == 0) {
        return [NSError badRequestError];
    } else if (username.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0f];
    [request setHTTPMethod:@"POST"];
    [request setHTTPShouldHandleCookies:NO];
    [self signRequest:request withToken:nil tokenSecret:nil verifier:nil];
    
    // generate the POST body...
    
    NSString *bodyString = [NSString stringWithFormat:@"x_auth_mode=client_auth&x_auth_username=%@&x_auth_password=%@",username,password];
    request.HTTPBody = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
    
    if (_shouldClearConsumer) {
        self.shouldClearConsumer = NO;
        self.consumer = nil;
    }
    
    id ret = [self sendRequest:request];
    
    if ([ret isKindOfClass:[NSError class]]) {
        return ret;
    } else if ([ret isKindOfClass:[NSData class]]) {
        NSString *httpBody = [[NSString alloc]initWithData:(NSData *)ret encoding:NSUTF8StringEncoding];
        
        if (httpBody.length > 0) {
            [self storeAccessToken:httpBody];
        } else {
            [self storeAccessToken:nil];
            return [NSError errorWithDomain:FHSErrorDomain code:422 userInfo:@{NSLocalizedDescriptionKey:@"The request was well-formed but was unable to be followed due to semantic errors.", @"request":request}];
        }
    }
    
    return nil;
}

//
// Access Token Management
//

- (void)loadAccessToken {
    
    NSString *savedHttpBody = nil;
    
    if (_delegate && [_delegate respondsToSelector:@selector(loadAccessToken)]) {
        savedHttpBody = [_delegate loadAccessToken];
    } else {
        savedHttpBody = [[NSUserDefaults standardUserDefaults]objectForKey:@"SavedAccessHTTPBody"];
    }
    
    self.accessToken = [FHSToken tokenWithHTTPResponseBody:savedHttpBody];
    self.authenticatedUsername = [self extractValueForKey:@"screen_name" fromHTTPBody:savedHttpBody];
    self.authenticatedID = [self extractValueForKey:@"user_id" fromHTTPBody:savedHttpBody];
}

- (void)storeAccessToken:(NSString *)accessTokenZ {
    self.accessToken = [FHSToken tokenWithHTTPResponseBody:accessTokenZ];
    self.authenticatedUsername = [self extractValueForKey:@"screen_name" fromHTTPBody:accessTokenZ];
    self.authenticatedID = [self extractValueForKey:@"user_id" fromHTTPBody:accessTokenZ];
    
    if (_delegate && [_delegate respondsToSelector:@selector(storeAccessToken:)]) {
        [_delegate storeAccessToken:accessTokenZ];
    } else {
        [[NSUserDefaults standardUserDefaults]setObject:accessTokenZ forKey:@"SavedAccessHTTPBody"];
    }
}

- (NSString *)extractValueForKey:(NSString *)target fromHTTPBody:(NSString *)body {
    if (body.length == 0) {
        return nil;
    }
    
    if (target.length == 0) {
        return nil;
    }
	
	NSArray *tuples = [body componentsSeparatedByString:@"&"];
	if (tuples.count < 1) {
        return nil;
    }
	
	for (NSString *tuple in tuples) {
		NSArray *keyValueArray = [tuple componentsSeparatedByString:@"="];
		
		if (keyValueArray.count >= 2) {
			NSString *key = [keyValueArray objectAtIndex:0];
			NSString *value = [keyValueArray objectAtIndex:1];
			
			if ([key isEqualToString:target]) {
                return value;
            }
		}
	}
	
	return nil;
}

- (BOOL)isAuthorized {
    if (!self.consumer) {
        return NO;
    }
    
	if (self.accessToken.key && self.accessToken.secret) {
        if (self.accessToken.key.length > 0 && self.accessToken.secret.length > 0) {
            return YES;
        }
    }
    
	return NO;
}

- (void)clearAccessToken {
    [self storeAccessToken:@""];
	self.accessToken = nil;
    self.authenticatedID = nil;
}

- (void)clearConsumer {
    self.consumer = nil;
}

- (void)permanentlySetConsumerKey:(NSString *)consumerKey andSecret:(NSString *)consumerSecret {
    self.shouldClearConsumer = NO;
    self.consumer = [FHSConsumer consumerWithKey:consumerKey secret:consumerSecret];
}

- (void)temporarilySetConsumerKey:(NSString *)consumerKey andSecret:(NSString *)consumerSecret {
    self.shouldClearConsumer = YES;
    self.consumer = [FHSConsumer consumerWithKey:consumerKey secret:consumerSecret];
}

- (UIViewController *)loginController {
    return [[FHSTwitterEngineController alloc]init]; // It's legit because this project is ARC only.
}

- (UIViewController *)loginControllerWithCompletionHandler:(void(^)(BOOL success))block {
    FHSTwitterEngineController *vc = [[FHSTwitterEngineController alloc]init];
    objc_setAssociatedObject(vc, "FHSTwitterEngineOAuthCompletion", block, OBJC_ASSOCIATION_COPY_NONATOMIC);
    return vc;
}

+ (BOOL)isConnectedToInternet {
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)&zeroAddress);
    
    if (reachability) {
        SCNetworkReachabilityFlags flags;
        BOOL worked = SCNetworkReachabilityGetFlags(reachability, &flags);
        CFRelease(reachability);
        
        if (worked) {
            
            if ((flags & kSCNetworkReachabilityFlagsReachable) == 0) {
                return NO;
            }
            
            if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) {
                return YES;
            }
            
            if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand) != 0) || (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0)) {
                if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0) {
                    return YES;
                }
            }
            
            if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN) {
                return YES;
            }
        }
        
    }
    return NO;
}

- (void)cancelTouched:(NSNotification *)notification {
    if ( [_delegate respondsToSelector:@selector(twitterEngineControllerDidCancel)] ) {
        [_delegate twitterEngineControllerDidCancel];
    }
}

- (void)dealloc {
    [self setDelegate:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

@end

@implementation FHSTwitterEngineController

- (void)loadView {
    [super loadView];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(pasteboardChanged:) name:UIPasteboardChangedNotification object:nil];
    
    self.view = [[UIView alloc]initWithFrame:UIScreen.mainScreen.bounds];
    self.view.backgroundColor = [UIColor lightGrayColor];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    self.navBar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, (UIDevice.currentDevice.systemVersion.floatValue >= 7.0f)?64:44)];
    _navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    UINavigationItem *navItem = [[UINavigationItem alloc]initWithTitle:@"Twitter Login"];
	navItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(close)];
	[_navBar pushNavigationItem:navItem animated:NO];
    
    self.theWebView = [[UIWebView alloc]initWithFrame:CGRectMake(0, _navBar.bounds.size.height, self.view.bounds.size.width, self.view.bounds.size.height-_navBar.bounds.size.height)];
    _theWebView.hidden = YES;
    _theWebView.delegate = self;
    _theWebView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _theWebView.dataDetectorTypes = UIDataDetectorTypeNone;
    _theWebView.scrollView.clipsToBounds = NO;
    _theWebView.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:_theWebView];
    [self.view addSubview:_navBar];
    
    self.loadingText = [[UILabel alloc]initWithFrame:CGRectMake((self.view.bounds.size.width/2)-40, (self.view.bounds.size.height/2)-10-7.5, 100, 15)];
	_loadingText.text = @"Please Wait...";
	_loadingText.backgroundColor = [UIColor clearColor];
	_loadingText.textColor = [UIColor blackColor];
	_loadingText.textAlignment = NSTextAlignmentLeft;
	_loadingText.font = [UIFont boldSystemFontOfSize:15];
	[self.view addSubview:_loadingText];
	
	self.spinner = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	_spinner.center = CGPointMake((self.view.bounds.size.width/2)-60, (self.view.bounds.size.height/2)-10);
	[self.view addSubview:_spinner];
	[_spinner startAnimating];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            NSString *reqString = [[FHSTwitterEngine sharedEngine]getRequestTokenString];

            if (reqString.length == 0) {
                double delayInSeconds = 0.5;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(),^(void) {
                    @autoreleasepool {
                        [self dismissViewControllerAnimated:YES completion:nil];
                    }
                });
            } else {
                self.requestToken = [FHSToken tokenWithHTTPResponseBody:reqString];
                NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.twitter.com/oauth/authorize?oauth_token=%@",_requestToken.key]]];
                
                dispatch_sync(dispatch_get_main_queue(), ^{
                    @autoreleasepool {
                        [_theWebView loadRequest:request];
                    }
                });
            }
        }
    });
}

- (void)gotPin:(NSString *)pin {
    _requestToken.verifier = pin;
    BOOL ret = [[FHSTwitterEngine sharedEngine]finishAuthWithRequestToken:_requestToken];
    
    void(^block)(BOOL success) = objc_getAssociatedObject(self, "FHSTwitterEngineOAuthCompletion");
    
    if (block) {
        block(ret);
    }
    
    objc_setAssociatedObject(self, "FHSTwitterEngineOAuthCompletion", nil, OBJC_ASSOCIATION_COPY_NONATOMIC);
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)pasteboardChanged:(NSNotification *)note {
	
	if (![note.userInfo objectForKey:UIPasteboardChangedTypesAddedKey]) {
        return;
    }
    
    NSString *string = [[UIPasteboard generalPasteboard]string];
	
	if (string.length != 7 || !string.fhs_isNumeric) {
        return;
    }
	
	[self gotPin:string];
}

- (NSString *)locatePin {
	NSString *pin = [[_theWebView stringByEvaluatingJavaScriptFromString:newPinJS]stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	if (pin.length == 7) {
		return pin;
	} else {
		pin = [[_theWebView stringByEvaluatingJavaScriptFromString:oldPinJS]stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
		if (pin.length == 7) {
			return pin;
		}
	}
	return nil;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    _theWebView.userInteractionEnabled = YES;
    NSString *authPin = [self locatePin];
    
    if (authPin.length > 0) {
        [self gotPin:authPin];
        return;
    }
    
    NSString *formCount = [webView stringByEvaluatingJavaScriptFromString:@"document.forms.length"];
    
    if ([formCount isEqualToString:@"0"]) {
        _navBar.topItem.title = @"Select and Copy the PIN";
    }
	
	[UIView beginAnimations:nil context:nil];
    _spinner.hidden = YES;
    _loadingText.hidden = YES;
	[UIView commitAnimations];
	
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    _theWebView.hidden = NO;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    _theWebView.userInteractionEnabled = NO;
    [_theWebView setHidden:YES];
    _spinner.hidden = NO;
    _loadingText.hidden = NO;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    if (strstr([request.URL.absoluteString UTF8String], "denied=")) {
		[self dismissViewControllerAnimated:YES completion:nil];
        return NO;
    }
    
    NSData *data = request.HTTPBody;
	char *raw = data?(char *)[data bytes]:"";
	
	if (raw && (strstr(raw, "cancel=") || strstr(raw, "deny="))) {
        [self close];
		return NO;
	}
    
	return YES;
}

- (void)close {
    [self dismissViewControllerAnimated:YES completion:^(void){
        [[NSNotificationCenter defaultCenter] postNotificationName:@"FHSTwitterEngineControllerDidCancel" object:nil userInfo:nil];
    }];
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [_theWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@""]]];
    [super dismissViewControllerAnimated:flag completion:completion];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

@end
