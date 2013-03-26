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

#import "OAuthConsumer.h"
#import <QuartzCore/QuartzCore.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <ifaddrs.h>

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

@interface FHSTwitterEngineController : UIViewController <UIWebViewDelegate> 

@property (strong, nonatomic) UINavigationBar *navBar;
@property (strong, nonatomic) UIView *blockerView;
@property (strong, nonatomic) UIToolbar *pinCopyBar;

@property (strong, nonatomic) FHSTwitterEngine *engine;
@property (strong, nonatomic) UIWebView *theWebView;
@property (strong, nonatomic) OAToken *requestToken;

- (id)initWithEngine:(FHSTwitterEngine *)theEngine;
- (NSString *)locatePin;

- (void)showPinCopyPrompt;
- (void)removePinCopyPrompt;

@end

@interface FHSTwitterEngine ()

// id list generator - returns an array of id/username list strings
// used for users/lookup
- (NSArray *)generateRequestURLSForIDs:(NSArray *)idsArray;

// Login stuff
- (NSString *)getRequestTokenString;
- (NSString *)extractUserIDFromHTTPBody:(NSString *)body;
- (NSString *)extractUsernameFromHTTPBody:(NSString *)body;

// These are here to obfuscate them from prying eyes

@property (strong, nonatomic) OAConsumer *consumer;
@property (assign, nonatomic) BOOL shouldClearConsumer;

@end

@implementation NSString (FHSTwitterEngine)

- (NSString *)trimForTwitter {
    NSString *string = [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return (string.length > 140)?[string substringToIndex:140]:string;
}

- (BOOL)isNumeric {
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

@synthesize consumer, accessToken, loggedInUsername, loggedInID, delegate, includeEntities;

- (id)searchUsersWithQuery:(NSString *)q andCount:(int)count {
    
    if (q.length == 0) {
        return [NSError errorWithDomain:@"Bad Request: The query string was empty." code:403 userInfo:nil];
    }
    
    if (q.length > 1000) {
        q = [q substringToIndex:1000];
    }
    
    if (count == 0) {
        return [NSError errorWithDomain:@"Bad Request: The number of results you specified was 0." code:403 userInfo:nil];
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/users/search.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    OARequestParameter *include_entitiesP = [OARequestParameter requestParameterWithName:@"include_entities" value:self.includeEntities?@"true":@"false"];
    OARequestParameter *countP = [OARequestParameter requestParameterWithName:@"count" value:[NSString stringWithFormat:@"%d",count]];
    OARequestParameter *qP = [OARequestParameter requestParameterWithName:@"q" value:q];
    return [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:include_entitiesP, countP, qP, nil]];
}

- (id)searchTweetsWithQuery:(NSString *)q count:(int)count resultType:(FHSTwitterEngineResultType)resultType unil:(NSDate *)untilDate sinceID:(NSString *)sinceID maxID:(NSString *)maxID {
    
    if (q.length == 0) {
        return [NSError errorWithDomain:@"Bad Request: The query string was empty." code:403 userInfo:nil];
    }
    
    if (q.length > 1000) {
        q = [q substringToIndex:1000];
    }
    
    if (count == 0) {
        return [NSError errorWithDomain:@"Bad Request: The number of results you specified was 0." code:403 userInfo:nil];
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/search/tweets.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    OARequestParameter *include_entitiesP = [OARequestParameter requestParameterWithName:@"include_entities" value:self.includeEntities?@"true":@"false"];
    OARequestParameter *countP = [OARequestParameter requestParameterWithName:@"count" value:[NSString stringWithFormat:@"%d",count]];
    OARequestParameter *sinceIDP = [OARequestParameter requestParameterWithName:@"since_id" value:sinceID];
    OARequestParameter *maxIDP = [OARequestParameter requestParameterWithName:@"max_id" value:maxID];
    OARequestParameter *untilP = [OARequestParameter requestParameterWithName:@"until" value:nil];
    OARequestParameter *result_typeP = [OARequestParameter requestParameterWithName:@"result_type" value:nil];
    OARequestParameter *qP = [OARequestParameter requestParameterWithName:@"q" value:q];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    formatter.dateFormat = @"YYYY-MM-DD";
    NSString *untilString = [formatter stringFromDate:untilDate];
    untilP.value = untilString;

    if (resultType == FHSTwitterEngineResultTypeMixed) {
        result_typeP.value = @"mixed";
    } else if (resultType == FHSTwitterEngineResultTypeRecent) {
        result_typeP.value = @"recent";
    } else if (resultType == FHSTwitterEngineResultTypePopular) {
        result_typeP.value = @"popular";
    }
    
    NSMutableArray *params = [NSMutableArray array];
    
    if (maxID.length > 0) {
        [params addObject:maxIDP];
    }
    
    if (sinceID.length > 0) {
        [params addObject:sinceIDP];
    }
    
    [params addObject:countP];
    [params addObject:include_entitiesP];
    [params addObject:qP];
    
    return [self sendGETRequest:request withParameters:params];
}

- (NSError *)createListWithName:(NSString *)name isPrivate:(BOOL)isPrivate description:(NSString *)description {
    
    if (name.length == 0) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/lists/create.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *nameP = [OARequestParameter requestParameterWithName:@"name" value:name];
    OARequestParameter *descriptionP = [OARequestParameter requestParameterWithName:@"description" value:description];
    OARequestParameter *isPrivateP = [OARequestParameter requestParameterWithName:@"mode" value:nil];
    
    if (isPrivate) {
        isPrivateP.value = @"private";
    } else {
        isPrivateP.value = @"public";
    }
    
    NSMutableArray *params = [[NSMutableArray alloc]initWithObjects:nameP, isPrivateP, nil];
    
    if (description.length > 0 && description != nil) {
        [params addObject:descriptionP];
    }
    
    return [self sendPOSTRequest:request withParameters:params];
}

- (id)getListWithID:(NSString *)listID {
    
    if (listID.length == 0) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/lists/show.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *listIDP = [OARequestParameter requestParameterWithName:@"list_id" value:listID];
    
    return [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:listIDP, nil]];
}

- (NSError *)changeDescriptionOfListWithID:(NSString *)listID toDescription:(NSString *)newName {
    
    if (listID.length == 0) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    if (newName.length == 0 ) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/lists/update.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *listIDP = [OARequestParameter requestParameterWithName:@"list_id" value:listID];
    OARequestParameter *nameP = [OARequestParameter requestParameterWithName:@"description" value:newName];
    
    return [self sendPOSTRequest:request withParameters:[NSArray arrayWithObjects:listIDP, nameP, nil]];
}

- (NSError *)changeNameOfListWithID:(NSString *)listID toName:(NSString *)newName {
    
    if (listID.length == 0) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    if (newName.length == 0 ) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/lists/update.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *listIDP = [OARequestParameter requestParameterWithName:@"list_id" value:listID];
    OARequestParameter *nameP = [OARequestParameter requestParameterWithName:@"name" value:newName];

    return [self sendPOSTRequest:request withParameters:[NSArray arrayWithObjects:listIDP, nameP, nil]];
}

- (NSError *)setModeOfListWithID:(NSString *)listID toPrivate:(BOOL)isPrivate {
    
    if (listID.length == 0) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/lists/update.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *listIDP = [OARequestParameter requestParameterWithName:@"list_id" value:listID];
    OARequestParameter *isPrivateP = [OARequestParameter requestParameterWithName:@"mode" value:nil];
    
    if (isPrivate) {
        isPrivateP.value = @"private";
    } else {
        isPrivateP.value = @"public";
    }
    
    return [self sendPOSTRequest:request withParameters:[NSArray arrayWithObjects:listIDP, isPrivateP, nil]];
}

- (id)getListsThatUserIsMemberOf:(NSString *)user {
    
    if (user.length == 0) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/lists/memberships.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *listIDP = [OARequestParameter requestParameterWithName:@"screen_name" value:user];
    
    return [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:listIDP, nil]];
}

- (id)listUsersInListWithID:(NSString *)listID {
    
    if (listID.length == 0) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/lists/members.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];

    OARequestParameter *listIDP = [OARequestParameter requestParameterWithName:@"list_id" value:listID];
    
    return [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:listIDP, nil]];
}

- (NSError *)removeUsersFromListWithID:(NSString *)listID users:(NSArray *)users {
    
    if (listID.length == 0) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    if (users.count >= 99) {
        return [NSError errorWithDomain:@"The request you are trying to make is missing parameters." code:13372 userInfo:nil];
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/lists/members/destroy_all.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    NSArray *usersListA = [self generateRequestURLSForIDs:users];
    
    return [self sendPOSTRequest:request withParameters:[NSArray arrayWithObjects:[OARequestParameter requestParameterWithName:@"screen_name" value:[usersListA firstObjectCommonWithArray:usersListA]], nil]];
}

- (NSError *)addUsersToListWithID:(NSString *)listID users:(NSArray *)users {
    
    if (listID.length == 0) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    if (users.count >= 99) {
        return [NSError errorWithDomain:@"The request you are trying to make is missing parameters." code:13372 userInfo:nil];
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/lists/members/create_all.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];

    NSArray *usersListA = [self generateRequestURLSForIDs:users];
    
    return [self sendPOSTRequest:request withParameters:[NSArray arrayWithObjects:[OARequestParameter requestParameterWithName:@"screen_name" value:[usersListA firstObjectCommonWithArray:usersListA]], nil]];
}

- (id)getTimelineForListWithID:(NSString *)listID count:(int)count {
    return [self getTimelineForListWithID:listID count:count sinceID:nil maxID:nil];
}

- (id)getTimelineForListWithID:(NSString *)listID count:(int)count sinceID:(NSString *)sinceID maxID:(NSString *)maxID {
    
    if (listID.length == 0) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/lists/statuses.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    NSMutableArray *params = [NSMutableArray array];
    
    OARequestParameter *countP = [OARequestParameter requestParameterWithName:@"count" value:[NSString stringWithFormat:@"%d",count]];
    OARequestParameter *excludeRepliesP = [OARequestParameter requestParameterWithName:@"exclude_replies" value:@"false"];
    OARequestParameter *includeRTsP = [OARequestParameter requestParameterWithName:@"include_rts" value:@"true"];
    OARequestParameter *listIDP = [OARequestParameter requestParameterWithName:@"list_id" value:listID];
    
    [params addObject:countP];
    [params addObject:excludeRepliesP];
    [params addObject:includeRTsP];
    [params addObject:listIDP];
    
    if (sinceID.length > 0) {
        OARequestParameter *sinceIDP = [OARequestParameter requestParameterWithName:@"since_id" value:sinceID];
        [params addObject:sinceIDP];
    }
    
    if (maxID.length > 0) {
        OARequestParameter *maxIDP = [OARequestParameter requestParameterWithName:@"max_id" value:maxID];
        [params addObject:maxIDP];
    }
    
    return [self sendGETRequest:request withParameters:params];
}

- (id)getListsForUser:(NSString *)user isID:(BOOL)isID {
    
    if (user.length == 0) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/lists/list.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    OARequestParameter *userP = [OARequestParameter requestParameterWithName:isID?@"user_id":@"screen_name" value:user];
    return [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:userP, nil]];
}

