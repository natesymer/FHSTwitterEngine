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

#import <SystemConfiguration/SystemConfiguration.h>
#import <netinet/in.h>
#import <ifaddrs.h>

// These are internal
#import "FHSStream.h"
#import "FHSTwitterEngine+Requests.h"
#import "FHSTwitterEngine+Streaming.h"
#import "NSMutableURLRequest+OAuth.h"

@interface FHSTwitterEngine ()

@property BOOL shouldClearConsumer;

@end

@implementation FHSTwitterEngine

#pragma mark - Initialization

+ (instancetype)shared {
    static id shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [self new];
    });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

#pragma mark - Helpers

// Twitter API datestamps are UTC
// Set up the date formatter once. Allocating a
// new one takes a _long_ time
+ (NSDateFormatter *)dateFormatter {
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc]init];
        formatter.locale = [[NSLocale alloc]initWithLocaleIdentifier:@"en_US"];
        formatter.dateStyle = NSDateFormatterLongStyle;
        formatter.formatterBehavior = NSDateFormatterBehavior10_4;
        formatter.dateFormat = @"EEE MMM dd HH:mm:ss ZZZZ yyyy";
    });
    return formatter;
}

#pragma mark - REST API

- (id)listFollowersForUser:(NSString *)user isID:(BOOL)isID withCursor:(NSString *)cursor {
    if (user.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_followers_list];
    
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:@{
                                                                     @"skip_status": @"true",
                                                                     @"include_entities": (_includeEntities?@"true":@"false"),
                                                                     (isID?@"user_id":@"screen_name"): user,
                                                                     @"cursor": cursor
                                                                     }];
}

- (id)listFriendsForUser:(NSString *)user isID:(BOOL)isID withCursor:(NSString *)cursor {
    
    if (user.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_friends_list];
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:@{
                                                                     @"skip_status": @"true",
                                                                     @"include_entities": (_includeEntities?@"true":@"false"),
                                                                     (isID?@"user_id":@"screen_name"): user,
                                                                     @"cursor": cursor
                                                                     }];
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
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:@{
                                                                     @"include_entities": (_includeEntities?@"true":@"false"),
                                                                     @"count": @(count).stringValue,
                                                                     @"q": q
                                                                     }];
}

- (id)getContributees:(NSString *)user isID:(BOOL)isID skipStatus:(BOOL)skipStatus {
    if (user.length == 0) {
        return [NSError badRequestError];
    }

    NSURL *baseURL = [NSURL URLWithString:url_users_contributees];
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:@{
                                                                     @"skip_status": (skipStatus?@"true":@"false"),
                                                                     @"include_entities": (_includeEntities?@"true":@"false"),
                                                                     (isID?@"user_id":@"screen_name"): user,
                                                                     }];
}

- (id)getContributors:(NSString *)user isID:(BOOL)isID skipStatus:(BOOL)skipStatus {
    if (user.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_users_contributors];
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:@{
                                                                     @"skip_status": (skipStatus?@"true":@"false"),
                                                                     @"include_entities": (_includeEntities?@"true":@"false"),
                                                                     (isID?@"user_id":@"screen_name"): user,
                                                                     }];
}

- (id)accountRemoveProfileBanner {
    NSURL *baseURL = [NSURL URLWithString:url_account_remove_profile_banner];
    
    return [self sendRequestWithHTTPMethod:kPOST URL:baseURL params:nil];
}

- (id)accountUpdateProfileBanner:(UIImage*)banner width:(NSInteger)width height:(NSInteger)height offset_left:(NSInteger)offset_left offset_top:(NSInteger)offset_top {
    
    if (!banner) {
        return [NSError badRequestError];
    }
    
    if (width>0) {
        if ((height==0)||
            (offset_left==0)||
            (offset_top==0)
            )
            return [NSError badRequestError];
    }
    

    NSURL *baseURL = [NSURL URLWithString:url_account_update_profile_banner];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];    
    params[@"banner"] = UIImagePNGRepresentation(banner);
    params[@"width"] = @(width).stringValue;
    params[@"height"] = @(width).stringValue;
    params[@"offset_left"] = @(width).stringValue;
    params[@"offset_top"] = @(width).stringValue;
    
    return [self sendRequestWithHTTPMethod:kPOST URL:baseURL params:params];
}

- (id)accountUpdateProfileBanner:(UIImage *)banner {
    return [self accountUpdateProfileBanner:banner width:0 height:0 offset_left:0 offset_top:0];
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

    NSMutableDictionary *params = @{
                                    @"include_entities": (_includeEntities?@"true":@"false"),
                                    @"count": @(count).stringValue,
                                    @"q": q
                                    }.mutableCopy;
    
    if (untilDate) {
        NSDateFormatter *formatter = FHSTwitterEngine.dateFormatter.copy;
        formatter.dateFormat = @"YYYY-MM-DD";
        params[@"until"] = [formatter stringFromDate:untilDate];
    }
    
    switch (resultType) {
        case FHSTwitterEngineResultTypeMixed:
            params[@"result_type"] = @"mixed";
            break;
        case FHSTwitterEngineResultTypeRecent:
            params[@"result_type"] = @"recent";
            break;
        case FHSTwitterEngineResultTypePopular:
            params[@"result_type"] = @"popular";
            break;
        default:
            break;
    }
    
    if (maxID.length > 0) {
        params[@"max_id"] = maxID;
    }
    
    if (sinceID.length > 0) {
        params[@"since_id"] = sinceID;
    }
    
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:params];
}

