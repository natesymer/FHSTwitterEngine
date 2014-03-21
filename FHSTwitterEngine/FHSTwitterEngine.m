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

@interface FHSTwitterEngine ()

@property (assign, nonatomic) BOOL shouldClearConsumer;

@end

@implementation FHSTwitterEngine

//
// Most of these methods are
// implementations of the
// Twitter API resources
//

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
    
    NSMutableDictionary *params = @{ @"include_entities":(_includeEntities?@"true":@"false"), @"count":@(count).stringValue, @"q":q }.mutableCopy;
    
    if (untilDate) {
        NSDateFormatter *formatter = FHSTwitterEngine.dateFormatter.copy;
        formatter.dateFormat = @"YYYY-MM-DD";
        params[@"until"] = [formatter stringFromDate:untilDate];
    }
    
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
    params[@"status"] = tweetString;
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
    return [self sendGETRequestForURL:baseURL andParams:@{ @"stringify_ids":@"true" }];
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
    return [self sendPOSTRequestForURL:baseURL andParams:@{@"text": [body fhs_truncatedToLength:140], (isID?@"user_id":@"screen_name"):user}];
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
    params[@"count"] = @(count).stringValue;
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
    params[@"count"] = @(count).stringValue;
    
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
    return [self sendGETRequestForURL:baseURL andParams:@{ @"screen_name": _accessToken.username, @"stringify_ids":@"true"}];
}

- (id)getFriendsIDs {
    NSURL *baseURL = [NSURL URLWithString:url_friends_ids];
    return [self sendGETRequestForURL:baseURL andParams:@{ @"screen_name": _accessToken.username, @"stringify_ids":@"true"}];
}

- (id)uploadImageToTwitPic:(UIImage *)image withMessage:(NSString *)message twitPicAPIKey:(NSString *)twitPicAPIKey {
    return [self uploadImageDataToTwitPic:UIImagePNGRepresentation(image) withMessage:message twitPicAPIKey:twitPicAPIKey];
}

// Works by generating auth for twitter
// Then sending it to TwitPic
- (id)uploadImageDataToTwitPic:(NSData *)imageData withMessage:(NSString *)message twitPicAPIKey:(NSString *)twitPicAPIKey {
    
    NSString *appropriateExtension = [imageData appropriateFileExtension];
    
    if (appropriateExtension == nil) {
        return [NSError badRequestError];
    }
    
    NSString *verifyURL = @"https://api.twitter.com/1.1/account/verify_credentials.json";
    
    NSString *oauthHeaders = [self generateOAuthHeaderForURL:[NSURL URLWithString:verifyURL] HTTPMethod:@"GET" withToken:_accessToken.key tokenSecret:_accessToken.secret verifier:nil realm:@"http://api.twitter.com/".fhs_URLEncode extraParameters:nil];
    
    NSURL *url = [NSURL URLWithString:@"http://api.twitpic.com/2/upload.json"];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"POST"];
    [req setValue:oauthHeaders forHTTPHeaderField:@"X-Verify-Credentials-Authorization"];
    [req setValue:verifyURL forHTTPHeaderField:@"X-Auth-Service-Provider"];

    NSString *boundary = [NSString fhs_UUID];
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
    [req addValue:contentType forHTTPHeaderField:@"Content-Type"];
    
    NSDictionary *params = @{
                             @"message": message,
                             @"key": twitPicAPIKey,
                             @"media": @{
                                          @"type": @"file",
                                          @"filename": [NSString stringWithFormat:@"%@.%@",[NSString fhs_UUID],appropriateExtension],
                                          @"data": imageData,
                                          @"mimetype": [NSString stringWithFormat:@"image/%@",appropriateExtension]
                                        }
                             };
    
    req.HTTPBody = [self POSTBodyWithParams:params boundary:boundary];
    [req setValue:@(req.HTTPBody.length).stringValue forHTTPHeaderField:@"Content-Length"];
    
    id res = [self sendRequest:req];
    
    if ([res isKindOfClass:[NSError class]]) {
        return res;
    }
    
    id parsed = [[NSJSONSerialization JSONObjectWithData:res options:NSJSONReadingMutableContainers error:nil]removeNull];
    
    NSError *error = [self checkError:parsed];
    
    if (error) {
        return error;
    }
    
    return parsed;
}