- (id)getRetweetsForTweet:(NSString *)identifier count:(int)count {
    
    if (identifier.length == 0) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.twitter.com/1.1/statuses/retweets/%@.json",identifier]];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    OARequestParameter *identifierP = [OARequestParameter requestParameterWithName:@"count" value:[NSString stringWithFormat:@"%d",count]];
    return [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:identifierP, nil]];
}

- (id)getRetweetedTimelineWithCount:(int)count {
    return [self getRetweetedTimelineWithCount:count sinceID:nil maxID:nil];
}

- (id)getRetweetedTimelineWithCount:(int)count sinceID:(NSString *)sinceID maxID:(NSString *)maxID {
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/retweets_of_me.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    NSMutableArray *params = [NSMutableArray array];
    OARequestParameter *countP = [OARequestParameter requestParameterWithName:@"count" value:[NSString stringWithFormat:@"%d",count]];
    OARequestParameter *excludeRepliesP = [OARequestParameter requestParameterWithName:@"exclude_replies" value:@"false"];
    OARequestParameter *includeRTsP = [OARequestParameter requestParameterWithName:@"include_rts" value:@"true"];
    
    [params addObject:countP];
    [params addObject:excludeRepliesP];
    [params addObject:includeRTsP];
    
    if (sinceID.length > 0) {
        OARequestParameter *sinceIDP = [OARequestParameter requestParameterWithName:@"since_id" value:sinceID];
        [params addObject:sinceIDP];
    }
    
    if (maxID.length > 0) {
        OARequestParameter *maxIDP = [OARequestParameter requestParameterWithName:@"max_id" value:maxID];
        [params addObject:maxIDP];
    }
    
    return [self sendGETRequest:request withParameters:params];
}

- (id)getMentionsTimelineWithCount:(int)count {
    return [self getMentionsTimelineWithCount:count sinceID:nil maxID:nil];
}

- (id)getMentionsTimelineWithCount:(int)count sinceID:(NSString *)sinceID maxID:(NSString *)maxID {

    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/mentions_timeline.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    NSMutableArray *params = [NSMutableArray array];
    
    OARequestParameter *countP = [OARequestParameter requestParameterWithName:@"count" value:[NSString stringWithFormat:@"%d",count]];
    OARequestParameter *excludeRepliesP = [OARequestParameter requestParameterWithName:@"exclude_replies" value:@"false"];
    OARequestParameter *includeRTsP = [OARequestParameter requestParameterWithName:@"include_rts" value:@"true"];

    [params addObject:countP];
    [params addObject:excludeRepliesP];
    [params addObject:includeRTsP];
    
    if (sinceID.length > 0) {
        OARequestParameter *sinceIDP = [OARequestParameter requestParameterWithName:@"since_id" value:sinceID];
        [params addObject:sinceIDP];
    }
    
    if (maxID.length > 0) {
        OARequestParameter *maxIDP = [OARequestParameter requestParameterWithName:@"max_id" value:maxID];
        [params addObject:maxIDP];
    }
    
    return [self sendGETRequest:request withParameters:params];
}

- (NSError *)postTweet:(NSString *)tweetString withImageData:(NSData *)theData {
    return [self postTweet:tweetString withImageData:theData inReplyTo:nil];
}

- (NSError *)postTweet:(NSString *)tweetString withImageData:(NSData *)theData inReplyTo:(NSString *)irt {
    
    if (tweetString.length == 0) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    if (theData == nil) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/update_with_media.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    NSMutableArray *params = [NSMutableArray array];
    OARequestParameter *statusP = [OARequestParameter requestParameterWithName:@"status" value:tweetString];
    OARequestParameter *mediaP = [OARequestParameter requestParameterWithName:@"media_data[]" value:[theData base64EncodingWithLineLength:0]];
    OARequestParameter *inReplyToP = [OARequestParameter requestParameterWithName:@"in_reply_to_status_id" value:irt];
    
    [params addObject:statusP];
    [params addObject:mediaP];
    
    if (irt.length > 0) {
        [params addObject:inReplyToP];
    }
    
    return [self sendPOSTRequest:request withParameters:params];
}

- (NSError *)destoryTweet:(NSString *)identifier {
    
    if (identifier.length == 0) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/destroy.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    OARequestParameter *identifierP = [OARequestParameter requestParameterWithName:@"id" value:identifier];
    return [self sendPOSTRequest:request withParameters:[NSArray arrayWithObjects:identifierP, nil]];
}

- (id)getDetailsForTweet:(NSString *)identifier {
    
    if (identifier.length == 0) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/show.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    OARequestParameter *identifierP = [OARequestParameter requestParameterWithName:@"id" value:identifier];
    OARequestParameter *includeMyRetweet = [OARequestParameter requestParameterWithName:@"include_my_retweet" value:@"true"];
    return [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:includeMyRetweet, identifierP, nil]];
}

- (id)oembedTweet:(NSString *)identifier maxWidth:(float)maxWidth alignmentMode:(FHSTwitterEngineAlignMode)alignmentMode {
    
    if (identifier.length == 0) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/oembed.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    NSString *language = [[NSLocale preferredLanguages]objectAtIndex:0];
    NSString *alignment = [[NSArray arrayWithObjects:@"left", @"right", @"center", @"none", nil]objectAtIndex:alignmentMode];
    
    OARequestParameter *identifierP = [OARequestParameter requestParameterWithName:@"id" value:identifier];
    OARequestParameter *maxWidthP = [OARequestParameter requestParameterWithName:@"maxwidth" value:[NSString stringWithFormat:@"%f",maxWidth]];
    OARequestParameter *languageP= [OARequestParameter requestParameterWithName:@"lang" value:language];
    OARequestParameter *alignmentP = [OARequestParameter requestParameterWithName:@"align" value:alignment];
    
    return [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:identifierP, maxWidthP, languageP,alignmentP, nil]];
}

- (NSError *)retweet:(NSString *)identifier {
    
    if (identifier.length == 0) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.twitter.com/1.1/statuses/retweet/%@.json",identifier]];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    return [self sendPOSTRequest:request withParameters:nil];
}

- (id)getTimelineForUser:(NSString *)user isID:(BOOL)isID count:(int)count {
    return [self getTimelineForUser:user isID:isID count:count sinceID:nil maxID:nil];
}

- (id)getTimelineForUser:(NSString *)user isID:(BOOL)isID count:(int)count sinceID:(NSString *)sinceID maxID:(NSString *)maxID {
    
    if (user.length == 0) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/user_timeline.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    NSMutableArray *params = [NSMutableArray array];
    
    OARequestParameter *countP = [OARequestParameter requestParameterWithName:@"count" value:[NSString stringWithFormat:@"%d",count]];
    OARequestParameter *userP = [OARequestParameter requestParameterWithName:isID?@"user_id":@"screen_name" value:user];
    OARequestParameter *excludeRepliesP = [OARequestParameter requestParameterWithName:@"exclude_replies" value:@"false"];
    OARequestParameter *includeRTsP = [OARequestParameter requestParameterWithName:@"include_rts" value:@"true"];

    [params addObject:countP];
    [params addObject:userP];
    [params addObject:excludeRepliesP];
    [params addObject:includeRTsP];
    
    if (sinceID.length > 0) {
        OARequestParameter *sinceIDP = [OARequestParameter requestParameterWithName:@"since_id" value:sinceID];
        [params addObject:sinceIDP];
    }
    
    if (maxID.length > 0) {
        OARequestParameter *maxIDP = [OARequestParameter requestParameterWithName:@"max_id" value:maxID];
        [params addObject:maxIDP];
    }
    
    return [self sendGETRequest:request withParameters:params];
}

- (id)getWeeklyTrends {
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/trends/weekly.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    return [self sendGETRequest:request withParameters:nil];
}

- (id)getDailyTrends {
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/trends/daily.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    return [self sendGETRequest:request withParameters:nil];
}