- (id)createListWithName:(NSString *)name isPrivate:(BOOL)isPrivate description:(NSString *)description {
    
    if (name.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_lists_create];
    
    NSMutableDictionary *params = @{
                                    @"name": name,
                                    @"mode": isPrivate?@"private":@"public"
                                    }.mutableCopy;

    if (description.length > 0) {
        params[@"description"] = description;
    }
    
    return [self sendRequestWithHTTPMethod:kPOST URL:baseURL params:params];
}

- (id)getListWithID:(NSString *)listID {
    
    if (listID.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_lists_show];
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:@{ @"list_id": listID }];
}

- (id)getListSubscriptionsForUser:(NSString*)user isID:(BOOL)isID count:(int)count withCursor:(NSString *)cursor {

    if (user.length == 0) {
        return [NSError badRequestError];
    }

    if (count == 0) {
        return [NSError badRequestError];
    }

    if (count > 1000) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_lists_subscriptions];
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:@{
                                                                     (isID?@"user_id":@"screen_name"): user,
                                                                     @"count":@(count),
                                                                     @"cursor": cursor
                                                                     }];
}

- (id)updateListWithID:(NSString *)listID name:(NSString *)name {
    if (listID.length == 0) {
        return [NSError badRequestError];
    } else if (name.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_lists_update];
    return [self sendRequestWithHTTPMethod:kPOST URL:baseURL params:@{@"list_id": listID, @"name": name}];
}

- (id)updateListWithID:(NSString *)listID description:(NSString *)description {
    if (listID.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_lists_update];
    return [self sendRequestWithHTTPMethod:kPOST URL:baseURL params:@{
                                                                      @"list_id": listID,
                                                                      @"description": description?description:@""
                                                                      }];
}

- (id)updateListWithID:(NSString *)listID mode:(BOOL)isPrivate {
    if (listID.length == 0) {
        return [NSError badRequestError];
    }

    NSURL *baseURL = [NSURL URLWithString:url_lists_update];
    return [self sendRequestWithHTTPMethod:kPOST URL:baseURL params:@{
                                                                      @"list_id": listID,
                                                                      @"mode": isPrivate?@"private":@"public"
                                                                      }];
}

- (id)updateListWithID:(NSString *)listID name:(NSString *)name description:(NSString *)description mode:(BOOL)isPrivate {
    if (listID.length == 0) {
        return [NSError badRequestError];
    } else if (name.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_lists_update];
    return [self sendRequestWithHTTPMethod:kPOST URL:baseURL params:@{
                                                                      @"list_id": listID,
                                                                      @"name": name,
                                                                      @"description": description?description:@"",
                                                                      @"mode": isPrivate?@"private":@"public"
                                                                      }];
}

- (id)listUsersInListWithID:(NSString *)listID {
    if (listID.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_lists_members];
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:@{ @"list_id": listID }];
}

- (id)removeUsersFromListWithID:(NSString *)listID users:(NSArray *)users {
    if (users.count > 100 || users.count == 0) {
        return [NSError badRequestError];
    } else if (listID.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_lists_members_destroy_all];
    return [self sendRequestWithHTTPMethod:kPOST URL:baseURL params:@{@"screen_name": [users componentsJoinedByString:@","]}];
}

- (id)addUsersToListWithID:(NSString *)listID users:(NSArray *)users {
    if (users.count > 100 || users.count == 0) {
        return [NSError badRequestError];
    } else if (listID.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_lists_members_create_all];
    return [self sendRequestWithHTTPMethod:kPOST URL:baseURL params:@{@"screen_name": [users componentsJoinedByString:@","]}];
}

- (id)getMembersShow:(NSString*)list isListID:(BOOL)isListID user:(NSString*)user isUserID:(BOOL)isUserID owner:(NSString*)owner isOwnerID:(BOOL)isOwnerID skipStatus:(BOOL)skipStatus {
    if (list.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_lists_members_show];
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:@{
                                                                     (isListID?@"list_id":@"slug"): list,
                                                                     (isUserID?@"user_id":@"screen_name"): user,
                                                                     (isOwnerID?@"owner_id":@"owner_screen_name"): user,
                                                                     @"include_entities": (_includeEntities?@"true":@"false"),
                                                                     @"skip_status": (skipStatus?@"true":@"false"),
                                                                     }];
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
    } else if (listID.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_lists_statuses];
    NSMutableDictionary *params = @{
                                    @"count": @(count).stringValue,
                                    @"exclude_replies": (excludeReplies?@"true":@"false"),
                                    @"include_rts": (excludeRetweets?@"false":@"true"),
                                    @"list_id": listID
                                    }.mutableCopy;

    if (sinceID.length > 0) {
        params[@"since_id"] = sinceID;
    }
    
    if (maxID.length > 0) {
        params[@"max_id"] = maxID;
    }
    
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:params];
}

- (id)getListsForUser:(NSString *)user isID:(BOOL)isID {
    if (user.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_lists_list];
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:@{(isID?@"user_id":@"screen_name"): user}];
}

