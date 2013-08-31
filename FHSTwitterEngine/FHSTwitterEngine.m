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

#import "OAuthConsumer.h"

#include "Base64TranscoderFHS.h"

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

static FHSTwitterEngine *sharedInstance = nil;
static NSString * const authBlockKey = @"FHSTwitterEngineOAuthCompletion";

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
static NSString * const url_statuses_oembed = @"https://api.twitter.com/1.1/statuses/oembed.json";

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

@interface FHSToken : NSObject

@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSString *secret;
@property (nonatomic, strong) NSString *verifier;

+ (FHSToken *)tokenWithHTTPResponseBody:(NSString *)body;
- (id)initWithHTTPResponseBody:(NSString *)body;

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

@property (nonatomic, retain) UINavigationBar *navBar;
@property (nonatomic, retain) UIView *blockerView;
@property (nonatomic, retain) UIToolbar *pinCopyBar;

@property (nonatomic, retain) UIWebView *theWebView;
@property (nonatomic, retain) OAToken *requestToken;

- (NSString *)locatePin;
- (void)showPinCopyPrompt;

@end

@interface FHSTwitterEngine ()

// Login stuff
- (NSString *)getRequestTokenString;

// General Get request sender
- (id)sendRequest:(NSURLRequest *)request;

// These are here to obfuscate them from prying eyes
@property (retain, nonatomic) OAConsumer *consumer;
@property (assign, nonatomic) BOOL shouldClearConsumer;
@property (retain, nonatomic) NSDateFormatter *dateFormatter;

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
	return [(NSString *)url autorelease];
}

- (NSString *)fhs_trimForTwitter {
    NSString *string = [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return (string.length > 140)?[string substringToIndex:140]:string;
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
        NSString *uuid = [NSString stringWithString:(NSString *)string];
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

@implementation FHSTwitterEngine

- (id)listFollowersForUser:(NSString *)user isID:(BOOL)isID withCursor:(NSString *)cursor {
    
    if (user.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_friends_list];
    
    OAMutableURLRequest *request = [OAMutableURLRequest requestWithURL:baseURL consumer:self.consumer token:self.accessToken];
    OARequestParameter *skipstatusP = [OARequestParameter requestParameterWithName:@"skip_status" value:@"true"];
    OARequestParameter *include_entitiesP = [OARequestParameter requestParameterWithName:@"include_entities" value:self.includeEntities?@"true":@"false"];
    OARequestParameter *screen_nameP = [OARequestParameter requestParameterWithName:isID?@"user_id":@"screen_name" value:user];
    OARequestParameter *cursorP = [OARequestParameter requestParameterWithName:@"cursor" value:cursor];
    return [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:include_entitiesP, skipstatusP, screen_nameP, cursorP, nil]];
}

- (id)listFriendsForUser:(NSString *)user isID:(BOOL)isID withCursor:(NSString *)cursor {
    
    if (user.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_friends_list];
    OAMutableURLRequest *request = [OAMutableURLRequest requestWithURL:baseURL consumer:self.consumer token:self.accessToken];
    OARequestParameter *skipstatusP = [OARequestParameter requestParameterWithName:@"skip_status" value:@"true"];
    OARequestParameter *include_entitiesP = [OARequestParameter requestParameterWithName:@"include_entities" value:self.includeEntities?@"true":@"false"];
    OARequestParameter *screen_nameP = [OARequestParameter requestParameterWithName:isID?@"user_id":@"screen_name" value:user];
    OARequestParameter *cursorP = [OARequestParameter requestParameterWithName:@"cursor" value:cursor];
    return [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:include_entitiesP, skipstatusP, screen_nameP, cursorP, nil]];
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
    OAMutableURLRequest *request = [OAMutableURLRequest requestWithURL:baseURL consumer:self.consumer token:self.accessToken];
    OARequestParameter *include_entitiesP = [OARequestParameter requestParameterWithName:@"include_entities" value:self.includeEntities?@"true":@"false"];
    OARequestParameter *countP = [OARequestParameter requestParameterWithName:@"count" value:[NSString stringWithFormat:@"%d",count]];
    OARequestParameter *qP = [OARequestParameter requestParameterWithName:@"q" value:q];
    return [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:include_entitiesP, countP, qP, nil]];
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
    OAMutableURLRequest *request = [OAMutableURLRequest requestWithURL:baseURL consumer:self.consumer token:self.accessToken];
    OARequestParameter *include_entitiesP = [OARequestParameter requestParameterWithName:@"include_entities" value:self.includeEntities?@"true":@"false"];
    OARequestParameter *countP = [OARequestParameter requestParameterWithName:@"count" value:[NSString stringWithFormat:@"%d",count]];
    OARequestParameter *untilP = [OARequestParameter requestParameterWithName:@"until" value:nil];
    OARequestParameter *result_typeP = [OARequestParameter requestParameterWithName:@"result_type" value:nil];
    OARequestParameter *qP = [OARequestParameter requestParameterWithName:@"q" value:q];
    
    [self.dateFormatter setDateFormat:@"YYYY-MM-DD"];
    NSString *untilString = [self.dateFormatter stringFromDate:untilDate];
    [self.dateFormatter setDateFormat:@"EEE MMM dd HH:mm:ss ZZZZ yyyy"];
    
    untilP.value = untilString;

    if (resultType == FHSTwitterEngineResultTypeMixed) {
        result_typeP.value = @"mixed";
    } else if (resultType == FHSTwitterEngineResultTypeRecent) {
        result_typeP.value = @"recent";
    } else if (resultType == FHSTwitterEngineResultTypePopular) {
        result_typeP.value = @"popular";
    }
    
    NSMutableArray *params = [NSMutableArray arrayWithObjects:countP, include_entitiesP, qP, nil];
    
    if (maxID.length > 0) {
        [params addObject:[OARequestParameter requestParameterWithName:@"max_id" value:maxID]];
    }
    
    if (sinceID.length > 0) {
        [params addObject:[OARequestParameter requestParameterWithName:@"since_id" value:sinceID]];
    }
    
    return [self sendGETRequest:request withParameters:params];
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
    OAMutableURLRequest *request = [OAMutableURLRequest requestWithURL:baseURL consumer:self.consumer token:self.accessToken];
    OARequestParameter *listIDP = [OARequestParameter requestParameterWithName:@"list_id" value:listID];
    return [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:listIDP, nil]];
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
    OAMutableURLRequest *request = [OAMutableURLRequest requestWithURL:baseURL consumer:self.consumer token:self.accessToken];
    OARequestParameter *listIDP = [OARequestParameter requestParameterWithName:@"list_id" value:listID];
    return [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:listIDP, nil]];
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
    OAMutableURLRequest *request = [OAMutableURLRequest requestWithURL:baseURL consumer:self.consumer token:self.accessToken];
    OARequestParameter *countP = [OARequestParameter requestParameterWithName:@"count" value:[NSString stringWithFormat:@"%d",count]];
    OARequestParameter *excludeRepliesP = [OARequestParameter requestParameterWithName:@"exclude_replies" value:excludeReplies?@"true":@"false"];
    OARequestParameter *includeRTsP = [OARequestParameter requestParameterWithName:@"include_rts" value:excludeRetweets?@"false":@"true"];
    OARequestParameter *listIDP = [OARequestParameter requestParameterWithName:@"list_id" value:listID];
    
    NSMutableArray *params = [NSMutableArray arrayWithObjects:countP, excludeRepliesP, includeRTsP, listIDP, nil];
    
    if (sinceID.length > 0) {
        [params addObject:[OARequestParameter requestParameterWithName:@"since_id" value:sinceID]];
    }
    
    if (maxID.length > 0) {
        [params addObject:[OARequestParameter requestParameterWithName:@"max_id" value:maxID]];
    }
    
    return [self sendGETRequest:request withParameters:params];
}