- (id)getProfileImageForUsername:(NSString *)username andSize:(FHSTwitterEngineImageSize)size {
    
    if (username.length == 0) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/users/show.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    OARequestParameter *usernameP = [OARequestParameter requestParameterWithName:@"screen_name" value:username];
    
    NSArray *params = [NSArray arrayWithObjects:usernameP, nil];
    
    id userShowReturn = [self sendGETRequest:request withParameters:params];
    
    if ([userShowReturn isKindOfClass:[NSError class]]) {
        return [NSError errorWithDomain:[(NSError *)userShowReturn domain] code:[(NSError *)userShowReturn code] userInfo:[NSDictionary dictionaryWithObject:request forKey:@"request"]];
    } else if ([userShowReturn isKindOfClass:[NSDictionary class]]) {
            NSString *finalURL = nil;
            NSString *rawProfileURL = [userShowReturn objectForKey:@"profile_image_url"];
            
            if (size == 0) { // mini
                NSString *ext = [rawProfileURL pathExtension];
                finalURL = [[[[rawProfileURL stringByDeletingPathExtension]stringByReplacingOccurrencesOfString:@"_normal" withString:@""] stringByAppendingString:@"_mini."]stringByAppendingString:ext];
            } else if (size == 1) { // normal
                finalURL = rawProfileURL;
            } else if (size == 2) { // bigger
                NSString *ext = [rawProfileURL pathExtension];
                finalURL = [[[[rawProfileURL stringByDeletingPathExtension]stringByReplacingOccurrencesOfString:@"_normal" withString:@""] stringByAppendingString:@"_bigger."]stringByAppendingString:ext];
            } else if (size == 3) { // original
                finalURL = [[rawProfileURL stringByDeletingPathExtension]stringByReplacingOccurrencesOfString:@"_normal" withString:@""];
            }
            
            NSURLRequest *imageRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:finalURL]];
            
            NSHTTPURLResponse *response = nil;
            NSError *error = nil;
            
            NSData *imageData = [NSURLConnection sendSynchronousRequest:imageRequest returningResponse:&response error:&error];
            
            if (response == nil || error != nil) {
                return error;
            }
            
            if (response.statusCode >= 304) {
                return error;
            }
            
            return [UIImage imageWithData:imageData];
    }
    
    return [NSError errorWithDomain:@"Bad Request: the request you attempted to make messed up royally." code:400 userInfo:nil];
}

- (id)authenticatedUserIsBlocking:(NSString *)user isID:(BOOL)isID {
    
    if (user.length == 0) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/blocks/exists.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *userP = [OARequestParameter requestParameterWithName:isID?@"user_id":@"screen_name" value:user];
    OARequestParameter *skipstatusP = [OARequestParameter requestParameterWithName:@"skip_status" value:@"true"];
    
    id obj = [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:skipstatusP, userP, nil]];
    
    if (!obj) {
        return [NSError errorWithDomain:[(NSError *)obj domain] code:[(NSError *)obj code] userInfo:[NSDictionary dictionaryWithObject:request forKey:@"request"]];
    }
    
    if ([obj isKindOfClass:[NSError class]]) {
        return [NSError errorWithDomain:[(NSError *)obj domain] code:[(NSError *)obj code] userInfo:[NSDictionary dictionaryWithObject:request forKey:@"request"]];
    }
    
    if ([obj isKindOfClass:[NSDictionary class]]) {
        if ([[obj objectForKey:@"error"]isEqualToString:@"You are not blocking this user."]) {
            return @"NO";
        } else {
            return @"YES";
        }
    }
    
    return [NSError errorWithDomain:@"Bad Request: the request you attempted to make messed up royally." code:400 userInfo:nil];
}

- (id)listBlockedUsers {
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/blocks/blocking.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    OARequestParameter *skipstatusP = [OARequestParameter requestParameterWithName:@"skip_status" value:@"true"];
    return [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:skipstatusP, nil]];
}

- (id)listBlockedIDs {
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/blocks/blocking/ids.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    OARequestParameter *stringifyIDsP = [OARequestParameter requestParameterWithName:@"stringify_ids" value:@"true"];
    
    id object = [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:stringifyIDsP, nil]];
    
    if ([object isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = (NSDictionary *)object;
        if ([dict.allKeys containsObject:@"ids"]) {
            object = [dict objectForKey:@"ids"];
        }
    }
    return object;
}

- (id)getLanguages {
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/help/languages.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    return [self sendGETRequest:request withParameters:nil];
}

- (id)getConfiguration {
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/help/configuration.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    return [self sendGETRequest:request withParameters:nil];
}

- (NSError *)reportUserAsSpam:(NSString *)user isID:(BOOL)isID {
    
    if (user.length == 0) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/report_spam.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    OARequestParameter *userP = [OARequestParameter requestParameterWithName:isID?@"user_id":@"screen_name" value:user];
    return [self sendPOSTRequest:request withParameters:[NSArray arrayWithObjects:userP, nil]];
}

- (id)showDirectMessage:(NSString *)messageID {
    
    if (messageID.length == 0) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.twitter.com/1.1/direct_messages/show/%@.json",messageID]];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    return [self sendGETRequest:request withParameters:nil];
}

- (NSError *)sendDirectMessage:(NSString *)body toUser:(NSString *)user isID:(BOOL)isID {
    
    if (user.length == 0) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    if (body.length == 0) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    body = [body trimForTwitter];
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/direct_messages/new.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *bodyP = [OARequestParameter requestParameterWithName:@"text" value:body];
    OARequestParameter *userP = [OARequestParameter requestParameterWithName:isID?@"user_id":@"screen_name" value:user];
    return [self sendPOSTRequest:request withParameters:[NSArray arrayWithObjects:userP, bodyP, nil]];
}

- (id)getSentDirectMessages:(int)count {
    
    if (count == 0) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/direct_messages/sent.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *countP = [OARequestParameter requestParameterWithName:@"count" value:[NSString stringWithFormat:@"%d",count]];
    return [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:countP, nil]];
}

- (NSError *)deleteDirectMessage:(NSString *)messageID {
    
    if (messageID.length == 0) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.twitter.com/1.1/direct_messages/destroy/%@.json",messageID]];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    return [self sendPOSTRequest:request withParameters:nil];
}

- (id)getDirectMessages:(int)count {
    
    if (count == 0) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/direct_messages.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *countP = [OARequestParameter requestParameterWithName:@"count" value:[NSString stringWithFormat:@"%d",count]];
    OARequestParameter *skipStatusP = [OARequestParameter requestParameterWithName:@"skip_status" value:@"true"];
    return [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:countP, skipStatusP, nil]];
}

- (id)getPrivacyPolicy {
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/legal/privacy.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    id object = [self sendGETRequest:request withParameters:nil];
    
    if ([object isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = (NSDictionary *)object;
        if ([dict.allKeys containsObject:@"privacy"]) {
            object = [dict objectForKey:@"privacy"];
        }
    }
    return object;
}

- (id)getTermsOfService {
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/legal/tos.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    id object = [self sendGETRequest:request withParameters:nil];
    
    if ([object isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = (NSDictionary *)object;
        if ([dict.allKeys containsObject:@"tos"]) {
            object = [dict objectForKey:@"tos"];
        }
    }
    return object;
}

- (id)getNoRetweetIDs {
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/friendships/no_retweet_ids.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *stringifyIDsP = [OARequestParameter requestParameterWithName:@"stringify_ids" value:@"true"];
    
    return [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:stringifyIDsP, nil]];
}

- (NSError *)enableRetweets:(BOOL)enableRTs andDeviceNotifs:(BOOL)devNotifs forUser:(NSString *)user isID:(BOOL)isID {
    
    if (user.length == 0) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/friendships/update.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *userP = [OARequestParameter requestParameterWithName:isID?@"user_id":@"screen_name" value:user];
    OARequestParameter *retweetsP = [OARequestParameter requestParameterWithName:@"retweets" value:enableRTs?@"true":@"false"];
    OARequestParameter *deviceP = [OARequestParameter requestParameterWithName:@"device" value:devNotifs?@"true":@"false"];
    return [self sendPOSTRequest:request withParameters:[NSArray arrayWithObjects:userP, retweetsP, deviceP, nil]];
}

- (id)getPendingOutgoingFollowers {
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/friendships/outgoing.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *stringifyIDsP = [OARequestParameter requestParameterWithName:@"stringify_ids" value:@"true"];
    
    id object = [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:stringifyIDsP, nil]];
    
    if ([object isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = (NSDictionary *)object;
        if ([dict.allKeys containsObject:@"ids"]) {
            object = [dict objectForKey:@"ids"];
        }
    }
    return object;
}

- (id)getPendingIncomingFollowers {
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/friendships/incoming.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *stringifyIDsP = [OARequestParameter requestParameterWithName:@"stringify_ids" value:@"true"];
    
    id object = [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:stringifyIDsP, nil]];
    
    if ([object isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = (NSDictionary *)object;
        if ([dict.allKeys containsObject:@"ids"]) {
            object = [dict objectForKey:@"ids"];
        }
    }
    return object;
}

- (id)lookupFriends:(NSArray *)users areIDs:(BOOL)areIDs {
    
    if (users.count == 0) {
        return nil;
    }
    
    NSMutableArray *returnedDictionaries = [NSMutableArray array];
    NSArray *reqStrings = [self generateRequestURLSForIDs:users];
    
    for (NSString *reqString in reqStrings) {
        NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/friendships/lookup.json"];
        
        OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
        
        OARequestParameter *userP = [OARequestParameter requestParameterWithName:areIDs?@"user_id":@"screen_name" value:reqString];
        
        id retObj = [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:userP, nil]];
        
        if ([retObj isKindOfClass:[NSArray class]]) {
            [returnedDictionaries addObjectsFromArray:(NSArray *)retObj];
        }
    }
    return returnedDictionaries;
}

- (NSError *)unfollowUser:(NSString *)user isID:(BOOL)isID {
    
    if (user.length == 0) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/friendships/destroy.json"];
    
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *userP = [OARequestParameter requestParameterWithName:isID?@"user_id":@"screen_name" value:user];
    return [self sendPOSTRequest:request withParameters:[NSArray arrayWithObjects:userP, nil]];
}