//
// Streaming API
//

// check out the streaming parameters here:
// https://dev.twitter.com/docs/streaming-apis/parameters

// This makes sure all track keywords are valid
- (NSString *)sanitizeTrackParameter:(NSArray *)keywords {
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
        params[@"track"] = [self sanitizeTrackParameter:keywords];
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
        params[@"track"] = [self sanitizeTrackParameter:keywords];
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
        return @[initialString];
    }
    
    int offset = 0;
    int remainder = fmod(array.count, 100);
    int numberOfStrings = (array.count-remainder)/100;
    
    NSMutableArray *reqStrs = [NSMutableArray array];
    
    for (int i = 1; i <= numberOfStrings; ++i) {
        NSString *ninetyNinththItem = (NSString *)array[(i*100)-1];
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
// Access Token Management
//

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

//
// Consumer key pair manament
//

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

//
// OAuth
//

- (id)getRequestToken {
    return [self getRequestTokenReverseAuth:NO];
}

- (id)getRequestTokenReverseAuth:(BOOL)reverseAuth {
    NSURL *url = [NSURL URLWithString:url_oauth_request_token];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0f];
    [request setHTTPMethod:@"POST"];
    [request setHTTPShouldHandleCookies:NO];
    
    [self signRequest:request withToken:nil tokenSecret:nil verifier:nil realm:nil extraParameters:reverseAuth?@{@"x_auth_mode": @"reverse_auth"}:nil];

    if (reverseAuth) {
        request.HTTPBody = [@"x_auth_mode=reverse_auth" dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    id retobj = [self sendRequest:request];
    
    if ([retobj isKindOfClass:[NSData class]]) {
        return [[NSString alloc]initWithData:(NSData *)retobj encoding:NSUTF8StringEncoding];
    }
    
    return retobj;
}

- (BOOL)finishAuthWithRequestToken:(FHSToken *)reqToken {
    NSURL *url = [NSURL URLWithString:url_oauth_access_token];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0f];
    [request setHTTPMethod:@"POST"];
    [request setHTTPShouldHandleCookies:NO];
    [self signRequest:request withToken:reqToken.key tokenSecret:reqToken.secret verifier:reqToken.verifier realm:nil extraParameters:nil];
    
    if (_shouldClearConsumer) {
        self.shouldClearConsumer = NO;
        [self clearConsumer];
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

- (NSError *)authenticateWithUsername:(NSString *)username password:(NSString *)password {
    if (password.length == 0) {
        return [NSError badRequestError];
    } else if (username.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *url = [NSURL URLWithString:url_oauth_access_token];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0f];
    [request setHTTPMethod:@"POST"];
    [request setHTTPShouldHandleCookies:NO];
    [self signRequest:request withToken:nil tokenSecret:nil verifier:nil realm:nil extraParameters:@{
                                                                                                     @"x_auth_mode": @"client_auth",
                                                                                                     @"x_auth_username": username,
                                                                                                     @"x_auth_password": password
                                                                                                     }];

    NSString *bodyString = [NSString stringWithFormat:@"x_auth_mode=client_auth&x_auth_username=%@&x_auth_password=%@",username,password];
    request.HTTPBody = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
    
    if (_shouldClearConsumer) {
        self.shouldClearConsumer = NO;
        [self clearConsumer];
    }
    
    id ret = [self sendRequest:request];
    
    if ([ret isKindOfClass:[NSError class]]) {
        return ret;
    } else if ([ret isKindOfClass:[NSData class]]) {
        NSString *httpBody = [[NSString alloc]initWithData:(NSData *)ret encoding:NSUTF8StringEncoding];
        
        if (httpBody.length > 0) {
            [self storeAccessToken:httpBody];
        } else {
            return [NSError errorWithDomain:FHSErrorDomain code:422 userInfo:@{NSLocalizedDescriptionKey:@"The request was well-formed but was unable to be followed due to semantic errors.", @"request":request}];
        }
    }
    
    return nil;
}

@end