- (id)getRetweetsForTweet:(NSString *)identifier count:(int)count {
    if (count == 0) {
        return @[].mutableCopy;
    } else if (identifier.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.twitter.com/1.1/statuses/retweets/%@.json",identifier]];
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:@{@"count": @(count).stringValue}];
}

- (id)getRetweetedTimelineWithCount:(int)count {
    return [self getRetweetedTimelineWithCount:count sinceID:nil maxID:nil];
}

- (id)getRetweetedTimelineWithCount:(int)count sinceID:(NSString *)sinceID maxID:(NSString *)maxID {
    if (count == 0) {
        return @[].mutableCopy;
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_statuses_retweets_of_me];
    NSMutableDictionary *params = @{
                                    @"count": @(count).stringValue,
                                    @"exclude_replies": @"false",
                                    @"include_rts": @"true"
                                    }.mutableCopy;
    
    if (sinceID.length > 0) {
        params[@"since_id"] = sinceID;
    }
    
    if (maxID.length > 0) {
        params[@"max_id"] = maxID;
    }
    
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:params];
}

- (id)getMentionsTimelineWithCount:(int)count {
    return [self getMentionsTimelineWithCount:count sinceID:nil maxID:nil];
}

- (id)getMentionsTimelineWithCount:(int)count sinceID:(NSString *)sinceID maxID:(NSString *)maxID {
    if (count == 0) {
        return @[].mutableCopy;
    }

    NSURL *baseURL = [NSURL URLWithString:url_statuses_metions_timeline];
    
    NSMutableDictionary *params = @{
                                     @"count": @(count).stringValue,
                                     @"exclude_replies": @"false",
                                     @"include_rts": @"true"
                                     }.mutableCopy;
    
    if (sinceID.length > 0) {
        params[@"since_id"] = sinceID;
    }
    
    if (maxID.length > 0) {
        params[@"max_id"] = maxID;
    }
    
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:params];
}

- (id)postTweet:(NSString *)tweetString withImageData:(NSData *)theData {
    return [self postTweet:tweetString withImageData:theData inReplyTo:nil];
}

- (id)postTweet:(NSString *)tweetString withImageData:(NSData *)theData inReplyTo:(NSString *)irt {
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
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:3];
    params[@"status"] = tweetString;
    params[@"media[]"] = theData;
    
    if (irt.length > 0) {
        params[@"in_reply_to_status_id"] = irt;
    }
    return [self sendRequestWithHTTPMethod:kPOST URL:baseURL params:params];
}

- (id)postTweet:(NSString *)tweetString withImages:(NSArray *)images {
    return [self postTweet:tweetString withImages:images inReplyTo:nil];
}

- (id)postTweet:(NSString *)tweetString withImages:(NSArray *)images inReplyTo:(NSString *)irt {
    if (tweetString.length == 0) {
        return [NSError badRequestError];
    } else if (images.count == 0) {
        if (irt.length == 0) {
            return [self postTweet:tweetString];
        } else {
            return [self postTweet:tweetString inReplyTo:irt];
        }
    }
    
    __block NSError *mediaError = nil;
    
    NSMutableArray *mediaIds = [NSMutableArray array];

    NSURL *mediaUploadBaseURL = [NSURL URLWithString:url_media_upload];
    
    for (UIImage *image in images) {
        NSDictionary *params = @{
                                 @"media": @{
                                         @"type": @"file",
                                         @"filename": [NSString stringWithFormat:@"%@.png",[NSString fhs_UUID]],
                                         @"data": UIImagePNGRepresentation(image),
                                         @"mimetype": @"image/png"
                                         }
                                 };
        
        id res = [self sendRequestWithHTTPMethod:kPOST URL:mediaUploadBaseURL params:params];
        
        if ([res isKindOfClass:[NSError class]]) {
            mediaError = (NSError *)res;
            break;
        } else if ([res isKindOfClass:[NSDictionary class]]) {
            [mediaIds addObject:res[@"media_id_string"]];
        }
    }
    
    if (mediaError) return mediaError;
    
    NSURL *baseURL = [NSURL URLWithString:url_statuses_update];
    NSMutableDictionary *params = @{
                                    @"media_ids": [mediaIds componentsJoinedByString:@","],
                                    @"status": tweetString
                                    }.mutableCopy;
    if (irt.length > 0) params[@"in_reply_to_status_id"] = irt;
    
    NSLog(@"post tweet - params=%@",params);
    return [self sendRequestWithHTTPMethod:kPOST URL:baseURL params:params] ;
}

- (id)getoEmbedStatus:(NSString*)identifier {
    if (identifier.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseUrl = [NSURL URLWithString:url_statuses_oembed];
    return [self sendRequestWithHTTPMethod:kGET URL:baseUrl params:nil];
}

- (id)getRetweetersForTweet:(NSString *)identifier count:(int)count {
    if (identifier.length == 0) {
        return [NSError badRequestError];
    }
    
    if (count == 0) {
        return @[].mutableCopy;
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_statuses_retweeters];
    
    NSMutableDictionary *params = @{
                                    @"count": @(count).stringValue,
                                    @"id":identifier
                                    }.mutableCopy;
    
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:params];
}