- (NSError *)followUser:(NSString *)user isID:(BOOL)isID {
    
    if (user.length == 0) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/friendships/create.json"];
    
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *userP = [OARequestParameter requestParameterWithName:isID?@"user_id":@"screen_name" value:user];
    return [self sendPOSTRequest:request withParameters:[NSArray arrayWithObjects:userP, nil]];
}

- (id)user:(NSString *)user followsUser:(NSString *)userTwo areUsernames:(BOOL)areUsernames {
    
    if (user.length == 0) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    if (userTwo.length == 0) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/friendships/exists.json"]; // fix this
    
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *userP = [OARequestParameter requestParameterWithName:areUsernames?@"screen_name_a":@"user_id_a" value:user];
    OARequestParameter *userTwoP = [OARequestParameter requestParameterWithName:areUsernames?@"screen_name_b":@"user_id_b" value:userTwo];
    return [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:userP, userTwoP, nil]];
}

- (id)verifyCredentials {
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/account/verify_credentials.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    return [self sendGETRequest:request withParameters:nil];
}

- (id)getFavoritesForUser:(NSString *)user isID:(BOOL)isID andCount:(int)count {
    
    if (count == 0) {
        return nil;
    }
    
    if (user.length == 0) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/favorites.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *countP = [OARequestParameter requestParameterWithName:@"count" value:[NSString stringWithFormat:@"%d",count]];
    OARequestParameter *userP = [OARequestParameter requestParameterWithName:isID?@"user_id":@"screen_name" value:user];
    return [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:countP, userP, nil]];
}

- (NSError *)markTweet:(NSString *)tweetID asFavorite:(BOOL)flag {
    
    if (tweetID.length == 0) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.twitter.com/1.1/favorites/%@.json",flag?@"create":@"destroy"]];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    OARequestParameter *idP = [OARequestParameter requestParameterWithName:@"id" value:tweetID];
    return [self sendPOSTRequest:request withParameters:[NSArray arrayWithObjects:idP, nil]];
}

- (id)getRateLimitStatus {
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/application/rate_limit_status.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    return [self sendGETRequest:request withParameters:nil];
}