- (id)getListsForUser:(NSString *)user isID:(BOOL)isID {
    
    if (user.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_lists_list];
    OAMutableURLRequest *request = [OAMutableURLRequest requestWithURL:baseURL consumer:self.consumer token:self.accessToken];
    OARequestParameter *userP = [OARequestParameter requestParameterWithName:isID?@"user_id":@"screen_name" value:user];
    return [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:userP, nil]];
}

- (id)getRetweetsForTweet:(NSString *)identifier count:(int)count {
    
    if (count == 0) {
        return nil;
    }
    
    if (identifier.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.twitter.com/1.1/statuses/retweets/%@.json",identifier]];
    OAMutableURLRequest *request = [OAMutableURLRequest requestWithURL:baseURL consumer:self.consumer token:self.accessToken];
    OARequestParameter *identifierP = [OARequestParameter requestParameterWithName:@"count" value:[NSString stringWithFormat:@"%d",count]];
    return [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:identifierP, nil]];
}

- (id)getRetweetedTimelineWithCount:(int)count {
    return [self getRetweetedTimelineWithCount:count sinceID:nil maxID:nil];
}

- (id)getRetweetedTimelineWithCount:(int)count sinceID:(NSString *)sinceID maxID:(NSString *)maxID {
    
    if (count == 0) {
        return nil;
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_statuses_retweets_of_me];
    OAMutableURLRequest *request = [OAMutableURLRequest requestWithURL:baseURL consumer:self.consumer token:self.accessToken];
    OARequestParameter *countP = [OARequestParameter requestParameterWithName:@"count" value:[NSString stringWithFormat:@"%d",count]];
    OARequestParameter *excludeRepliesP = [OARequestParameter requestParameterWithName:@"exclude_replies" value:@"false"];
    OARequestParameter *includeRTsP = [OARequestParameter requestParameterWithName:@"include_rts" value:@"true"];
    
    NSMutableArray *params = [NSMutableArray array];
    [params addObject:countP];
    [params addObject:excludeRepliesP];
    [params addObject:includeRTsP];
    
    if (sinceID.length > 0) {
        [params addObject:[OARequestParameter requestParameterWithName:@"since_id" value:sinceID]];
    }
    
    if (maxID.length > 0) {
        [params addObject:[OARequestParameter requestParameterWithName:@"max_id" value:maxID]];
    }
    
    return [self sendGETRequest:request withParameters:params];
}

- (id)getMentionsTimelineWithCount:(int)count {
    return [self getMentionsTimelineWithCount:count sinceID:nil maxID:nil];
}

- (id)getMentionsTimelineWithCount:(int)count sinceID:(NSString *)sinceID maxID:(NSString *)maxID {
    
    if (count == 0) {
        return nil;
    }

    NSURL *baseURL = [NSURL URLWithString:url_statuses_metions_timeline];
    OAMutableURLRequest *request = [OAMutableURLRequest requestWithURL:baseURL consumer:self.consumer token:self.accessToken];
    OARequestParameter *countP = [OARequestParameter requestParameterWithName:@"count" value:[NSString stringWithFormat:@"%d",count]];
    OARequestParameter *excludeRepliesP = [OARequestParameter requestParameterWithName:@"exclude_replies" value:@"false"];
    OARequestParameter *includeRTsP = [OARequestParameter requestParameterWithName:@"include_rts" value:@"true"];

    NSMutableArray *params = [NSMutableArray array];
    [params addObject:countP];
    [params addObject:excludeRepliesP];
    [params addObject:includeRTsP];
    
    if (sinceID.length > 0) {
        [params addObject:[OARequestParameter requestParameterWithName:@"since_id" value:sinceID]];
    }
    
    if (maxID.length > 0) {
        [params addObject:[OARequestParameter requestParameterWithName:@"max_id" value:maxID]];
    }
    
    return [self sendGETRequest:request withParameters:params];
}