- (id)destroyTweet:(NSString *)identifier {
    if (identifier.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_statuses_destroy];
    return [self sendRequestWithHTTPMethod:kPOST URL:baseURL params:@{@"id": identifier}];
}

- (id)getDetailsForTweet:(NSString *)identifier {
    if (identifier.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_statuses_show];
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:@{
                                                                     @"id": identifier,
                                                                     @"include_my_retweet": @"true"
                                                                     }];
}

- (id)retweet:(NSString *)identifier {
    if (identifier.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.twitter.com/1.1/statuses/retweet/%@.json",identifier]];
    return [self sendRequestWithHTTPMethod:kPOST URL:baseURL params:nil];
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
    NSMutableDictionary *params = @{
                                    @"count": @(count).stringValue,
                                    (isID?@"user_id":@"screen_name"): user,
                                    @"exclude_replies": @"false",
                                    @"include_rts": @"true"
                                    }.mutableCopy;
    
    if (sinceID.length > 0) {
        params[@"since_id"] = sinceID;
    }
    
    if (maxID.length > 0) {
        params[@"max_id"] = maxID;
    }
    
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:params];
}

- (id)authenticatedUserIsBlocking:(NSString *)user isID:(BOOL)isID {
    if (user.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_blocks_exists];
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:@{
                                                                     (isID?@"user_id":@"screen_name"): @"true",
                                                                     @"skip_status": @"true"
                                                                     }];
}

- (id)listBlockedUsers {
    NSURL *baseURL = [NSURL URLWithString:url_blocks_blocking];
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:@{@"skip_status": @"true"}];
}

- (id)listBlockedIDs {
    NSURL *baseURL = [NSURL URLWithString:url_blocks_blocking_ids];
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:@{@"stringify_ids": @"true"}];
}

- (id)getLanguages {
    NSURL *baseURL = [NSURL URLWithString:url_help_languages];
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:nil];
}

- (id)getConfiguration {
    NSURL *baseURL = [NSURL URLWithString:url_help_configuration];
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:nil];
}

- (id)reportUserAsSpam:(NSString *)user isID:(BOOL)isID {
    if (user.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_users_report_spam];
    return [self sendRequestWithHTTPMethod:kPOST URL:baseURL params:@{(isID?@"user_id":@"screen_name"): user}];
}

- (id)showDirectMessage:(NSString *)messageID {
    if (messageID.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_direct_messages_show];
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:@{@"id": messageID}];
}

- (id)sendDirectMessage:(NSString *)body toUser:(NSString *)user isID:(BOOL)isID {
    if (user.length == 0) {
        return [NSError badRequestError];
    }
    
    if (body.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_direct_messages_new];
    return [self sendRequestWithHTTPMethod:kPOST URL:baseURL params:@{
                                                                      @"text": [body fhs_truncatedToLength:140],
                                                                      (isID?@"user_id":@"screen_name"): user
                                                                      }];
}

- (id)getSentDirectMessages:(int)count {
    if (count == 0) {
        return @[].mutableCopy;
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_direct_messages_sent];
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:@{@"count": @(count).stringValue}];
}

- (id)deleteDirectMessage:(NSString *)messageID {
    if (messageID.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_direct_messages_destroy];
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:@{
                                                                     @"id": messageID,
                                                                     @"include_entities": (_includeEntities?@"true":@"false")
                                                                     }];
}

- (id)getDirectMessages:(int)count {
    if (count == 0) {
        return @[].mutableCopy;
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_direct_messages];
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:@{
                                                          @"count": @(count).stringValue,
                                                          @"skip_status": @"true"
                                                          }];
}

- (id)getPrivacyPolicy {
    NSURL *baseURL = [NSURL URLWithString:url_help_privacy];
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:nil];
}

- (id)getTermsOfService {
    NSURL *baseURL = [NSURL URLWithString:url_help_tos];
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:nil];
}

- (id)getNoRetweetIDs {
    NSURL *baseURL = [NSURL URLWithString:url_friendships_no_retweets_ids];
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:@{ @"stringify_ids":@"true" }];
}

- (id)enableRetweets:(BOOL)enableRTs andDeviceNotifs:(BOOL)devNotifs forUser:(NSString *)user isID:(BOOL)isID {
    
    if (user.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_friendships_update];
    return [self sendRequestWithHTTPMethod:kPOST URL:baseURL params:@{
                                                                      (isID?@"user_id":@"screen_name"): user,
                                                                      @"retweets": (enableRTs?@"true":@"false"),
                                                                      @"device": (devNotifs?@"true":@"false")
                                                                      }];
}

- (id)getFriendshipForSourceUser:(NSString *)sourceUser targetUser:(NSString*)targetUser isID:(BOOL)isID {
    
    if (sourceUser.length == 0) {
        return [NSError badRequestError];
    }

    if (targetUser.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_friendships_show];
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:@{
                                                                     (isID?@"source_id":@"source_screen_name"): sourceUser,
                                                                     (isID?@"target_id":@"target_screen_name"): targetUser,
                                                                     }];
    
}

- (id)getPendingOutgoingFollowers {
    NSURL *baseURL = [NSURL URLWithString:url_friendships_outgoing];
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:@{@"stringify_ids": @"true"}];
}

- (id)getPendingIncomingFollowers {
    NSURL *baseURL = [NSURL URLWithString:url_friendships_incoming];
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:@{ @"stringify_ids":@"true" }];
}