- (NSError *)updateProfileColorsWithDictionary:(NSDictionary *)dictionary {
    
    // profile_background_color - hex color
    // profile_link_color - hex color
    // profile_sidebar_border_color - hex color
    // profile_sidebar_fill_color - hex color
    // profile_text_color - hex color
    
    NSString *profile_background_color = nil;
    NSString *profile_link_color = nil;
    NSString *profile_sidebar_border_color = nil;
    NSString *profile_sidebar_fill_color = nil;
    NSString *profile_text_color = nil;
    
    
    if (!dictionary) {
        profile_background_color = @"C0DEED";
        profile_link_color = @"0084B4";
        profile_sidebar_border_color = @"C0DEED";
        profile_sidebar_fill_color = @"DDEEF6";
        profile_text_color = @"333333";
    } else {
        profile_background_color = [dictionary objectForKey:@"profile_background_color"];
        profile_link_color = [dictionary objectForKey:@"profile_link_color"];
        profile_sidebar_border_color = [dictionary objectForKey:@"profile_sidebar_border_color"];
        profile_sidebar_fill_color = [dictionary objectForKey:@"profile_sidebar_fill_color"];
        profile_text_color = [dictionary objectForKey:@"profile_text_color"];
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/account/update_profile_colors.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    NSMutableArray *params = [NSMutableArray array];
    
    OARequestParameter *profile_background_colorP = [OARequestParameter requestParameterWithName:@"profile_background_color" value:profile_background_color];
    OARequestParameter *profile_link_colorP = [OARequestParameter requestParameterWithName:@"profile_link_color" value:profile_link_color];
    OARequestParameter *profile_sidebar_border_colorP = [OARequestParameter requestParameterWithName:@"profile_sidebar_border_color" value:profile_sidebar_border_color];
    OARequestParameter *profile_sidebar_fill_colorP = [OARequestParameter requestParameterWithName:@"profile_sidebar_fill_color" value:profile_sidebar_fill_color];
    OARequestParameter *profile_text_colorP = [OARequestParameter requestParameterWithName:@"rofile_text_color" value:profile_text_color];
    
    if (profile_background_color.length > 0) {
        [params addObject:profile_background_colorP];
    }
    
    if (profile_link_color.length > 0) {
        [params addObject:profile_link_colorP];
    }
    
    if (profile_sidebar_border_color.length > 0) {
        [params addObject:profile_sidebar_border_colorP];
    }
    
    if (profile_sidebar_fill_color.length > 0) {
        [params addObject:profile_sidebar_fill_colorP];
    }
    
    if (profile_text_color.length > 0) {
        [params addObject:profile_text_colorP];
    }
    
    OARequestParameter *skipStatus = [OARequestParameter requestParameterWithName:@"skip_status" value:@"true"];
    [params addObject:skipStatus];
    
    return [self sendPOSTRequest:request withParameters:params];
}

- (NSError *)setUseProfileBackgroundImage:(BOOL)shouldUseProfileBackgroundImage {
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/account/update_profile_background_image.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *skipStatus = [OARequestParameter requestParameterWithName:@"skip_status" value:@"true"];
    OARequestParameter *useImage = [OARequestParameter requestParameterWithName:@"profile_use_background_image" value:shouldUseProfileBackgroundImage?@"true":@"false"];
    return [self sendPOSTRequest:request withParameters:[NSArray arrayWithObjects:skipStatus, useImage, nil]];
}

- (NSError *)setProfileBackgroundImageWithImageAtPath:(NSString *)file tiled:(BOOL)flag {
    
    if (file.length == 0) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    if (![[NSFileManager defaultManager]fileExistsAtPath:file]) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    if ([[[NSFileManager defaultManager]attributesOfFileSystemForPath:file error:nil]fileSize] >= 800000) {
        return [NSError errorWithDomain:@"The image you are trying to upload is too large." code:422 userInfo:nil];
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/account/update_profile_background_image.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *tiled = [OARequestParameter requestParameterWithName:@"tiled" value:flag?@"true":@"false"];
    OARequestParameter *skipStatus = [OARequestParameter requestParameterWithName:@"skip_status" value:@"true"];
    OARequestParameter *useImage = [OARequestParameter requestParameterWithName:@"profile_use_background_image" value:@"true"];
    OARequestParameter *image = [OARequestParameter requestParameterWithName:@"image" value:[[NSData dataWithContentsOfFile:file]base64EncodingWithLineLength:0]];

    return [self sendPOSTRequest:request withParameters:[NSArray arrayWithObjects:tiled, skipStatus, useImage, image, nil]];
}

- (NSError *)setProfileImageWithImageAtPath:(NSString *)file {
    
    if (file.length == 0) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/account/update_profile_image.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    if ([[[NSFileManager defaultManager]attributesOfFileSystemForPath:file error:nil]fileSize] >= 700000) {
        return [NSError errorWithDomain:@"The image you are trying to upload is too large." code:422 userInfo:nil];
    }
    
    OARequestParameter *image = [OARequestParameter requestParameterWithName:@"image" value:[[NSData dataWithContentsOfFile:file]base64EncodingWithLineLength:0]];
    OARequestParameter *skipStatus = [OARequestParameter requestParameterWithName:@"skip_status" value:@"true"];
    
    return [self sendPOSTRequest:request withParameters:[NSArray arrayWithObjects:image, skipStatus, nil]];
}

- (id)getTotals {
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/account/totals.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    return [self sendGETRequest:request withParameters:nil];
}

- (id)getUserSettings {
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/account/settings.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    return [self sendGETRequest:request withParameters:nil];
}

- (NSError *)updateUserProfileWithDictionary:(NSDictionary *)settings {
    
    if (!settings) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    // all of the values are just non-normalized strings. They appear:
    
    //   setting   - length in characters
    // name        -        20
    // url         -        100
    // location    -        30
    // description -        160
    
    NSString *name = [settings objectForKey:@"name"];
    NSString *url = [settings objectForKey:@"url"];
    NSString *location = [settings objectForKey:@"location"];
    NSString *description = [settings objectForKey:@"description"];
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/account/update_profile.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    NSMutableArray *params = [NSMutableArray array];
    
    OARequestParameter *nameP = [OARequestParameter requestParameterWithName:@"name" value:name];
    OARequestParameter *urlP = [OARequestParameter requestParameterWithName:@"url" value:url];
    OARequestParameter *locationP = [OARequestParameter requestParameterWithName:@"location" value:location];
    OARequestParameter *descriptionP = [OARequestParameter requestParameterWithName:@"description" value:description];
    OARequestParameter *skipStatus = [OARequestParameter requestParameterWithName:@"skip_status" value:@"true"];
    
    if (name.length > 0) {
        [params addObject:nameP];
    }
    
    if (url.length > 0) {
        [params addObject:urlP];
    }
    
    if (location.length > 0) {
        [params addObject:locationP];
    }
    
    if (description.length > 0) {
        [params addObject:descriptionP];
    }
    
    [params addObject:skipStatus];
    
    return [self sendPOSTRequest:request withParameters:params];
}

- (NSError *)updateSettingsWithDictionary:(NSDictionary *)settings {
    
    if (!settings) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    // Dictionary with keys:
    // All strings... You could have guessed that.
    // sleep_time_enabled - true/false
    // start_sleep_time - UTC time
    // end_sleep_time - UTC time
    // time_zone - Europe/Copenhagen, Pacific/Tongatapu
    // lang - en, it, es
    
    NSString *sleep_time_enabled = [settings objectForKey:@"sleep_time_enabled"];
    NSString *start_sleep_time = [settings objectForKey:@"start_sleep_time"];
    NSString *end_sleep_time = [settings objectForKey:@"end_sleep_time"];
    NSString *time_zone = [settings objectForKey:@"time_zone"];
    NSString *lang = [settings objectForKey:@"lang"];
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/account/settings.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *sleep_time_enabledP = [OARequestParameter requestParameterWithName:@"sleep_time_enabled" value:sleep_time_enabled];
    OARequestParameter *start_sleep_timeP = [OARequestParameter requestParameterWithName:@"start_sleep_time" value:start_sleep_time];
    OARequestParameter *end_sleep_timeP = [OARequestParameter requestParameterWithName:@"end_sleep_time" value:end_sleep_time];
    OARequestParameter *time_zoneP = [OARequestParameter requestParameterWithName:@"time_zone" value:time_zone];
    OARequestParameter *langP = [OARequestParameter requestParameterWithName:@"lang" value:lang];
    
    NSMutableArray *params = [NSMutableArray array];
    
    if (sleep_time_enabled.length > 0) {
        [params addObject:sleep_time_enabledP];
    }
    
    if (start_sleep_time.length > 0) {
        [params addObject:start_sleep_timeP];
    }
    
    if (end_sleep_time.length > 0) {
        [params addObject:end_sleep_timeP];
    }
    
    if (time_zone.length > 0) {
        [params addObject:time_zoneP];
    }
    
    if (lang.length > 0) {
        [params addObject:langP];
    }
    
    return [self sendPOSTRequest:request withParameters:params];
}

- (NSError *)disableNotificationsForID:(NSString *)identifier {
    
    if (identifier.length == 0) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/notifications/leave.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *usernameParam = [OARequestParameter requestParameterWithName:@"user_id" value:identifier];
    
    return [self sendPOSTRequest:request withParameters:[NSArray arrayWithObjects:usernameParam, nil]];
}

- (NSError *)disableNotificationsForUsername:(NSString *)username {
    
    if (username.length == 0) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/notifications/leave.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *usernameParam = [OARequestParameter requestParameterWithName:@"screen_name" value:username];
    
    return [self sendPOSTRequest:request withParameters:[NSArray arrayWithObjects:usernameParam, nil]];
}

- (NSError *)enableNotificationsForID:(NSString *)identifier {
    
    if (identifier.length == 0) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/notifications/follow.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *usernameParam = [OARequestParameter requestParameterWithName:@"user_id" value:identifier];
    
    return [self sendPOSTRequest:request withParameters:[NSArray arrayWithObjects:usernameParam, nil]];
}

- (NSError *)enableNotificationsForUsername:(NSString *)username {
    
    if (username.length == 0) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/notifications/follow.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *usernameParam = [OARequestParameter requestParameterWithName:@"screen_name" value:username];
    
    return [self sendPOSTRequest:request withParameters:[NSArray arrayWithObjects:usernameParam, nil]];
}

- (id)getUserInformationForUsers:(NSArray *)users areUsers:(BOOL)flag {
    
    if (users.count == 0) {
        return nil;
    }
    
    if (users.count > 99) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make has invalid parameters." code:400 userInfo:nil];
    }
    
    NSString *userString = nil;
    
    if (users.count > 1) {
        
        for (NSString *string in users) {
            
            NSString *commaOrNot = @",";
            
            if ([(NSString *)[users lastObject]isEqualToString:string]) {
                commaOrNot = @"";
            }
            
            [userString stringByAppendingFormat:@"%@%@",string,commaOrNot];
        }
        
    } else {
        userString = [users objectAtIndex:0];
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/users/lookup.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    NSString *paramName = nil;
    
    if (flag) {
        paramName = @"screen_name";
    } else {
        paramName = @"user_id";
    }
    
    OARequestParameter *usernames = [OARequestParameter requestParameterWithName:paramName value:userString];
    
    return [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:usernames, nil]];
}

- (NSError *)unblock:(NSString *)username {
    
    if (username.length == 0) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/blocks/destroy.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *usernameP = [OARequestParameter requestParameterWithName:@"screen_name" value:username];
    
    return [self sendPOSTRequest:request withParameters:[NSArray arrayWithObjects:usernameP, nil]];
}

- (NSError *)block:(NSString *)username {
    
    if (username.length == 0) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/blocks/create.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *usernameP = [OARequestParameter requestParameterWithName:@"screen_name" value:username];
    
    return [self sendPOSTRequest:request withParameters:[NSArray arrayWithObjects:usernameP, nil]];
}

- (BOOL)testService {
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/help/test.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    id retValue = [self sendGETRequest:request withParameters:nil];
    
    if([retValue isKindOfClass:[NSString class]]) {
        NSString *finalString = (NSString *)retValue;
        if ([finalString isEqualToString:@"ok"]) {
            return YES;
        }
    }
    
    return NO;
}

- (id)getHomeTimelineSinceID:(NSString *)sinceID count:(int)count {
    
    if (count == 0) {
        return nil;
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/home_timeline.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *since_id = [OARequestParameter requestParameterWithName:@"since_id" value:sinceID];
    OARequestParameter *countParam = [OARequestParameter requestParameterWithName:@"count" value:[NSString stringWithFormat:@"%d", count]];
    
    NSMutableArray *params = [NSMutableArray arrayWithObjects:countParam, nil];
    
    if (sinceID.length > 0) {
        [params addObject:since_id];
    }
    
    return [self sendGETRequest:request withParameters:params];
}

- (id)initWithConsumerKey:(NSString *)consumerKey andSecret:(NSString *)consumerSecret {
    self = [super init];
    if (self) {
        self.consumer = [[OAConsumer alloc]initWithKey:consumerKey secret:consumerSecret];
    }
    return self;
}

- (NSArray *)generateRequestURLSForIDs:(NSArray *)idsArray {
    
    int count = idsArray.count;
    
    NSMutableArray *reqStrs = [NSMutableArray array];
    
    int remainder = fmod(count, 99);
    
    int numberOfStrings = (count-remainder)/99;
    
    for (int i = 0; i < numberOfStrings; i++) {
        NSString *reqString = @"";
        
        for (int ii = 0; ii < 99; ii++) {
            
            // i*99 -> the number of 99's completed
            // ii -> the number indicating the progress into the current 99
            int lol = (i*99)+ii;
            
            // handle getting the correct string
            NSString *currentID = [[[idsArray objectAtIndex:lol]stringValue]stringByAppendingString:@","];
            
            // append the string
            reqString = [reqString stringByAppendingString:currentID];
        }
        
        BOOL isLastCharAComma = ([[reqString substringFromIndex:reqString.length-1]isEqualToString:@","]);
        
        if (isLastCharAComma) {
            reqString = [reqString substringToIndex:reqString.length-1];
        }
        
        [reqStrs addObject:reqString];
    }
    
    if (numberOfStrings*99 < count) {
        NSString *reqString = @"";
        
        for (int iii = 0; iii < remainder; iii++) {
            
            // handle getting the correct string
            NSString *currentID = [[idsArray objectAtIndex:(numberOfStrings*99)+iii]stringByAppendingString:@","];
            
            // append the string
            reqString = [reqString stringByAppendingString:currentID];
        }
        
        BOOL isLastCharAComma = ([[reqString substringFromIndex:reqString.length-1]isEqualToString:@","]);
        
        if (isLastCharAComma) {
            reqString = [reqString substringToIndex:reqString.length-1];
        }
        
        [reqStrs addObject:reqString];
    }
    
    return reqStrs;
}

- (NSArray *)getFollowers {
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/followers/ids.json"];
    
    OARequestParameter *param = [OARequestParameter requestParameterWithName:@"screen_name" value:self.loggedInUsername];
    OARequestParameter *stringify_ids = [OARequestParameter requestParameterWithName:@"stringify_ids" value:@"true"];
    
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    id returnedValue = [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:param, stringify_ids, nil]];
    
    NSMutableArray *identifiersFromRequest = [NSMutableArray array];
    
    if ([returnedValue isKindOfClass:[NSDictionary class]]) {
        id idsRAW = [(NSDictionary *)returnedValue objectForKey:@"ids"];
        if ([idsRAW isKindOfClass:[NSArray class]]) {
            [identifiersFromRequest addObjectsFromArray:(NSArray *)idsRAW];
        }
    } else if ([returnedValue isKindOfClass:[NSError class]]) {
        return nil;
    }
    
    if (identifiersFromRequest.count == 0) {
        return nil;
    }
    
    NSMutableArray *usernames = [NSMutableArray array];
    
    NSArray *usernameListStrings = [self generateRequestURLSForIDs:identifiersFromRequest];
    
    for (NSString *idListString in usernameListStrings) {
        baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/users/lookup.json"];
        
        OARequestParameter *iden = [OARequestParameter requestParameterWithName:@"user_id" value:idListString];
        OARequestParameter *includeEntitiesP = [OARequestParameter requestParameterWithName:@"include_entities" value:self.includeEntities?@"true":@"false"];
        
        OAMutableURLRequest *requestTwo = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
        
        id parsed = [self sendGETRequest:requestTwo withParameters:[NSArray arrayWithObjects:iden, includeEntitiesP, nil]];
        
        if ([parsed isKindOfClass:[NSDictionary class]]) {
            [usernames addObject:[parsed objectForKey:@"screen_name"]];
        } else if ([parsed isKindOfClass:[NSArray class]]) {
            for (NSDictionary *dict in (NSArray *)parsed) {
                [usernames addObject:[dict objectForKey:@"screen_name"]];
            }
        }
    }
    
    return [usernames sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

- (NSArray *)getFriends {
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/friends/ids.json"];
    
    OARequestParameter *param = [OARequestParameter requestParameterWithName:@"screen_name" value:self.loggedInUsername];
    OARequestParameter *stringify_ids = [OARequestParameter requestParameterWithName:@"stringify_ids" value:@"true"];
    
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    id returnedValue = [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:param, stringify_ids, nil]];
    
    NSMutableArray *identifiersFromRequest = [NSMutableArray array];
    
    if ([returnedValue isKindOfClass:[NSDictionary class]]) {
        id idsRAW = [(NSDictionary *)returnedValue objectForKey:@"ids"];
        if ([idsRAW isKindOfClass:[NSArray class]]) {
            [identifiersFromRequest addObjectsFromArray:(NSArray *)idsRAW];
        }
    } else if ([returnedValue isKindOfClass:[NSError class]]) {
        return nil;
    }
    
    if (identifiersFromRequest.count == 0) {
        return nil;
    }
    
    NSMutableArray *usernames = [NSMutableArray array];
    
    NSArray *usernameListStrings = [self generateRequestURLSForIDs:identifiersFromRequest];
    
    for (NSString *idListString in usernameListStrings) {
        baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/users/lookup.json"];
        
        OARequestParameter *iden = [OARequestParameter requestParameterWithName:@"user_id" value:idListString];
        OARequestParameter *includeEntitiesP = [OARequestParameter requestParameterWithName:@"include_entities" value:self.includeEntities?@"true":@"false"];
        
        OAMutableURLRequest *requestTwo = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
        
        id parsed = [self sendGETRequest:requestTwo withParameters:[NSArray arrayWithObjects:iden, includeEntitiesP, nil]];
        
        if ([parsed isKindOfClass:[NSDictionary class]]) {
            [usernames addObject:[parsed objectForKey:@"screen_name"]];
        } else if ([parsed isKindOfClass:[NSArray class]]) {
            for (NSDictionary *dict in (NSArray *)parsed) {
                [usernames addObject:[dict objectForKey:@"screen_name"]];
            }
        }
    }
    
    return [usernames sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

- (NSError *)postTweet:(NSString *)tweetString inReplyTo:(NSString *)inReplyToString {

    if (tweetString.length == 0) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    tweetString = [tweetString trimForTwitter];
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/update.json"];
    
    OARequestParameter *status = [OARequestParameter requestParameterWithName:@"status" value:tweetString];
    OARequestParameter *inReplyToID = [OARequestParameter requestParameterWithName:@"in_reply_to_status_id" value:inReplyToString];
    
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    NSMutableArray *params = [NSMutableArray array];
    
    [params addObject:status];
    
    if (inReplyToString.length > 0) {
        [params addObject:inReplyToID];
    }
    
    // PARAMETERS WERE MALFORMED due to setting the params before the HTTP method... lulz
    
    return [self sendPOSTRequest:request withParameters:params];
}

- (NSError *)postTweet:(NSString *)tweetString {
    return [self postTweet:tweetString inReplyTo:nil];
}


//
// XAuth
//

- (NSError *)getXAuthAccessTokenForUsername:(NSString *)username password:(NSString *)password {
    
    if (password.length == 0) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    if (username.length == 0) {
        return [NSError errorWithDomain:@"Bad Request: The request you are trying to make is missing parameters." code:400 userInfo:nil];
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"];
    
	OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:nil realm:nil signatureProvider:nil];
	
	[request setHTTPMethod:@"POST"];
    [request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    [request setTimeoutInterval:25];
	
	[request setParameters:[NSArray arrayWithObjects:[OARequestParameter requestParameterWithName:@"x_auth_mode" value:@"client_auth"], [OARequestParameter requestParameterWithName:@"x_auth_username" value:username], [OARequestParameter requestParameterWithName:@"x_auth_password" value:password], nil]];
    
    [request prepare];
    
    if (self.shouldClearConsumer) {
        self.shouldClearConsumer = NO;
        self.consumer = nil;
    }
    
    NSError *error = nil;
    NSHTTPURLResponse *response = nil;
    
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    if (response == nil || responseData == nil || error != nil) {
        return [NSError errorWithDomain:error.domain code:error.code userInfo:[NSDictionary dictionaryWithObject:request forKey:@"request"]];
    }
    
    if (response.statusCode >= 304) {
        return [NSError errorWithDomain:[self getSarcasticErrorDescriptionForErrorCode:response.statusCode] code:response.statusCode userInfo:[NSDictionary dictionaryWithObject:request forKey:@"request"]];
    }

    NSString *httpBody = [[NSString alloc]initWithData:responseData encoding:NSUTF8StringEncoding];
    
    if (httpBody.length > 0) {
        [self storeAccessToken:httpBody];
        return nil;
    } else {
        [self storeAccessToken:nil];
        return [NSError errorWithDomain:@"Twitter messed up and did not return anything for some reason. Please try again later." code:500 userInfo:nil];
    }
    return 0;
}

//
// sendRequest:
//

- (NSError *)sendPOSTRequest:(OAMutableURLRequest *)request withParameters:(NSArray *)params {
    
    if (![self isAuthorized]) {
        return [NSError errorWithDomain:@"You are not authorized via OAuth" code:401 userInfo:[NSDictionary dictionaryWithObject:request forKey:@"request"]];
    }
    
    [request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    [request setTimeoutInterval:25];
    
    [request setHTTPMethod:@"POST"];
    [request setParameters:params];
    [request prepare];
    
    if (self.shouldClearConsumer) {
        self.shouldClearConsumer = NO;
        self.consumer = nil;
    }
    
    NSError *error = nil;
    NSHTTPURLResponse *response = nil;
    
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    id parsedJSONResponse = removeNull([NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:nil]);
    
    if (response == nil || responseData == nil || error != nil) {
        return [NSError errorWithDomain:error.domain code:error.code userInfo:[NSDictionary dictionaryWithObject:request forKey:@"request"]];
    }
    
    if (response.statusCode >= 304) {
        return [NSError errorWithDomain:[self getSarcasticErrorDescriptionForErrorCode:response.statusCode] code:response.statusCode userInfo:[NSDictionary dictionaryWithObject:request forKey:@"request"]];
    }
    
    if ([parsedJSONResponse isKindOfClass:[NSDictionary class]]) {
        NSString *errorMessage = [parsedJSONResponse objectForKey:@"error"];
        NSArray *errorArray = [parsedJSONResponse objectForKey:@"errors"];
        if (errorMessage.length > 0) {
            return [NSError errorWithDomain:errorMessage code:[[parsedJSONResponse objectForKey:@"code"]intValue] userInfo:[NSDictionary dictionaryWithObject:request forKey:@"request"]];
        } else if (errorArray.count > 0) {
            if (errorArray.count > 1) {
                return [NSError errorWithDomain:@"Multiple Errors" code:1337 userInfo:[NSDictionary dictionaryWithObject:request forKey:@"request"]];
            } else {
                NSDictionary *theError = [errorArray objectAtIndex:0];
                return [NSError errorWithDomain:[theError objectForKey:@"message"] code:[[theError objectForKey:@"code"]integerValue] userInfo:[NSDictionary dictionaryWithObject:request forKey:@"request"]];
            }
        }
    }
    
    return nil;
}

- (id)sendGETRequest:(OAMutableURLRequest *)request withParameters:(NSArray *)params {
    
    if (![self isAuthorized]) {
        return [NSError errorWithDomain:@"You are not authorized with Twitter. Please sign in." code:401 userInfo:[NSDictionary dictionaryWithObject:request forKey:@"request"]];
    }
    
    [request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    [request setTimeoutInterval:25];
    
    [request setHTTPMethod:@"GET"];
    [request setParameters:params];
    [request prepare];
    
    if (self.shouldClearConsumer) {
        self.shouldClearConsumer = NO;
        self.consumer = nil;
    }
    
    NSError *error = nil;
    NSHTTPURLResponse *response = nil;
    
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    id parsedJSONResponse = removeNull([NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:nil]);

    if (response == nil || responseData == nil || error != nil) {
        return [NSError errorWithDomain:error.domain code:error.code userInfo:[NSDictionary dictionaryWithObject:request forKey:@"request"]];
    }
    
    if (response.statusCode >= 304) {
        return [NSError errorWithDomain:[self getSarcasticErrorDescriptionForErrorCode:response.statusCode] code:response.statusCode userInfo:[NSDictionary dictionaryWithObject:request forKey:@"request"]];
    }
    
    if ([parsedJSONResponse isKindOfClass:[NSDictionary class]]) {
        NSString *errorMessage = [parsedJSONResponse objectForKey:@"error"];
        NSArray *errorArray = [parsedJSONResponse objectForKey:@"errors"];
        if (errorMessage.length > 0) {
            return [NSError errorWithDomain:errorMessage code:[[parsedJSONResponse objectForKey:@"code"]intValue] userInfo:[NSDictionary dictionaryWithObject:request forKey:@"request"]];
        } else if (errorArray.count > 0) {
            if (errorArray.count > 1) {
                return [NSError errorWithDomain:@"Multiple Errors" code:1337 userInfo:[NSDictionary dictionaryWithObject:request forKey:@"request"]];
            } else {
                NSDictionary *theError = [errorArray objectAtIndex:0];
                return [NSError errorWithDomain:[theError objectForKey:@"message"] code:[[theError objectForKey:@"code"]integerValue] userInfo:[NSDictionary dictionaryWithObject:request forKey:@"request"]];
            }
        }
    }
    
    return parsedJSONResponse;
}



//
// OAuth
//

/*
 This section of code is pretty crufty. I know. It works well enough 
 and is not accessed by the user. Move along. You didn't see anything.
 */

- (NSString *)getRequestTokenString {
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/oauth/request_token"];
    
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:url consumer:self.consumer token:nil realm:nil signatureProvider:nil];
    
    [request setHTTPMethod:@"POST"];
    [request prepare];
    
    NSError *error = nil;
    NSHTTPURLResponse *response = nil;
    
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    if (response == nil || responseData == nil || error != nil) {
        return nil;
    }
    
    if (response.statusCode >= 304) {
        return nil;
    }
    
    NSString *responseBody = [[NSString alloc]initWithData:responseData encoding:NSUTF8StringEncoding];
    
    return responseBody;
}

- (int)finishAuthWithPin:(NSString *)pin andRequestToken:(OAToken *)reqToken {
    if (pin.length != 7) {
        return 1;
    }
    
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"];
    
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:url consumer:self.consumer token:reqToken realm:nil signatureProvider:nil];
    [request setHTTPMethod:@"POST"];
    [request prepare];
    
    if (self.shouldClearConsumer) {
        self.shouldClearConsumer = NO;
        self.consumer = nil;
    }
    
    NSError *error = nil;
    NSHTTPURLResponse *response = nil;
    
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    if (response == nil || responseData == nil || error != nil) {
        return 1;
    }
    
    if (response.statusCode >= 304) {
        return 1;
    }

    NSString *responseBody = [[NSString alloc]initWithData:responseData encoding:NSUTF8StringEncoding];
    
    if (responseBody.length == 0) {
        return 1;
    }
    
    [self storeAccessToken:responseBody];
    
    return 0;
}

//
// Access Token Management
//

- (void)loadAccessToken {
    
    NSString *savedHttpBody = nil;
    
    if ([self.delegate respondsToSelector:@selector(loadAccessToken)]) {
        savedHttpBody = [self.delegate loadAccessToken];
    } else {
        savedHttpBody = [[NSUserDefaults standardUserDefaults]objectForKey:@"SavedAccessHTTPBody"];
    }
    
    self.accessToken = [[OAToken alloc]initWithHTTPResponseBody:savedHttpBody];
    self.loggedInUsername = [self extractUsernameFromHTTPBody:savedHttpBody];
    self.loggedInID = [self extractUserIDFromHTTPBody:savedHttpBody];
}

- (void)storeAccessToken:(NSString *)accessTokenZ {
    self.accessToken = [[OAToken alloc]initWithHTTPResponseBody:accessTokenZ];
    self.loggedInUsername = [self extractUsernameFromHTTPBody:accessTokenZ];
    self.loggedInID = [self extractUserIDFromHTTPBody:accessTokenZ];
    
    if ([self.delegate respondsToSelector:@selector(storeAccessToken:)]) {
        [self.delegate storeAccessToken:accessTokenZ];
    } else {
        [[NSUserDefaults standardUserDefaults]setObject:accessTokenZ forKey:@"SavedAccessHTTPBody"];
    }
}

- (NSString *)extractUsernameFromHTTPBody:(NSString *)body {
	if (!body) {
        return nil;
    }
	
	NSArray *tuples = [body componentsSeparatedByString:@"&"];
	if (tuples.count < 1) {
        return nil;
    }
	
	for (NSString *tuple in tuples) {
		NSArray *keyValueArray = [tuple componentsSeparatedByString:@"="];
		
		if (keyValueArray.count == 2) {
			NSString *key = [keyValueArray objectAtIndex: 0];
			NSString *value = [keyValueArray objectAtIndex: 1];
			
			if ([key isEqualToString:@"screen_name"]) {
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

- (NSString *)extractUserIDFromHTTPBody:(NSString *)body {
    if (!body) {
        return nil;
    }
	
	NSArray *tuples = [body componentsSeparatedByString:@"&"];
	if (tuples.count < 1) {
        return nil;
    }
	
	for (NSString *tuple in tuples) {
		NSArray *keyValueArray = [tuple componentsSeparatedByString:@"="];
		
		if (keyValueArray.count == 2) {
			NSString *key = [keyValueArray objectAtIndex: 0];
			NSString *value = [keyValueArray objectAtIndex: 1];
			
			if ([key isEqualToString:@"user_id"]) {
                return value;
            }
		}
	}
	
	return nil;
}


- (NSDate *)getDateFromTwitterCreatedAt:(NSString *)twitterDate {
    // Twitter API datestamps are UTC
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    NSLocale *usLocale = [[NSLocale alloc]initWithLocaleIdentifier:@"en_US"];
    [dateFormatter setLocale:usLocale];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    
    // according to some chinese programmer, this is wrong.
    //[dateFormatter setDateFormat:@"EEE MMM dd HH:mm:ss +0000 yyyy"];
    
    [dateFormatter setDateFormat:@"EEE MMM dd HH:mm:ss ZZZZ yyyy"];
    
    return [dateFormatter dateFromString:twitterDate];
}

- (void)clearConsumer {
    self.consumer = nil;
}

- (void)temporarilySetConsumerKey:(NSString *)consumerKey andSecret:(NSString *)consumerSecret {
    self.shouldClearConsumer = YES;
    self.consumer = [[OAConsumer alloc]initWithKey:consumerKey secret:consumerSecret];
}

- (NSString *)getSarcasticErrorDescriptionForErrorCode:(int)errorCode {
    if (errorCode == 32) {
        return @"Your call could not be completed as dialed.";
    }
    
    if (errorCode == 88) {
        return @"The request limit for this resource has been reached for the current rate limit window.";
    }
    
    if (errorCode == 89) {
        return @"The access token used in the request is incorrect or has expired.";
    }
    
    if (errorCode == 200) {
        return @"Quit being such an uptight person. See error 420 (Enhance your calm) for help with this issue.";
    }
    
    if (errorCode == -1009) {
        return @"You are disconnected from the internet. Reconnect and try again.";
    }
    
    if (errorCode == -1200) {
        return @"This error is not your fault and is a temporary issue.";
    }
    
    if (errorCode == -1012) {
        return @"I paraphrase IT Crowd (British TV Show): Try logging out and back in again.";
    }
    
    if (errorCode == 304) {
        return @"There was no new data to return.";
    }
    
    if (errorCode == 400) {
        return @"Twitter is either rate limiting you, or this app just messed up.";
    }
    
    if (errorCode == 401) {
        return @"Are you logged in?";
    }
    
    if (errorCode == 403) {
        return @"Check what you are posting. Twitter doesn't accept duplicate posts.";
    }
    
    if (errorCode == 404 || errorCode == 34) {
        return @"Yeah, you know the drill. The content you requested is not available.";
    }
    
    if (errorCode == 420) {
        return @"Bro, You're being rate limited.";
    }
    
    if (errorCode == 429) {
        return @"Chill out dude, why are you overloading Twitter with so many requests? See error 420 for help.";
    }
    
    if (errorCode == 500 || errorCode == 131) {
        return @"Its not your fault, its Twitter's. Just try again later";
    }
    
    if (errorCode == 502) {
        return @"Twitter is down right now.";
    }
    
    if (errorCode == 503 || errorCode == 130) {
        return @"Back off, Twitter is being accosted by people like you and is over capacity.";
    }
    
    if (errorCode == 504) {
        return @"Twitter had an API fart.";
    }
    
    if (errorCode == 1001) { // -1001
        return @"There is something wrong, and it is most likely my fault. So sue me.";
    }
    
    if (errorCode == 0) {
        return nil;
    }
    
    if (errorCode == 1) {
        return @"Just because it's an API Error doesn't mean that you have to blame it on Twitter.";
    }
    
    if (errorCode == 2) {
        return @"Missing something?";
    }
    
    if (errorCode == 3) {
        return @"This image is just too big for Twitter, try again later with 700KB...";
    }
    
    if (errorCode == 4) {
        return @"Who are you? You forgot to login...";
    }
    
    return @"Whoa... An unknown error!";
}

- (void)showOAuthLoginControllerFromViewController:(UIViewController *)sender {
    [sender presentModalViewController:[self OAuthLoginWindow] animated:YES];
}

- (UIViewController *)OAuthLoginWindow {
    FHSTwitterEngineController *vc = [[FHSTwitterEngineController alloc]initWithEngine:self];
    vc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    return vc;
}

+ (BOOL)isConnectedToInternet {
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)&zeroAddress);
    if (reachability != nil) {
        SCNetworkReachabilityFlags flags;
        if (SCNetworkReachabilityGetFlags(reachability, &flags)) {
            
            if ((flags & kSCNetworkReachabilityFlagsReachable) == 0) {
                CFRelease(reachability);
                return NO;
            }
            
            if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) {
                CFRelease(reachability);
                return YES;
            }
            
            
            if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand) != 0) || (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0)) {
                if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0) {
                    CFRelease(reachability);
                    return YES;
                }
            }
            
            if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN) {
                CFRelease(reachability);
                return YES;
            }
        }
        CFRelease(reachability);
    }
    return NO;
}

@end

@implementation FHSTwitterEngineController

@synthesize theWebView, requestToken, engine, navBar, blockerView, pinCopyBar;

- (id)initWithEngine:(FHSTwitterEngine *)theEngine {
    if (self = [super init]) {
        self.engine = theEngine;
    }
    return self;
}   

- (void)loadView {
    [super loadView];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(pasteboardChanged:) name:UIPasteboardChangedNotification object:nil];
    
    self.view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, 460)];
    self.view.backgroundColor = [UIColor grayColor];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    self.theWebView = [[UIWebView alloc]initWithFrame:CGRectMake(0, 44, 320, 416)];
    self.theWebView.hidden = YES;
    self.theWebView.delegate = self;
    self.theWebView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.theWebView.dataDetectorTypes = UIDataDetectorTypeNone;
    
    self.navBar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, 320, 44)];
    self.navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
	
	[self.view addSubview:self.theWebView];
	[self.view addSubview:self.navBar];
    
	self.blockerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 200, 60)];
	self.blockerView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.8];
	self.blockerView.center = CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2);
	self.blockerView.clipsToBounds = YES;
    self.blockerView.layer.cornerRadius = 10;
	
	UILabel	*label = [[UILabel alloc]initWithFrame:CGRectMake(0, 5, blockerView.bounds.size.width, 15)];
	label.text = @"Please Wait...";
	label.backgroundColor = [UIColor clearColor];
	label.textColor = [UIColor whiteColor];
	label.textAlignment = UITextAlignmentCenter;
	label.font = [UIFont boldSystemFontOfSize:15];
	[self.blockerView addSubview:label];
	
	UIActivityIndicatorView	*spinner = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	spinner.center = CGPointMake(self.blockerView.bounds.size.width/2, (self.blockerView.bounds.size.height/2)+10);
	[self.blockerView addSubview:spinner];
	[self.view addSubview:self.blockerView];
	[spinner startAnimating];
	
	UINavigationItem *navItem = [[UINavigationItem alloc]initWithTitle:@"Twitter Login"];
	navItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(close)];
	[self.navBar pushNavigationItem:navItem animated:NO];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    dispatch_async(GCDBackgroundThread, ^{
        @autoreleasepool {
            NSString *reqString = [self.engine getRequestTokenString];
            
            if (reqString.length == 0) {
                [self dismissModalViewControllerAnimated:YES];
                return;
            }
            
            self.requestToken = [[OAToken alloc]initWithHTTPResponseBody:reqString];
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.twitter.com/oauth/authorize?oauth_token=%@",self.requestToken.key]]];
            
            dispatch_sync(GCDMainThread, ^{
                @autoreleasepool {
                    [self.theWebView loadRequest:request];
                }
            });
        }
    });
}