- (NSError *)postTweet:(NSString *)tweetString withImageData:(NSData *)theData {
    return [self postTweet:tweetString withImageData:theData inReplyTo:nil];
}

- (NSError *)postTweet:(NSString *)tweetString withImageData:(NSData *)theData inReplyTo:(NSString *)irt {
    
    if (tweetString.length == 0) {
        return [NSError badRequestError];
    } else if (theData.length == 0) {
        if (irt.length == 0) {
            return [self postTweet:tweetString];
        } else {
            return [self postTweet:tweetString inReplyTo:irt];
        }
    }

    NSURL *baseURL = [NSURL URLWithString:url_statuses_update_with_media];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"media[]"] = theData;
    
    if (irt.length > 0) {
        params[@"in_reply_to_status_id"] = irt;
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
    OAMutableURLRequest *request = [OAMutableURLRequest requestWithURL:baseURL consumer:self.consumer token:self.accessToken];
    OARequestParameter *identifierP = [OARequestParameter requestParameterWithName:@"id" value:identifier];
    OARequestParameter *includeMyRetweet = [OARequestParameter requestParameterWithName:@"include_my_retweet" value:@"true"];
    return [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:includeMyRetweet, identifierP, nil]];
}

- (id)oembedTweet:(NSString *)identifier maxWidth:(float)maxWidth alignmentMode:(FHSTwitterEngineAlignMode)alignmentMode {
    
    if (identifier.length == 0) {
        return [NSError badRequestError];
    }
    
    NSString *language = [[NSLocale preferredLanguages]objectAtIndex:0];
    NSString *alignment = [[NSArray arrayWithObjects:@"left", @"right", @"center", @"none", nil]objectAtIndex:alignmentMode];
    
    NSURL *baseURL = [NSURL URLWithString:url_statuses_oembed];
    OAMutableURLRequest *request = [OAMutableURLRequest requestWithURL:baseURL consumer:self.consumer token:self.accessToken];
    OARequestParameter *identifierP = [OARequestParameter requestParameterWithName:@"id" value:identifier];
    OARequestParameter *maxWidthP = [OARequestParameter requestParameterWithName:@"maxwidth" value:[NSString stringWithFormat:@"%f",maxWidth]];
    OARequestParameter *languageP= [OARequestParameter requestParameterWithName:@"lang" value:language];
    OARequestParameter *alignmentP = [OARequestParameter requestParameterWithName:@"align" value:alignment];
    return [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:identifierP, maxWidthP, languageP,alignmentP, nil]];
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
    OAMutableURLRequest *request = [OAMutableURLRequest requestWithURL:baseURL consumer:self.consumer token:self.accessToken];
    OARequestParameter *countP = [OARequestParameter requestParameterWithName:@"count" value:[NSString stringWithFormat:@"%d",count]];
    OARequestParameter *userP = [OARequestParameter requestParameterWithName:isID?@"user_id":@"screen_name" value:user];
    OARequestParameter *excludeRepliesP = [OARequestParameter requestParameterWithName:@"exclude_replies" value:@"false"];
    OARequestParameter *includeRTsP = [OARequestParameter requestParameterWithName:@"include_rts" value:@"true"];

    NSMutableArray *params = [NSMutableArray array];
    [params addObject:countP];
    [params addObject:userP];
    [params addObject:excludeRepliesP];
    [params addObject:includeRTsP];
    
    if (sinceID.length > 0) {
        [params addObject:[OARequestParameter requestParameterWithName:@"since_id" value:sinceID]];
    }
    
    if (maxID.length > 0) {
        [params addObject:[OARequestParameter requestParameterWithName:@"max_id" value:maxID]];
    }
    
    return [self sendGETRequest:request withParameters:params];
}

- (id)getProfileImageForUsername:(NSString *)username andSize:(FHSTwitterEngineImageSize)size {
    
    if (username.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_users_show];
    OAMutableURLRequest *request = [OAMutableURLRequest requestWithURL:baseURL consumer:self.consumer token:self.accessToken];
    OARequestParameter *usernameP = [OARequestParameter requestParameterWithName:@"screen_name" value:username];
    
    NSArray *params = [NSArray arrayWithObjects:usernameP, nil];
    
    id userShowReturn = [self sendGETRequest:request withParameters:params];
    
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

- (id)authenticatedUserIsBlocking:(NSString *)user isID:(BOOL)isID {
    
    if (user.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_blocks_exists];
    OAMutableURLRequest *request = [OAMutableURLRequest requestWithURL:baseURL consumer:self.consumer token:self.accessToken];
    OARequestParameter *userP = [OARequestParameter requestParameterWithName:isID?@"user_id":@"screen_name" value:user];
    OARequestParameter *skipstatusP = [OARequestParameter requestParameterWithName:@"skip_status" value:@"true"];
    
    id obj = [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:skipstatusP, userP, nil]];
    
    if ([obj isKindOfClass:[NSError class]]) {
        return obj;
    } else if ([obj isKindOfClass:[NSDictionary class]]) {
        if ([[obj objectForKey:@"error"]isEqualToString:@"You are not blocking this user."]) {
            return @"NO";
        } else {
            return @"YES";
        }
    }
    
    return [NSError badRequestError];
}