- (id)lookupFriendshipStatusForUsers:(NSArray *)users areIDs:(BOOL)areIDs {
    if (users.count == 0) {
        return @[].mutableCopy;
    }
    
    if (users.count > 100) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_friendships_lookup];
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:@{(areIDs?@"user_id":@"screen_name"): [users componentsJoinedByString:@","]}];
}

- (id)unfollowUser:(NSString *)user isID:(BOOL)isID {
    if (user.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_friendships_destroy];
    return [self sendRequestWithHTTPMethod:kPOST URL:baseURL params:@{(isID?@"user_id":@"screen_name"): user}];
}

- (id)followUser:(NSString *)user isID:(BOOL)isID {
    if (user.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_friendships_create];
    return [self sendRequestWithHTTPMethod:kPOST URL:baseURL params:@{(isID?@"user_id":@"screen_name"): user}];
}

- (id)verifyCredentials {
    NSURL *baseURL = [NSURL URLWithString:url_account_verify_credentials];
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:nil];
}

- (id)muteUser:(NSString *)user isID:(BOOL)isID {
    if (user.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_mutes_users_create];
    return [self sendRequestWithHTTPMethod:kPOST URL:baseURL params:@{(isID?@"user_id":@"screen_name"): user}];
}

- (id)unmuteUser:(NSString *)user isID:(BOOL)isID {
    if (user.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_mutes_users_destroy];
    return [self sendRequestWithHTTPMethod:kPOST URL:baseURL params:@{(isID?@"user_id":@"screen_name"): user}];
}

- (id)getMutedIds {
    NSURL *baseURL = [NSURL URLWithString:url_mutes_users_ids];
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:nil];
}

- (id)getMutedUsers {
    NSURL *baseURL = [NSURL URLWithString:url_mutes_users_list];
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:nil];
}

- (id)getProfileBanner:(NSString *)user isID:(BOOL)isID {
    NSURL *baseURL = [NSURL URLWithString:url_users_profile_banner];
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:@{(isID?@"user_id":@"screen_name"): user}];
}

- (id)getUserSuggestionsForSlug:(NSString*)slug lang:(NSString*)lang {
    if (slug.length == 0) {
        return [NSError badRequestError];
    }
    
    NSString *stringURL = [NSString stringWithFormat:@"%@/%@.json",url_users_suggestions_slug, slug];
    NSURL *baseURL = [NSURL URLWithString:stringURL];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:1];
    if (lang.length>0) {
        params[@"lang"] = lang;
    }
    
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:nil];
}

- (id)getUserSuggestionsForLanguage:(NSString*)lang {
    NSURL *baseURL = [NSURL URLWithString:url_users_suggestions];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:1];
    if (lang.length>0) {
        params[@"lang"] = lang;
    }
    
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:nil];
}

- (id)getUserSuggestionsStatusesForSlug:(NSString*)slug {
    if (slug.length == 0) {
        return [NSError badRequestError];
    }

    NSString *stringURL = [NSString stringWithFormat:@"%@/%@/members.json",url_users_suggestions_slug, slug];
    NSURL *baseURL = [NSURL URLWithString:stringURL];
    
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:nil];
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
    params[@"count"] = @(count).stringValue;
    params[(isID?@"user_id":@"screen_name")] = user;
    params[@"include_entities"] = _includeEntities?@"true":@"false";
    
    if (sinceID.length > 0) {
        params[@"since_id"] = sinceID;
    }
    
    if (maxID.length > 0) {
        params[@"max_id"] = maxID;
    }
    
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:params];
}

- (id)markTweet:(NSString *)tweetID asFavorite:(BOOL)flag {
    if (tweetID.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:flag?url_favorites_create:url_favorites_destroy];
    return [self sendRequestWithHTTPMethod:kPOST URL:baseURL params:@{@"id": tweetID}];
}

- (id)getRateLimitStatus {
    NSURL *baseURL = [NSURL URLWithString:url_application_rate_limit_status];
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:nil];
}

- (id)updateProfileColorsWithDictionary:(NSDictionary *)dictionary {
    
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
    
    return [self sendRequestWithHTTPMethod:kPOST URL:baseURL params:params];
}

- (id)setUseProfileBackgroundImage:(BOOL)shouldUseBGImg {
    NSURL *baseURL = [NSURL URLWithString:url_account_update_profile_background_image];
    return [self sendRequestWithHTTPMethod:kPOST URL:baseURL params:@{
                                                                      @"skip_status": @"true",
                                                                      @"use": (shouldUseBGImg?@"true":@"false")
                                                                      }];
}