- (void)gotPin:(NSString *)pin {
    [self.requestToken setVerifier:pin];
    [self.engine finishAuthWithPin:pin andRequestToken:self.requestToken];
    [self dismissModalViewControllerAnimated:YES];
}

- (void)pasteboardChanged:(NSNotification *)note {
	UIPasteboard *pb = [UIPasteboard generalPasteboard];
	
	if ([note.userInfo objectForKey:UIPasteboardChangedTypesAddedKey] == nil) {
        return;
    }
	
	NSString *copied = pb.string;
	
	if (copied.length != 7 || !copied.isNumeric) {
        return;
    }
	
	[self gotPin:copied];
}

- (NSString *)locatePin {
    // JavaScript for the newer Twitter PIN image
	NSString *js = @"var d = document.getElementById('oauth-pin'); if (d == null) d = document.getElementById('oauth_pin'); " \
    "if (d) { var d2 = d.getElementsByTagName('code'); if (d2.length > 0) d2[0].innerHTML; }";
	NSString *pin = [[self.theWebView stringByEvaluatingJavaScriptFromString:js]stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	if (pin.length == 7) {
		return pin;
	} else {
		// Older version of Twitter PIN Image
        js = @"var d = document.getElementById('oauth-pin'); if (d == null) d = document.getElementById('oauth_pin'); if (d) d = d.innerHTML; d;";
		pin = [[self.theWebView stringByEvaluatingJavaScriptFromString:js]stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
		if (pin.length == 7) {
			return pin;
		}
	}
	
	return nil;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    self.theWebView.userInteractionEnabled = YES;
    NSString *authPin = [self locatePin];
    
    if (authPin.length) {
        [self gotPin:authPin];
        return;
    }
    
    NSString *formCount = [webView stringByEvaluatingJavaScriptFromString:@"document.forms.length"];
    
    if ([formCount isEqualToString:@"0"]) {
        [self showPinCopyPrompt];
    }
	
	[UIView beginAnimations:nil context:nil];
	blockerView.hidden = YES;
	[UIView commitAnimations];
	
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    self.theWebView.hidden = NO;
}

- (void)showPinCopyPrompt {
	if (self.pinCopyPromptBar.superview) {
        return;
    }
    
	self.pinCopyPromptBar.center = CGPointMake(self.pinCopyPromptBar.bounds.size.width/2, self.pinCopyPromptBar.bounds.size.height/2);
	[self.view insertSubview:self.pinCopyPromptBar belowSubview:navBar];
	
	[UIView beginAnimations:nil context:nil];
    self.pinCopyBar.center = CGPointMake(self.pinCopyPromptBar.bounds.size.width/2, navBar.bounds.size.height+pinCopyBar.bounds.size.height/2);
	[UIView commitAnimations];
}

- (void)removePinCopyPrompt {
    if (self.pinCopyBar.superview) {
        [self.pinCopyBar removeFromSuperview];
    }
}

- (UIView *)pinCopyPromptBar {
	if (self.pinCopyBar == nil) {
		self.pinCopyBar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 44, self.view.bounds.size.width, 44)];
		self.pinCopyBar.barStyle = UIBarStyleBlackTranslucent;
		self.pinCopyBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        self.pinCopyBar.items = [NSArray arrayWithObjects:[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil], [[UIBarButtonItem alloc]initWithTitle:@"Select and Copy the PIN" style: UIBarButtonItemStylePlain target:nil action: nil], [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil], nil];
        
	}
	return self.pinCopyBar;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    self.theWebView.userInteractionEnabled = NO;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	[UIView beginAnimations:nil context:nil];
	[self.blockerView setHidden:NO];
    [self.theWebView setHidden:YES];
	[UIView commitAnimations];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    BOOL isNotCancelLink = !strstr([[NSString stringWithFormat:@"%@",request.URL]UTF8String], "denied=");
    
	NSData *data = [request HTTPBody];
	char *raw = data?(char *)[data bytes]:"";
    
    if (!isNotCancelLink) {
        [self dismissModalViewControllerAnimated:YES];
        return NO;
    }
	
	if (raw && (strstr(raw, "cancel=") || strstr(raw, "deny="))) {
		[self dismissModalViewControllerAnimated:YES];
		return NO;
	}
	return YES;
}