- (id)listBlockedUsers {
    NSURL *baseURL = [NSURL URLWithString:url_blocks_blocking];
    OAMutableURLRequest *request = [OAMutableURLRequest requestWithURL:baseURL consumer:self.consumer token:self.accessToken];
    OARequestParameter *skipstatusP = [OARequestParameter requestParameterWithName:@"skip_status" value:@"true"];
    return [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:skipstatusP, nil]];
}

- (id)listBlockedIDs {
    NSURL *baseURL = [NSURL URLWithString:url_blocks_blocking_ids];
    OAMutableURLRequest *request = [OAMutableURLRequest requestWithURL:baseURL consumer:self.consumer token:self.accessToken];
    OARequestParameter *stringifyIDsP = [OARequestParameter requestParameterWithName:@"stringify_ids" value:@"true"];
    
    id object = [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:stringifyIDsP, nil]];
    
    if ([object isKindOfClass:[NSDictionary class]]) {
        return [(NSDictionary *)object objectForKey:@"ids"];
    }
    return object;
}

- (id)getLanguages {
    NSURL *baseURL = [NSURL URLWithString:url_help_languages];
    OAMutableURLRequest *request = [OAMutableURLRequest requestWithURL:baseURL consumer:self.consumer token:self.accessToken];
    return [self sendGETRequest:request withParameters:nil];
}

- (id)getConfiguration {
    NSURL *baseURL = [NSURL URLWithString:url_help_configuration];
    OAMutableURLRequest *request = [OAMutableURLRequest requestWithURL:baseURL consumer:self.consumer token:self.accessToken];
    return [self sendGETRequest:request withParameters:nil];
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
    OAMutableURLRequest *request = [OAMutableURLRequest requestWithURL:baseURL consumer:self.consumer token:self.accessToken];
    OARequestParameter *id_ = [OARequestParameter requestParameterWithName:@"id" value:messageID];
    return [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:id_, nil]];
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
    OAMutableURLRequest *request = [OAMutableURLRequest requestWithURL:baseURL consumer:self.consumer token:self.accessToken];
    OARequestParameter *countP = [OARequestParameter requestParameterWithName:@"count" value:[NSString stringWithFormat:@"%d",count]];
    return [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:countP, nil]];
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
    OAMutableURLRequest *request = [OAMutableURLRequest requestWithURL:baseURL consumer:self.consumer token:self.accessToken];
    OARequestParameter *countP = [OARequestParameter requestParameterWithName:@"count" value:[NSString stringWithFormat:@"%d",count]];
    OARequestParameter *skipStatusP = [OARequestParameter requestParameterWithName:@"skip_status" value:@"true"];
    return [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:countP, skipStatusP, nil]];
}

- (id)getPrivacyPolicy {
    NSURL *baseURL = [NSURL URLWithString:url_help_privacy];
    OAMutableURLRequest *request = [OAMutableURLRequest requestWithURL:baseURL consumer:self.consumer token:self.accessToken];
    
    id object = [self sendGETRequest:request withParameters:nil];
    
    if ([object isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = (NSDictionary *)object;
        if ([dict.allKeys containsObject:@"privacy"]) {
            return [dict objectForKey:@"privacy"];
        }
    }
    return object;
}

- (id)getTermsOfService {
    NSURL *baseURL = [NSURL URLWithString:url_help_tos];
    OAMutableURLRequest *request = [OAMutableURLRequest requestWithURL:baseURL consumer:self.consumer token:self.accessToken];
    
    id object = [self sendGETRequest:request withParameters:nil];
    
    if ([object isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = (NSDictionary *)object;
        if ([dict.allKeys containsObject:@"tos"]) {
            return [dict objectForKey:@"tos"];
        }
    }
    return object;
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
    OAMutableURLRequest *request = [OAMutableURLRequest requestWithURL:baseURL consumer:self.consumer token:self.accessToken];
    OARequestParameter *stringifyIDsP = [OARequestParameter requestParameterWithName:@"stringify_ids" value:@"true"];
    
    id object = [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:stringifyIDsP, nil]];
    
    if ([object isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = (NSDictionary *)object;
        if ([dict.allKeys containsObject:@"ids"]) {
            return [dict objectForKey:@"ids"];
        }
    }
    return object;
}

- (id)getPendingIncomingFollowers {
    NSURL *baseURL = [NSURL URLWithString:url_friendships_incoming];
    OAMutableURLRequest *request = [OAMutableURLRequest requestWithURL:baseURL consumer:self.consumer token:self.accessToken];
    OARequestParameter *stringifyIDsP = [OARequestParameter requestParameterWithName:@"stringify_ids" value:@"true"];
    
    id object = [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:stringifyIDsP, nil]];
    
    if ([object isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = (NSDictionary *)object;
        if ([dict.allKeys containsObject:@"ids"]) {
            return [dict objectForKey:@"ids"];
        }
    }
    return object;
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
    return [self sendPOSTRequestForURL:baseURL andParams:@{@"skip_status":@"true", @"use":@"true", @"include_entities":_includeEntities?@"true":@"false", @"tiled":(isTiled?@"true":@"false"), @"image":[data base64EncodingWithLineLength:0]}];
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
    return [self sendPOSTRequestForURL:baseURL andParams:@{@"skip_status":@"true", @"include_entities":(_includeEntities?@"true":@"false"), @"image":[data base64EncodingWithLineLength:0]}];
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

    id retValue = [self sendGETRequestForURL:baseURL andParams:nil];
    
    if ([retValue isKindOfClass:[NSString class]]) {
        if ([(NSString *)retValue isEqualToString:@"ok"]) {
            return @"YES";
        } else {
            return @"NO";
        }
    } else if ([retValue isKindOfClass:[NSError class]]) {
        return retValue;
    }
    
    return [NSError badRequestError];
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

- (NSError *)postTweet:(NSString *)tweetString inReplyTo:(NSString *)inReplyToString {
    if (tweetString.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_statuses_update];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:2];
    params[@"status"] = tweetString;
    
    if (inReplyToString.length > 0) {
        params[@"in_reply_to_status_id"] = inReplyToString;
    }

    return [self sendPOSTRequestForURL:baseURL andParams:params];
}

- (NSError *)postTweet:(NSString *)tweetString {
    return [self postTweet:tweetString inReplyTo:nil];
}

- (id)getFollowersIDs {
    NSURL *baseURL = [NSURL URLWithString:url_followers_ids];
    return [self sendGETRequestForURL:baseURL andParams:@{ @"screen_name": _loggedInUsername, @"stringify_ids":@"true"}];
}

- (id)getFriendsIDs {
    NSURL *baseURL = [NSURL URLWithString:url_friends_ids];
    return [self sendGETRequestForURL:baseURL andParams:@{ @"screen_name": _loggedInUsername, @"stringify_ids":@"true"}];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // Twitter API datestamps are UTC
        // Don't question this code.
        self.dateFormatter = [[[NSDateFormatter alloc]init]autorelease];
        _dateFormatter.locale = [[[NSLocale alloc]initWithLocaleIdentifier:@"en_US"]autorelease];
        _dateFormatter.dateStyle = NSDateFormatterLongStyle;
        _dateFormatter.formatterBehavior = NSDateFormatterBehavior10_4;
        _dateFormatter.dateFormat = @"EEE MMM dd HH:mm:ss ZZZZ yyyy";
    }
    return self;
}

// The shared* class method
+ (FHSTwitterEngine *)sharedEngine {
    @synchronized (self) {
        if (sharedInstance == nil) {
            [[self alloc]init];
        }
    }
    return sharedInstance;
}

// Override stuff to make sure that the singleton is never dealloc'd. Fun.
+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (sharedInstance == nil) {
            sharedInstance = [super allocWithZone:zone];
            return sharedInstance;
        }
    }
    return nil;
}