- (id)setProfileBackgroundImageWithImageData:(NSData *)data tiled:(BOOL)isTiled {
    if (data.length == 0) {
        return [NSError badRequestError];
    }
    
    if (data.length >= 800000) {
        return [NSError imageTooLargeError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_account_update_profile_background_image];
    return [self sendRequestWithHTTPMethod:kPOST URL:baseURL params:@{@"skip_status":@"true", @"use":@"true", @"include_entities":_includeEntities?@"true":@"false", @"tiled":(isTiled?@"true":@"false"), @"image":[data base64Encode]}];
}

- (id)setProfileBackgroundImageWithImageAtPath:(NSString *)file tiled:(BOOL)isTiled {
    return [self setProfileBackgroundImageWithImageData:[NSData dataWithContentsOfFile:file] tiled:isTiled];
}

- (id)setProfileImageWithImageData:(NSData *)data {
    if (data.length == 0) {
        return [NSError badRequestError];
    }
    
    if (data.length >= 700000) {
        return [NSError imageTooLargeError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_account_update_profile_image];
    return [self sendRequestWithHTTPMethod:kPOST URL:baseURL params:@{
                                                                      @"skip_status":@"true",
                                                                      @"include_entities":(_includeEntities?@"true":@"false"),
                                                                      @"image":[data base64Encode]
                                                                      }];
}

- (id)setProfileImageWithImageAtPath:(NSString *)file {
    return [self setProfileImageWithImageData:[NSData dataWithContentsOfFile:file]];
}

- (id)getUserSettings {
    NSURL *baseURL = [NSURL URLWithString:url_account_settings];
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:nil];
}

- (id)updateUserProfileWithDictionary:(NSDictionary *)settings {
    
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
    
    return [self sendRequestWithHTTPMethod:kPOST URL:baseURL params:params];
}

- (id)updateSettingsWithDictionary:(NSDictionary *)settings {
    
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
    
    return [self sendRequestWithHTTPMethod:kPOST URL:baseURL params:params];
}

- (id)updateAccountDeliveryDeviceSMS:(BOOL)sms {
    NSURL *baseURL = [NSURL URLWithString:url_account_update_delivery_device];
    return [self sendRequestWithHTTPMethod:kPOST URL:baseURL params:@{@"device":sms?@"sms":@"none",
                                                                      @"include_entities": (_includeEntities?@"true":@"false"),
                                                                      }];
}

- (id)lookupUsers:(NSArray *)users areIDs:(BOOL)areIDs {
    if (users.count == 0) {
        return nil;
    }
    
    if (users.count > 100) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_users_lookup];
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:@{ (areIDs?@"user_id":@"screen_name"):[users componentsJoinedByString:@","] }];
}

- (id)getUser:(NSString*)user isID:(BOOL)isID {
    if (user.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_users_show];
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:@{ (isID?@"user_id":@"screen_name"):user,
                                                                      @"include_entities": (_includeEntities?@"true":@"false"),
                                                                      }];
}

- (id)unblock:(NSString *)username {
    if (username.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_blocks_destroy];
    return [self sendRequestWithHTTPMethod:kPOST URL:baseURL params:@{@"screen_name": username}];
}

- (id)block:(NSString *)username {
    if (username.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_blocks_create];
    return [self sendRequestWithHTTPMethod:kPOST URL:baseURL params:@{@"screen_name":username}];
}

- (id)testService {
    NSURL *baseURL = [NSURL URLWithString:url_help_test];
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:nil];
}

- (id)getHomeTimelineSinceID:(NSString *)sinceID count:(int)count {
    
    if (count == 0) {
        return nil;
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_statuses_home_timeline];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:2];
    params[@"count"] = @(count).stringValue;
    
    if (sinceID.length > 0) {
        params[@"since_id"] = sinceID;
    }
    
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:params];
}

- (id)postTweet:(NSString *)tweetString inReplyTo:(NSString *)inReplyToString {
    if (tweetString.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *baseURL = [NSURL URLWithString:url_statuses_update];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:2];
    params[@"status"] = tweetString;
    
    if (inReplyToString.length > 0) {
        params[@"in_reply_to_status_id"] = inReplyToString;
    }

    return [self sendRequestWithHTTPMethod:kPOST URL:baseURL params:params];
}

- (id)postTweet:(NSString *)tweetString {
    return [self postTweet:tweetString inReplyTo:nil];
}

- (id)getFollowersIDs {
    NSURL *baseURL = [NSURL URLWithString:url_followers_ids];
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:@{
                                                                     @"screen_name": _accessToken.username,
                                                                     @"stringify_ids": @"true"
                                                                     }];
}

- (id)getFriendsIDs {
    NSURL *baseURL = [NSURL URLWithString:url_friends_ids];
    return [self sendRequestWithHTTPMethod:kGET URL:baseURL params:@{
                                                                     @"screen_name": _accessToken.username,
                                                                     @"stringify_ids": @"true"
                                                                     }];
}

- (id)uploadImageToTwitPic:(UIImage *)image withMessage:(NSString *)message twitPicAPIKey:(NSString *)twitPicAPIKey {
    return [self uploadImageDataToTwitPic:UIImagePNGRepresentation(image) contentType:@"image/png" withMessage:message twitPicAPIKey:twitPicAPIKey];
}

- (id)uploadImageDataToTwitPic:(NSData *)imageData withMessage:(NSString *)message twitPicAPIKey:(NSString *)twitPicAPIKey {
    NSString *e = [imageData appropriateFileExtension];
    if (!e) return [NSError badRequestError];
    
    return [self uploadImageDataToTwitPic:imageData contentType:[NSString stringWithFormat:@"image/%@",e] withMessage:message twitPicAPIKey:twitPicAPIKey];
}