- (void)close {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)dismissModalViewControllerAnimated:(BOOL)animated {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [theWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@""]]];
    [super dismissModalViewControllerAnimated:animated];
}

@end



static char encodingTable[64] = {
    'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P',
    'Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f',
    'g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v',
    'w','x','y','z','0','1','2','3','4','5','6','7','8','9','+','/' };

@implementation NSData (Base64)

+ (NSData *)dataWithBase64EncodedString:(NSString *) string {
	NSData *result = [[NSData alloc]initWithBase64EncodedString:string];
	return result;
}

- (id)initWithBase64EncodedString:(NSString *)string {
	NSMutableData *mutableData = nil;
    
	if (string) {
		unsigned long ixtext = 0;
		unsigned long lentext = 0;
		unsigned char ch = 0;
		// unsigned char inbuf[4], outbuf[3];
        unsigned char inbuf[4] = {0,0,0,0}, outbuf[3] = {0,0,0};
		short ixinbuf = 0;
		BOOL flignore = NO;
		BOOL flendtext = NO;
		NSData *base64Data = nil;
		const unsigned char *base64Bytes = nil;
        
		// Convert the string to ASCII data.
		base64Data = [string dataUsingEncoding:NSASCIIStringEncoding];
		base64Bytes = [base64Data bytes];
		mutableData = [NSMutableData dataWithCapacity:[base64Data length]];
		lentext = [base64Data length];
        
		while (YES) {
			if (ixtext >= lentext) {
                break;
            }
            
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
                    
					if ((ixinbuf == 1) || (ixinbuf == 2)) {
                        ctcharsinbuf = 1;
                    } else {
                        ctcharsinbuf = 2;
                    }
                    
					ixinbuf = 3;
					flbreak = YES;
				}
                
				inbuf [ixinbuf++] = ch;
                
				if (ixinbuf == 4) {
					ixinbuf = 0;
					outbuf [0] = (inbuf[0] << 2) | ((inbuf[1] & 0x30) >> 4);
					outbuf [1] = ((inbuf[1] & 0x0F) << 4 ) | ((inbuf[2] & 0x3C) >> 2);
					outbuf [2] = ((inbuf[2] & 0x03) << 6 ) | (inbuf[3] & 0x3F);
                    
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
	NSMutableString *result = [NSMutableString stringWithCapacity:[self length]];
	unsigned long ixtext = 0;
	unsigned long lentext = [self length];
	long ctremaining = 0;
	unsigned char inbuf[3], outbuf[4];
	short charsonline = 0, ctcopy = 0;
	unsigned long ix = 0;
    
	while (YES) {
		ctremaining = lentext - ixtext;
        
		if (ctremaining <= 0) {
            break;
        }
        
		for (int i = 0; i < 3; i++) {
			ix = ixtext + i;
			if (ix < lentext) {
                inbuf[i] = bytes[ix];
            } else {
                inbuf [i] = 0;
            }
		}
        
		outbuf [0] = (inbuf [0] & 0xFC) >> 2;
		outbuf [1] = ((inbuf [0] & 0x03) << 4) | ((inbuf [1] & 0xF0) >> 4);
		outbuf [2] = ((inbuf [1] & 0x0F) << 2) | ((inbuf [2] & 0xC0) >> 6);
		outbuf [3] = inbuf [2] & 0x3F;
		ctcopy = 4;
        
		switch (ctremaining) {
            case 1:
                ctcopy = 2;
                break;
            case 2:
                ctcopy = 3;
                break;
		}
        
		for (int i = 0; i < ctcopy; i++) {
			[result appendFormat:@"%c", encodingTable[outbuf[i]]];
        }
        
		for (int i = ctcopy; i < 4; i++) {
			[result appendFormat:@"%c",'='];
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