- (id)retain {
    return self;
}

- (oneway void)release {
    // Do nothing
}

- (id)autorelease {
    return self;
}

- (NSUInteger)retainCount {
    return NSUIntegerMax;
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
    char base64Result[32];
    size_t theResultLength = 32;
    Base64EncodeDataFHS(result, 20, base64Result, &theResultLength);
    NSData *theData = [NSData dataWithBytes:base64Result length:theResultLength];
    
    NSString *signature = [[[[NSString alloc]initWithData:theData encoding:NSUTF8StringEncoding]autorelease]fhs_URLEncode];
    
	NSString *oauthToken = (tokenString.length > 0)?[NSString stringWithFormat:@"oauth_token=\"%@\", ",[tokenString fhs_URLEncode]]:@"oauth_callback=\"oob\", ";
    NSString *oauthVerifier = (verifierString.length > 0)?[NSString stringWithFormat:@"oauth_verifier=\"%@\", ",verifierString]:@"";

    NSString *oauthHeader = [NSString stringWithFormat:@"OAuth oauth_consumer_key=\"%@\", %@%@oauth_signature_method=\"HMAC-SHA1\", oauth_signature=\"%@\", oauth_timestamp=\"%@\", oauth_nonce=\"%@\", oauth_version=\"1.0\"",consumerKey,oauthToken,oauthVerifier,signature,timestamp,nonce];
    
    NSLog(@"OAuth header: %@",oauthHeader);
	
    [request setValue:oauthHeader forHTTPHeaderField:@"Authorization"];
}