// Works by generating auth for twitter
// Then sending it to TwitPic
- (id)uploadImageDataToTwitPic:(NSData *)imageData contentType:(NSString *)contentType withMessage:(NSString *)message twitPicAPIKey:(NSString *)twitPicAPIKey {
    NSURL *verifyURL = [NSURL URLWithString:url_account_verify_credentials];
    NSMutableURLRequest *credVerifyReq = [NSMutableURLRequest requestWithURL:verifyURL];
    NSString *oauthHeaders = [credVerifyReq OAuthHeaderWithToken:_accessToken.key
                                                     tokenSecret:_accessToken.secret
                                                        verifier:nil
                                                     consumerKey:_consumerKey
                                                  consumerSecret:_consumerSecret
                                                           realm:@"http://api.twitter.com/".fhs_URLEncode];
    
    NSDictionary *params = @{
                             @"message": message,
                             @"key": twitPicAPIKey,
                             @"media": @{
                                     @"type": @"file",
                                     @"filename": [NSString stringWithFormat:@"%@.%@",NSString.fhs_UUID,imageData.appropriateFileExtension],
                                     @"data": imageData,
                                     @"mimetype": contentType
                                     }
                             };
    
    NSURL *url = [NSURL URLWithString:url_twitpic_upload];
    NSMutableURLRequest *req = [NSMutableURLRequest multipartPOSTRequestWithURL:url params:params];
    [req setValue:oauthHeaders forHTTPHeaderField:@"X-Verify-Credentials-Authorization"];
    [req setValue:url_account_verify_credentials forHTTPHeaderField:@"X-Auth-Service-Provider"];

    id res = [self sendRequest:req];
    
    if ([res isKindOfClass:[NSError class]]) return res;
    
    id parsed = [[NSJSONSerialization JSONObjectWithData:res options:NSJSONReadingMutableContainers error:nil]removeNull];
    
    NSError *error = [self checkError:parsed];
    if (error) return error;
    
    return parsed;
}

//
// Streaming API
//

// TODO: implement `replies`
- (void)streamUserMessagesWith:(NSArray *)with replies:(BOOL)replies keywords:(NSArray *)keywords locationBox:(NSArray *)locBox block:(StreamBlock)block {
    NSMutableDictionary *params = @{ @"stringify_friend_ids": @"true" }.mutableCopy;
    
    if (with.count > 0) {
        params[@"with"] = [with componentsJoinedByString:@","];
    }
    
    if (keywords.count > 0) {
        params[@"track"] = [FHSStream sanitizeTrackParameter:keywords];
    }
    
    if (locBox.count == 4) {
        params[@"locations"] = [locBox componentsJoinedByString:@","];
    }
    
    [self streamURL:[NSURL URLWithString:url_stream_user] httpMethod:kPOST params:params block:block]; // Twitter says it should be GET, but on further investigation of the docs, POST works too.
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
        params[@"track"] = [FHSStream sanitizeTrackParameter:keywords];
    }
    
    if (locBoxValid) {
        params[@"locations"] = [locBox componentsJoinedByString:@","];
    }
    
    [self streamURL:[NSURL URLWithString:url_stream_statuses_filter] httpMethod:kPOST params:params block:block];
}

- (void)streamSampleStatusesWithBlock:(StreamBlock)block {
    [self streamURL:[NSURL URLWithString:url_stream_statuses_sample] httpMethod:kGET params:nil block:block];
}

- (void)streamFirehoseWithBlock:(StreamBlock)block {
    [self streamURL:[NSURL URLWithString:url_stream_statuses_firehose] httpMethod:kGET params:nil block:block];
}


- (void)streamSiteMessagesFollow:(NSArray*)follow delimited:(BOOL)delimited stall_warnings:(BOOL)stall_warnings withFollowing:(BOOL)withFollowing replies:(BOOL)replies stringify_friend_ids:(BOOL)stringify_friend_ids block:(StreamBlock)block {
    BOOL usersValid = follow.count > 0 && follow.count < 5000;
    if (!usersValid) {
        NSError *error = [NSError errorWithDomain:FHSErrorDomain code:400 userInfo:@{NSLocalizedDescriptionKey: @"Bad Request: invalid parameters: GET site requires at least one user (follow)."}];
        block(error, NULL);
        return;
    }
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init]; //TODO: max capacity
    
    params[@"follow"] = [follow componentsJoinedByString:@","];
    
    if (delimited) {
        params[@"delimited"] = @"length";
    }
    
    if (stall_warnings) {
        params[@"stall_warnings"] = @"true";
    }
    
    params[@"with"] = withFollowing ? @"followings" : @"user";

    if (replies) {
        params[@"replies"] = @"all";
    }
    
    if (stringify_friend_ids) {
        params[@"stringify_friend_ids"] = @"true";
    }
    
    [self streamURL:[NSURL URLWithString:url_stream_site] httpMethod:kGET params:params block:block];
    
}


#pragma mark - Access Tokens

- (void)loadAccessToken {
    NSString *savedHttpBody = _loadAccessTokenBlock?_loadAccessTokenBlock():[[NSUserDefaults standardUserDefaults]objectForKey:@"SavedAccessHTTPBody"];
    self.accessToken = [FHSToken tokenWithHTTPResponseBody:savedHttpBody];
}