- (NSError *)sendPOSTRequestForURL:(NSURL *)url andParams:(NSDictionary *)params {
    
    if (![self isAuthorized]) {
        [self loadAccessToken];
        if (![self isAuthorized]) {
            return [NSError errorWithDomain:FHSErrorDomain code:401 userInfo:@{NSLocalizedDescriptionKey:@"You are not authorized via OAuth", @"url": url, @"parameters": params}];
        }
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0f];
    [request setHTTPMethod:@"POST"];
    [request setHTTPShouldHandleCookies:NO];
    
    NSString *boundary = [NSString fhs_UUID];
    
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
    [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
    
    [self signRequest:request];
    
    NSMutableData *body = [NSMutableData dataWithLength:0];

    for (NSString *key in params.allKeys) {
        id obj = params[key];

        [body appendData:[[NSString stringWithFormat:@"--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        
        NSData *data = nil;
        
        if ([obj isKindOfClass:[NSData class]]) {
            [body appendData:[@"Content-Type: application/octet-stream\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
            data = (NSData *)obj;
        } else if ([obj isKindOfClass:[NSString class]]) {
            data = [[NSString stringWithFormat:@"%@\r\n",(NSString *)obj]dataUsingEncoding:NSUTF8StringEncoding];
        }
        
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n",key] dataUsingEncoding:NSUTF8StringEncoding]];
        
        [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:data];
    }
    
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [request setValue:@(body.length).stringValue forHTTPHeaderField:@"Content-Length"];
    request.HTTPBody = body;
    
    id retobj = [self sendRequest:request];
    
    if (retobj == nil) {
        return [NSError noDataError];
    }
    
    if ([retobj isKindOfClass:[NSError class]]) {
        return retobj;
    }
    
    id parsed = removeNull([NSJSONSerialization JSONObjectWithData:(NSData *)retobj options:NSJSONReadingMutableContainers error:nil]);
    
    if ([parsed isKindOfClass:[NSDictionary class]]) {
        NSString *errorMessage = parsed[@"error"];
        NSArray *errorArray = parsed[@"errors"];
        if (errorMessage.length > 0) {
            return [NSError errorWithDomain:FHSErrorDomain code:[parsed[@"code"] intValue] userInfo:@{NSLocalizedDescriptionKey: errorMessage, @"request":request}];
        } else if (errorArray.count > 0) {
            if (errorArray.count > 1) {
                return [NSError errorWithDomain:FHSErrorDomain code:418 userInfo:@{NSLocalizedDescriptionKey:@"There were multiple errors when processing the request.", @"request":request}];
            } else {
                NSDictionary *theError = errorArray[0];
                return [NSError errorWithDomain:FHSErrorDomain code:[theError[@"code"]integerValue] userInfo:@{NSLocalizedDescriptionKey: theError[@"message"], @"request":request}];
            }
        }
    }
    
    return nil; // eventually return the parsed response
}

- (id)sendGETRequestForURL:(NSURL *)url andParams:(NSDictionary *)params {
    
    if (![self isAuthorized]) {
        [self loadAccessToken];
        if (![self isAuthorized]) {
            return [NSError errorWithDomain:FHSErrorDomain code:401 userInfo:@{NSLocalizedDescriptionKey:@"You are not authorized via OAuth", @"url": url, @"parameters": params}];
        }
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
    
    if (retobj == nil) {
        return [NSError noDataError];
    }
    
    if ([retobj isKindOfClass:[NSError class]]) {
        return retobj;
    }
    
    id parsed = removeNull([NSJSONSerialization JSONObjectWithData:(NSData *)retobj options:NSJSONReadingMutableContainers error:nil]);
    
    if ([parsed isKindOfClass:[NSDictionary class]]) {
        NSString *errorMessage = parsed[@"error"];
        NSArray *errorArray = parsed[@"errors"];
        if (errorMessage.length > 0) {
            return [NSError errorWithDomain:FHSErrorDomain code:[parsed[@"code"] intValue] userInfo:@{NSLocalizedDescriptionKey: errorMessage, @"request":request}];
        } else if (errorArray.count > 0) {
            if (errorArray.count > 1) {
                return [NSError errorWithDomain:FHSErrorDomain code:418 userInfo:@{NSLocalizedDescriptionKey:@"There were multiple errors when processing the request.", @"request":request}];
            } else {
                NSDictionary *theError = errorArray[0];
                return [NSError errorWithDomain:FHSErrorDomain code:[theError[@"code"]integerValue] userInfo:@{NSLocalizedDescriptionKey: theError[@"message"], @"request":request}];
            }
        }
    }
    
    return parsed;
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
        return [[[NSString alloc]initWithData:(NSData *)retobj encoding:NSUTF8StringEncoding]autorelease];
    }
    
    return nil;
}

- (BOOL)finishAuthWithRequestToken:(OAToken *)reqToken {

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
    
    NSString *response = [[[NSString alloc]initWithData:(NSData *)retobj encoding:NSUTF8StringEncoding]autorelease];
    
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
    
    /*
     
     NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"];
     NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0f];
     [request setHTTPMethod:@"POST"];
     [request setHTTPShouldHandleCookies:NO];
     [self signRequest:request withToken:nil tokenSecret:nil verifier:nil];
    */
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"];
    
	OAMutableURLRequest *request = [OAMutableURLRequest requestWithURL:baseURL consumer:self.consumer token:nil];
    OARequestParameter *x_auth_mode = [OARequestParameter requestParameterWithName:@"x_auth_mode" value:@"client_auth"];
    OARequestParameter *x_auth_username = [OARequestParameter requestParameterWithName:@"x_auth_username" value:username];
    OARequestParameter *x_auth_password = [OARequestParameter requestParameterWithName:@"x_auth_password" value:password];
	[request setHTTPMethod:@"POST"];
    
	[request setParameters:@[x_auth_mode, x_auth_username, x_auth_password]];
    [request prepare];
    
    if (self.shouldClearConsumer) {
        self.shouldClearConsumer = NO;
        self.consumer = nil;
    }
    
    id ret = [self sendRequest:request];
    
    if ([ret isKindOfClass:[NSError class]]) {
        return ret;
    } else if ([ret isKindOfClass:[NSData class]]) {
        NSString *httpBody = [[[NSString alloc]initWithData:(NSData *)ret encoding:NSUTF8StringEncoding]autorelease];
        
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
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(loadAccessToken)]) {
        savedHttpBody = [self.delegate loadAccessToken];
    } else {
        savedHttpBody = [[NSUserDefaults standardUserDefaults]objectForKey:@"SavedAccessHTTPBody"];
    }
    
    self.accessToken = [OAToken tokenWithHTTPResponseBody:savedHttpBody];
    self.loggedInUsername = [self extractValueForKey:@"screen_name" fromHTTPBody:savedHttpBody];
    self.loggedInID = [self extractValueForKey:@"user_id" fromHTTPBody:savedHttpBody];
}

- (void)storeAccessToken:(NSString *)accessTokenZ {
    self.accessToken = [OAToken tokenWithHTTPResponseBody:accessTokenZ];
    self.loggedInUsername = [self extractValueForKey:@"screen_name" fromHTTPBody:accessTokenZ];
    self.loggedInID = [self extractValueForKey:@"user_id" fromHTTPBody:accessTokenZ];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(storeAccessToken:)]) {
        [self.delegate storeAccessToken:accessTokenZ];
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
    self.loggedInUsername = nil;
}

- (void)clearConsumer {
    self.consumer = nil;
}

- (void)permanentlySetConsumerKey:(NSString *)consumerKey andSecret:(NSString *)consumerSecret {
    self.shouldClearConsumer = NO;
    self.consumer = [OAConsumer consumerWithKey:consumerKey secret:consumerSecret];
}

- (void)temporarilySetConsumerKey:(NSString *)consumerKey andSecret:(NSString *)consumerSecret {
    self.shouldClearConsumer = YES;
    self.consumer = [OAConsumer consumerWithKey:consumerKey secret:consumerSecret];
}

- (void)showOAuthLoginControllerFromViewController:(UIViewController *)sender {
    [self showOAuthLoginControllerFromViewController:sender withCompletion:nil];
}

- (void)showOAuthLoginControllerFromViewController:(UIViewController *)sender withCompletion:(void(^)(BOOL success))block {
    FHSTwitterEngineController *vc = [[[FHSTwitterEngineController alloc]init]autorelease];
    vc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    objc_setAssociatedObject(vc, "FHSTwitterEngineOAuthCompletion", block, OBJC_ASSOCIATION_COPY_NONATOMIC);
    [sender presentViewController:vc animated:YES completion:nil];
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

- (void)dealloc {
    [self setConsumer:nil];
    [self setDateFormatter:nil];
    [self setLoggedInUsername:nil];
    [self setLoggedInID:nil];
    [self setDelegate:nil];
    [self setAccessToken:nil];
    [super dealloc];
}

@end

@implementation FHSTwitterEngineController

static NSString * const newPinJS = @"var d = document.getElementById('oauth-pin'); if (d == null) d = document.getElementById('oauth_pin'); if (d) { var d2 = d.getElementsByTagName('code'); if (d2.length > 0) d2[0].innerHTML; }";
static NSString * const oldPinJS = @"var d = document.getElementById('oauth-pin'); if (d == null) d = document.getElementById('oauth_pin'); if (d) d = d.innerHTML; d;";

- (void)loadView {
    [super loadView];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(pasteboardChanged:) name:UIPasteboardChangedNotification object:nil];
    
    self.view = [[[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, 460)]autorelease];
    self.view.backgroundColor = [UIColor grayColor];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    self.theWebView = [[[UIWebView alloc]initWithFrame:CGRectMake(0, 44, 320, 416)]autorelease];
    _theWebView.hidden = YES;
    _theWebView.delegate = self;
    _theWebView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _theWebView.dataDetectorTypes = UIDataDetectorTypeNone;
    _theWebView.backgroundColor = [UIColor darkGrayColor];
    
    self.navBar = [[[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, 320, 44)]autorelease];
    _navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
	
	[self.view addSubview:_theWebView];
	[self.view addSubview:_navBar];
    
	self.blockerView = [[[UIView alloc]initWithFrame:CGRectMake(0, 0, 200, 60)]autorelease];
	_blockerView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.8];
	_blockerView.center = CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2);
	_blockerView.clipsToBounds = YES;
    _blockerView.layer.cornerRadius = 10;
    
    self.pinCopyBar = [[[UIToolbar alloc]initWithFrame:CGRectMake(0, 44, self.view.bounds.size.width, 44)]autorelease];
    _pinCopyBar.barStyle = UIBarStyleBlackTranslucent;
    _pinCopyBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    _pinCopyBar.items = [NSArray arrayWithObjects:[[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]autorelease], [[[UIBarButtonItem alloc]initWithTitle:@"Select and Copy the PIN" style: UIBarButtonItemStylePlain target:nil action: nil]autorelease], [[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]autorelease], nil];
	
	UILabel	*label = [[UILabel alloc]initWithFrame:CGRectMake(0, 5, _blockerView.bounds.size.width, 15)];
	label.text = @"Please Wait...";
	label.backgroundColor = [UIColor clearColor];
	label.textColor = [UIColor whiteColor];
	label.textAlignment = NSTextAlignmentCenter;
	label.font = [UIFont boldSystemFontOfSize:15];
	[_blockerView addSubview:label];
    [label release];
	
	UIActivityIndicatorView	*spinner = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	spinner.center = CGPointMake(_blockerView.bounds.size.width/2, (_blockerView.bounds.size.height/2)+10);
	[_blockerView addSubview:spinner];
	[self.view addSubview:_blockerView];
	[spinner startAnimating];
    [spinner release];
	
	UINavigationItem *navItem = [[[UINavigationItem alloc]initWithTitle:@"Twitter Login"]autorelease];
	navItem.leftBarButtonItem = [[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(close)]autorelease];
	[_navBar pushNavigationItem:navItem animated:NO];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    dispatch_async(GCDBackgroundThread, ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
        
        NSString *reqString = [[FHSTwitterEngine sharedEngine]getRequestTokenString];

        if (reqString.length == 0) {
            dispatch_sync(GCDMainThread, ^{
                NSAutoreleasePool *poolTwo = [[NSAutoreleasePool alloc]init];
               // [self dismissViewControllerAnimated:YES completion:nil];
                [poolTwo release];
            });
        } else {
            self.requestToken = [OAToken tokenWithHTTPResponseBody:reqString];
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.twitter.com/oauth/authorize?oauth_token=%@",_requestToken.key]]];
            
            dispatch_sync(GCDMainThread, ^{
                NSAutoreleasePool *poolTwo = [[NSAutoreleasePool alloc]init];
                [_theWebView loadRequest:request];
                [poolTwo release];
            });
        }

        [pool release];
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
        [self showPinCopyPrompt];
    }
	
	[UIView beginAnimations:nil context:nil];
	_blockerView.hidden = YES;
	[UIView commitAnimations];
	
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    _theWebView.hidden = NO;
}

- (void)showPinCopyPrompt {
	if (_pinCopyBar.superview) {
        return;
    }
    
	_pinCopyBar.center = CGPointMake(_pinCopyBar.bounds.size.width/2, _pinCopyBar.bounds.size.height/2);
	[self.view insertSubview:_pinCopyBar belowSubview:_navBar];
	
	[UIView beginAnimations:nil context:nil];
    _pinCopyBar.center = CGPointMake(_pinCopyBar.bounds.size.width/2, _navBar.bounds.size.height+_pinCopyBar.bounds.size.height/2);
	[UIView commitAnimations];
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    _theWebView.userInteractionEnabled = NO;
    [_theWebView setHidden:YES];
    [_blockerView setHidden:NO];
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
		[self dismissViewControllerAnimated:YES completion:nil];
		return NO;
	}
    
	return YES;
}

- (void)close {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dismissModalViewControllerAnimated:(BOOL)animated {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [_theWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@""]]];
    [super dismissModalViewControllerAnimated:animated];
}

- (void)dealloc {
    [self setNavBar:nil];
    [self setBlockerView:nil];
    [self setPinCopyBar:nil];
    [self setTheWebView:nil];
    [self setRequestToken:nil];
    [super dealloc];
}

@end


static char const encodingTable[64] = {
    'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P',
    'Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f',
    'g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v',
    'w','x','y','z','0','1','2','3','4','5','6','7','8','9','+','/' };

@implementation NSData (Base64)

+ (NSData *)dataWithBase64EncodedString:(NSString *)string {
	return [[[NSData alloc]initWithBase64EncodedString:string]autorelease];
}

- (id)initWithBase64EncodedString:(NSString *)string {
	NSMutableData *mutableData = nil;
    
	if (string) {
		unsigned long ixtext = 0;
		unsigned char ch = 0;
        unsigned char inbuf[4] = {0,0,0,0};
        unsigned char outbuf[3] = {0,0,0};
		short ixinbuf = 0;
		BOOL flignore = NO;
		BOOL flendtext = NO;
        
		NSData *base64Data = [string dataUsingEncoding:NSASCIIStringEncoding];
		const unsigned char *base64Bytes = [base64Data bytes];
		mutableData = [NSMutableData dataWithCapacity:base64Data.length];
		unsigned long lentext = [base64Data length];
        
        while (!(ixtext >= lentext)) {
            
			ch = base64Bytes[ixtext++];
			flignore = NO;
            
			if ((ch >= 'A') && (ch <= 'Z')) {
                ch = ch - 'A';
            } else if ((ch >= 'a') && (ch <= 'z')) {
                ch = ch - 'a' + 26;
            } else if ((ch >= '0') && (ch <= '9')) {
                ch = ch - '0' + 52;
            } else if (ch == '+') {
                ch = 62;
            } else if (ch == '=') {
                flendtext = YES;
            } else if (ch == '/') {
                ch = 63;
            } else {
                flignore = YES;
            }
            
			if (!flignore) {
				short ctcharsinbuf = 3;
				BOOL flbreak = NO;
                
				if (flendtext) {
					if (!ixinbuf) {
                        break;
                    }
                    
					if (ixinbuf == 1 || ixinbuf == 2) {
                        ctcharsinbuf = 1;
                    } else {
                        ctcharsinbuf = 2;
                    }
                    
					ixinbuf = 3;
					flbreak = YES;
				}
                
				inbuf[ixinbuf++] = ch;
                
				if (ixinbuf == 4) {
					ixinbuf = 0;
					outbuf[0] = (inbuf[0] << 2) | ((inbuf[1] & 0x30) >> 4);
					outbuf[1] = ((inbuf[1] & 0x0F) << 4) | ((inbuf[2] & 0x3C) >> 2);
					outbuf[2] = ((inbuf[2] & 0x03) << 6) | (inbuf[3] & 0x3F);
                    
					for (int i = 0; i < ctcharsinbuf; i++) {
						[mutableData appendBytes:&outbuf[i] length:1];
                    }
				}
                
				if (flbreak)  {
                    break;
                }
			}
		}
	}
    
	self = [self initWithData:mutableData];
	return self;
}