- (void)storeAccessToken:(NSString *)accessTokenZ {
    self.accessToken = [FHSToken tokenWithHTTPResponseBody:accessTokenZ];
    
    if (_storeAccessTokenBlock) {
        _storeAccessTokenBlock(accessTokenZ);
    } else {
        [[NSUserDefaults standardUserDefaults]setObject:accessTokenZ forKey:@"SavedAccessHTTPBody"];
    }
}

- (BOOL)isAuthorized {
    if (!_consumerKey && !_consumerSecret) {
        return NO;
    }
    
	if (_accessToken.key && _accessToken.secret) {
        if (_accessToken.key.length > 0 && _accessToken.secret.length > 0) {
            return YES;
        }
    }
    
	return NO;
}

- (void)clearAccessToken {
    [self storeAccessToken:@""];
	self.accessToken = nil;
}

#pragma mark - Consumer Keys

- (void)clearConsumer {
    self.consumerKey = nil;
    self.consumerSecret = nil;
}

- (void)clearConsumerIfNecessary {
    if (_shouldClearConsumer) {
        self.shouldClearConsumer = NO;
        [self clearConsumer];
    }
}

- (void)permanentlySetConsumerKey:(NSString *)consumerKey andSecret:(NSString *)consumerSecret {
    self.shouldClearConsumer = NO;
    self.consumerKey = consumerKey;
    self.consumerSecret = consumerSecret;
}

- (void)temporarilySetConsumerKey:(NSString *)consumerKey andSecret:(NSString *)consumerSecret {
    self.shouldClearConsumer = YES;
    self.consumerKey = consumerKey;
    self.consumerSecret = consumerSecret;
}

#pragma mark - Network Connectivity

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
            if (!(flags & kSCNetworkReachabilityFlagsReachable)) return NO;
            if (!(flags & kSCNetworkReachabilityFlagsConnectionRequired)) return YES;
            if ((flags & kSCNetworkReachabilityFlagsConnectionOnDemand) || (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic)) {
                if (!(flags & kSCNetworkReachabilityFlagsInterventionRequired)) return YES;
            }
            if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN) return YES;
        }
        
    }
    return NO;
}

#pragma mark - OAuth

- (id)getRequestToken {
    return [self getRequestTokenReverseAuth:NO];
}

- (id)getRequestTokenReverseAuth:(BOOL)reverseAuth {
    NSURL *url = [NSURL URLWithString:url_oauth_request_token];
    
    // Because the params are all strings, it will be x-www-form-urlencoded
    NSMutableURLRequest *r = [NSMutableURLRequest formURLEncodedPOSTRequestWithURL:url params:reverseAuth?@{@"x_auth_mode": @"reverse_auth"}:nil];
    [r signWithToken:nil tokenSecret:nil verifier:nil consumerKey:_consumerKey consumerSecret:_consumerSecret realm:nil];

    id res = [self sendRequest:r];
    
    if ([res isKindOfClass:[NSData class]]) {
        return [[NSString alloc]initWithData:(NSData *)res encoding:NSUTF8StringEncoding];
    }
    
    return res;
}

- (NSError *)finishAuthWithRequestToken:(FHSToken *)t {
    NSURL *url = [NSURL URLWithString:url_oauth_access_token];
    
    // This kind of BS has to happen because
    // this request has to be signed with a verifier
    NSMutableURLRequest *r = [NSMutableURLRequest defaultRequestWithURL:url];
    r.HTTPMethod = kPOST;
    [r signWithToken:t.key tokenSecret:t.secret verifier:t.verifier consumerKey:_consumerKey consumerSecret:_consumerKey realm:nil];

    id res = [self sendRequest:r];
    
    if ([res isKindOfClass:[NSError class]]) return res;
    
    NSString *response = [[NSString alloc]initWithData:(NSData *)res encoding:NSUTF8StringEncoding];
    
    if (response.length == 0) [NSError noDataError];
    
    [self storeAccessToken:response];
    
    return nil;
}

#pragma mark - XAuth

- (NSError *)authenticateWithUsername:(NSString *)username password:(NSString *)password {
    if (password.length == 0) return [NSError badRequestError];
    if (username.length == 0) return [NSError badRequestError];
    
    NSDictionary *params = @{
                             @"x_auth_mode": @"client_auth",
                             @"x_auth_username": username,
                             @"x_auth_password": password
                             };
    
    NSURL *url = [NSURL URLWithString:url_oauth_access_token];
    NSMutableURLRequest *r = [NSMutableURLRequest formURLEncodedPOSTRequestWithURL:url params:params];
    [r signWithToken:nil tokenSecret:nil verifier:nil consumerKey:_consumerKey consumerSecret:_consumerSecret realm:nil];

    id res = [self sendRequest:r];
    
    if ([res isKindOfClass:[NSError class]]) {
        return res;
    } else if ([res isKindOfClass:[NSData class]]) {
        NSString *httpBody = [[NSString alloc]initWithData:(NSData *)res encoding:NSUTF8StringEncoding];
        
        if (httpBody.length > 0) {
            [self storeAccessToken:httpBody];
        } else {
            return [NSError errorWithDomain:FHSErrorDomain code:422 userInfo:@{NSLocalizedDescriptionKey:@"The request was well-formed but was unable to be followed due to semantic errors.", @"request":r}];
        }
    }
    
    return nil;
}

@end