- (NSString *)base64EncodingWithLineLength:(unsigned int)lineLength {
    
	const unsigned char	*bytes = [self bytes];
	unsigned long ixtext = 0;
	unsigned long lentext = [self length];
	long ctremaining = 0;
    unsigned char inbuf[3] = {0,0,0};
    unsigned char outbuf[4] = {0,0,0,0};
    
	short charsonline = 0;
    short ctcopy = 0;
	unsigned long ix = 0;
    
    NSMutableString *result = [NSMutableString stringWithCapacity:lentext];
    
	while (YES) {
		ctremaining = lentext-ixtext;
        
		if (ctremaining <= 0) {
            break;
        }
        
		for (int i = 0; i < 3; i++) {
			ix = ixtext + i;
            inbuf[i] = (ix < lentext)?bytes[ix]:0;
		}
        
		outbuf[0] = (inbuf[0] & 0xFC) >> 2;
		outbuf[1] = ((inbuf[0] & 0x03) << 4) | ((inbuf[1] & 0xF0) >> 4);
		outbuf[2] = ((inbuf[1] & 0x0F) << 2) | ((inbuf[2] & 0xC0) >> 6);
		outbuf[3] = inbuf[2] & 0x3F;
        
		switch (ctremaining) {
            case 1:
                ctcopy = 2;
                break;
            case 2:
                ctcopy = 3;
                break;
            default:
                ctcopy = 4;
                break;
		}
        
		for (int i = 0; i < ctcopy; i++) {
			[result appendFormat:@"%c",encodingTable[outbuf[i]]];
        }
        
		for (int i = ctcopy; i < 4; i++) {
            [result appendString:@"="];
        }
        
		ixtext += 3;
		charsonline += 4;
        
		if (lineLength > 0) {
			if (charsonline >= lineLength) {
				charsonline = 0;
				[result appendString:@"\n"];
			}
		}
	}
	return result;
}

@end
