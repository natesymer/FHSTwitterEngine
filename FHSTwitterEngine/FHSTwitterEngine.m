//
//  FHSTwitterEngine.m
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 8/22/12.
//  Copyright (C) 2012 Nathaniel Symer.

//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "FHSTwitterEngine.h"
#import <QuartzCore/QuartzCore.h>

#import "OAConsumer.h"
#import "OAMutableURLRequest.h"
#import "OARequestParameter.h"
#import "OAToken.h"

@interface FHSTwitterEngineController : UIViewController <UIWebViewDelegate> {
    UINavigationBar *navBar;
    UIView *blockerView;
    UIToolbar *pinCopyBar;
}

@property (strong, nonatomic) FHSTwitterEngine *engine;
@property (strong, nonatomic) UIWebView *theWebView;
@property (strong, nonatomic) OAToken *requestToken;

- (id)initWithEngine:(FHSTwitterEngine *)theEngine;
- (NSString *)locatePin;

- (void)showPinCopyPrompt;
- (void)removePinCopyPrompt;

@end

@interface FHSTwitterEngine ()

// id list generator - returns an array of id list strings
- (NSArray *)generateRequestURLSForIDs:(NSArray *)idsArray;

// sendRequest methods, use these for every request
- (int)sendPOSTRequest:(OAMutableURLRequest *)request withParameters:(NSArray *)params;
- (id)sendGETRequest:(OAMutableURLRequest *)request withParameters:(NSArray *)params;

// Login stuff
- (NSString *)getRequestTokenString;
- (NSString *)extractUserIDFromHTTPBody:(NSString *)body;
- (NSString *)extractUsernameFromHTTPBody:(NSString *)body;

@property (strong, nonatomic) OAConsumer *consumer;
@property (strong, nonatomic) OAToken *accessToken;

@end

@interface NSData (Base64)
+ (NSData *)dataWithBase64EncodedString:(NSString *) string;
- (id)initWithBase64EncodedString:(NSString *) string;
- (NSString *)base64EncodingWithLineLength:(unsigned int) lineLength;

@end

@interface NSString (FHSTwitterEngine)

- (NSString *)trimForTwitter;

@end

@implementation NSString (FHSTwitterEngine)

- (NSString *)trimForTwitter {
    NSString *string = [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (string.length > 140) {
        string = [string substringToIndex:140];
    }
    
    return string;
}

@end

@implementation FHSTwitterEngine

@synthesize consumer, accessToken, loggedInUsername, loggedInID;

/*
 TODO:
 - Implement the listed enpoints
 - Fix error message reporting (i.e. returned error strings)
*/

/* 
 // API Endpoints to Implement

 - GET lists
 - GET lists/members
 - POST lists/members/create
 - POST lists/members/destroy
 
 - GET trends/daily
 - GET trends/weekly
 
 - GET blocks/blocking
 - GET blocks/exists

 - GET help/configuration
 - GET help/languages
 
 - POST statuses/update_with_media
 - GET statuses/mentions
 - POST statuses/retweet
 - GET statuses/show
 - POST statuses/destroy
 - GET statuses/user_timeline
 - GET statuses/retweeted_by_me
 - GET statuses/retweeted_to_me
 - GET statuses/retweets_of_me
 - GET statuses/retweeted_to_user
 - GET statuses/retweeted_by_user
 - POST statuses/update_with_media
 - GET statuses/oembed
 
 - GET users/suggestions
 */

// 24 more to implement

- (int)reportUserAsSpam:(NSString *)user isID:(BOOL)isID {
    
    if (user.length == 0) {
        return FHSTwitterEngineReturnCodeInsufficientInput;
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"http://api.twitter.com/1/report_spam.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *userP = [[OARequestParameter alloc]initWithName:nil value:user];
    
    if (isID) {
        userP.name = @"user_id";
    } else {
        userP.name = @"screen_name";
    }
    return [self sendPOSTRequest:request withParameters:[NSArray arrayWithObjects:userP, nil]];
}

- (id)showDirectMessage:(NSString *)messageID {
    
    if (messageID.length == 0) {
        return nil;
    }
    
    NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.twitter.com/1/direct_messages/show/%@.json",messageID]];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    return [self sendGETRequest:request withParameters:nil];
}

- (int)sendDirectMessage:(NSString *)body toUser:(NSString *)user isID:(BOOL)isID {
    
    if (user.length == 0) {
        return FHSTwitterEngineReturnCodeInsufficientInput;
    }
    
    if (body.length == 0) {
        return FHSTwitterEngineReturnCodeInsufficientInput;
    }
    
    body = [body trimForTwitter];
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1/direct_messages/new.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *bodyP = [[OARequestParameter alloc]initWithName:@"text" value:body];
    
    OARequestParameter *userP = [[OARequestParameter alloc]initWithName:nil value:user];
    
    if (isID) {
        userP.name = @"user_id";
    } else {
        userP.name = @"screen_name";
    }
    
    return [self sendPOSTRequest:request withParameters:[NSArray arrayWithObjects:userP, bodyP, nil]];
}

- (id)getSentDirectMessages:(int)count {
    
    if (count == 0) {
        return nil;
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1/direct_messages/sent.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *countP = [[OARequestParameter alloc]initWithName:@"count" value:[NSString stringWithFormat:@"%d",count]];
    return [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:countP, nil]];
}

- (int)deleteDirectMessage:(NSString *)messageID {
    
    if (messageID.length == 0) {
        return FHSTwitterEngineReturnCodeInsufficientInput;
    }
    
    NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.twitter.com/1/direct_messages/destroy/%@.json",messageID]];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    return [self sendPOSTRequest:request withParameters:nil];
}

- (id)getDirectMessages:(int)count {
    
    if (count == 0) {
        return FHSTwitterEngineReturnCodeInsufficientInput;
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1/direct_messages.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *countP = [[OARequestParameter alloc]initWithName:@"count" value:[NSString stringWithFormat:@"%d",count]];
    OARequestParameter *skipStatusP = [[OARequestParameter alloc]initWithName:@"skip_status" value:@"true"];
    return [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:countP, skipStatusP, nil]];
}

- (id)getPrivacyPolicy {
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1/legal/privacy.json"];
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
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1/legal/tos.json"];
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
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1/friendships/no_retweet_ids.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *stringifyIDsP = [[OARequestParameter alloc]initWithName:@"stringify_ids" value:@"true"];
    
    return [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:stringifyIDsP, nil]];
}

- (int)enableRetweets:(BOOL)enableRTs andDeviceNotifs:(BOOL)devNotifs forUser:(NSString *)user isID:(BOOL)isID {
    
    if (user.length == 0) {
        return FHSTwitterEngineReturnCodeInsufficientInput;
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1/friendships/update.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *userP = [[OARequestParameter alloc]initWithName:nil value:user];
    
    if (isID) {
        userP.name = @"user_id";
    } else {
        userP.name = @"screen_name";
    }
    
    OARequestParameter *retweetsP = [[OARequestParameter alloc]initWithName:@"retweets" value:nil];
    
    if (enableRTs) {
        retweetsP.value = @"true";
    } else {
        retweetsP.value = @"false";
    }
    
    OARequestParameter *deviceP = [[OARequestParameter alloc]initWithName:@"device" value:nil];
    
    if (devNotifs) {
        deviceP.value = @"true";
    } else {
        deviceP.value = @"false";
    }

    return [self sendPOSTRequest:request withParameters:[NSArray arrayWithObjects:userP, retweetsP, deviceP, nil]];
}

- (id)getPendingOutgoingFollowers {
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1/friendships/outgoing.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *stringifyIDsP = [[OARequestParameter alloc]initWithName:@"stringify_ids" value:@"true"];
    
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
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1/friendships/incoming.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *stringifyIDsP = [[OARequestParameter alloc]initWithName:@"stringify_ids" value:@"true"];
    
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
    
    NSMutableArray *returnedDictionaries = [[NSMutableArray alloc]init];
    NSArray *reqStrings = [self generateRequestURLSForIDs:users];
    
    for (NSString *reqString in reqStrings) {
        NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1/friendships/lookup.json"];
        
        OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
        
        OARequestParameter *userP = [[OARequestParameter alloc]initWithName:nil value:reqString];
        
        if (areIDs) {
            userP.name = @"user_id";
        } else {
            userP.name = @"screen_name";
        }
        
        id retObj = [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:userP, nil]];
        
        if ([retObj isKindOfClass:[NSArray class]]) {
            [returnedDictionaries addObjectsFromArray:(NSArray *)retObj];
        }
    }
    return returnedDictionaries;
}

- (int)unfollowUser:(NSString *)user isUsername:(BOOL)isUsername {
    
    if (user.length == 0) {
        return FHSTwitterEngineReturnCodeInsufficientInput;
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1/friendships/destroy.json"];
    
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *userP = [[OARequestParameter alloc]initWithName:nil value:user];
    
    if (isUsername) {
        userP.name = @"screen_name";
    } else {
        userP.name = @"user_id";
    }
    
    return [self sendPOSTRequest:request withParameters:[NSArray arrayWithObjects:userP, nil]];
}

- (int)followUser:(NSString *)user isUsername:(BOOL)isUsername {
    
    if (user.length == 0) {
        return FHSTwitterEngineReturnCodeInsufficientInput;
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1/friendships/create.json"];
    
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *userP = [[OARequestParameter alloc]initWithName:nil value:user];
    
    if (isUsername) {
        userP.name = @"screen_name";
    } else {
        userP.name = @"user_id";
    }
    
    return [self sendPOSTRequest:request withParameters:[NSArray arrayWithObjects:userP, nil]];
}

- (id)user:(NSString *)user followsUser:(NSString *)userTwo areUsernames:(BOOL)areUsernames {
    
    if (user.length == 0) {
        return nil;
    }
    
    if (userTwo.length == 0) {
        return nil;
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"http://search.twitter.com/search.json"];
    
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *userP = [[OARequestParameter alloc]initWithName:nil value:user];
    OARequestParameter *userTwoP = [[OARequestParameter alloc]initWithName:nil value:userTwo];
    
    if (areUsernames) {
        userP.name = @"screen_name_a";
        userTwoP.name = @"screen_name_b";
    } else {
        userP.name = @"user_id_a";
        userTwoP.name = @"user_id_b";
    }
    return [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:userP, userTwoP, nil]];
}

- (id)searchTwitterWithQuery:(NSString *)queryString {
    
    int length = queryString.length;
    
    if ((length == 0) || (length > 1000)) {
        return nil;
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"http://search.twitter.com/search.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *queryP = [[OARequestParameter alloc]initWithName:@"q" value:queryString];
    
    return [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:queryP, nil]];
}

- (id)verifyCredentials {
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1/account/verify_credentials.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    return [self sendGETRequest:request withParameters:nil];
}

- (id)getFavoritesForUser:(NSString *)user isID:(BOOL)isID andCount:(int)count {

    if (count == 0) {
        return nil;
    }
    
    if (user.length == 0) {
        return nil;
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1/favorites.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *countP = [[OARequestParameter alloc]initWithName:@"count" value:[NSString stringWithFormat:@"%d",count]];
    
    OARequestParameter *userP = [[OARequestParameter alloc]initWithName:@"screen_name" value:user];
    
    if (isID) {
        userP.name = @"user_id";
    }
    
    return [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:countP, userP, nil]];
}

- (int)markTweet:(NSString *)tweetID asFavorite:(BOOL)flag {
    
    if (tweetID.length == 0) {
        return FHSTwitterEngineReturnCodeInsufficientInput;
    }
    
    NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.twitter.com/1/favorites/%@/%@.json",flag?@"create":@"destroy",tweetID]];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    return [self sendPOSTRequest:request withParameters:nil];
}

- (id)getRateLimitStatus {
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1/account/rate_limit_status.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    return [self sendGETRequest:request withParameters:nil];
}

- (int)updateProfileColorsWithDictionary:(NSDictionary *)dictionary {

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
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1/account/update_profile_colors.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];

    NSMutableArray *params = [[NSMutableArray alloc]init];
    
    OARequestParameter *profile_background_colorP = [[OARequestParameter alloc]initWithName:@"profile_background_color" value:profile_background_color];
    OARequestParameter *profile_link_colorP = [[OARequestParameter alloc]initWithName:@"profile_link_color" value:profile_link_color];
    OARequestParameter *profile_sidebar_border_colorP = [[OARequestParameter alloc]initWithName:@"profile_sidebar_border_color" value:profile_sidebar_border_color];
    OARequestParameter *profile_sidebar_fill_colorP = [[OARequestParameter alloc]initWithName:@"profile_sidebar_fill_color" value:profile_sidebar_fill_color];
    OARequestParameter *profile_text_colorP = [[OARequestParameter alloc]initWithName:@"rofile_text_color" value:profile_text_color];
    
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
    
    OARequestParameter *skipStatus = [[OARequestParameter alloc]initWithName:@"skip_status" value:@"true"];
    [params addObject:skipStatus];

    return [self sendPOSTRequest:request withParameters:params];
}

- (int)setUseProfileImage:(BOOL)shouldUseProfileImage {
    NSURL *baseURL = [NSURL URLWithString:@"http://api.twitter.com/1/account/update_profile_background_image.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    NSMutableArray *params = [[NSMutableArray alloc]init];
    
    OARequestParameter *skipStatus = [[OARequestParameter alloc]initWithName:@"skip_status" value:@"true"];
    OARequestParameter *useImage = [[OARequestParameter alloc]initWithName:@"profile_use_background_image" value:shouldUseProfileImage?@"true":@"false"];
    
    [params addObject:skipStatus];
    [params addObject:useImage];

    return [self sendPOSTRequest:request withParameters:params];
}

- (int)setProfileBackgroundImageWithImageAtPath:(NSString *)file tiled:(BOOL)flag {

    if (file.length == 0) {
        return FHSTwitterEngineReturnCodeInsufficientInput;
    }
    
    if (![[NSFileManager defaultManager]fileExistsAtPath:file]) {
        return FHSTwitterEngineReturnCodeInsufficientInput;
    }
    
    if ([[[NSFileManager defaultManager]attributesOfFileSystemForPath:file error:nil]fileSize] >= 800000) {
        return FHSTwitterEngineReturnCodeImageTooLarge;
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"http://api.twitter.com/1/account/update_profile_background_image.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    NSMutableArray *params = [[NSMutableArray alloc]init];
    
    OARequestParameter *tiled = [[OARequestParameter alloc]initWithName:@"tiled" value:flag?@"true":@"false"];
    OARequestParameter *skipStatus = [[OARequestParameter alloc]initWithName:@"skip_status" value:@"true"];
    OARequestParameter *useImage = [[OARequestParameter alloc]initWithName:@"profile_use_background_image" value:@"true"];
    OARequestParameter *image = [[OARequestParameter alloc]initWithName:@"image" value:[[NSData dataWithContentsOfFile:file]base64EncodingWithLineLength:0]];
    
    [params addObject:skipStatus];
    [params addObject:useImage];
    [params addObject:image];
    [params addObject:tiled];
    
    return [self sendPOSTRequest:request withParameters:params];
}

- (int)setProfileImageWithImageAtPath:(NSString *)file {
    
    if (file.length == 0) {
        return FHSTwitterEngineReturnCodeInsufficientInput;
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"http://api.twitter.com/1/account/update_profile_image.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    if ([[[NSFileManager defaultManager]attributesOfFileSystemForPath:file error:nil]fileSize] >= 700000) {
        return 3;
    }
    
    OARequestParameter *image = [[OARequestParameter alloc]initWithName:@"image" value:[[NSData dataWithContentsOfFile:file]base64EncodingWithLineLength:0]];
    OARequestParameter *skipStatus = [[OARequestParameter alloc]initWithName:@"skip_status" value:@"true"];
    
    return [self sendPOSTRequest:request withParameters:[NSArray arrayWithObjects:image, skipStatus, nil]];
}

- (NSDictionary *)getTotals {

    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1/account/totals.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    return (NSDictionary *)[self sendGETRequest:request withParameters:nil];
}

- (NSDictionary *)getUserSettings {

    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1/account/settings.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    return (NSDictionary *)[self sendGETRequest:request withParameters:nil];
}

- (int)updateUserProfileWithDictionary:(NSDictionary *)settings {
    
    if (!settings) {
        return FHSTwitterEngineReturnCodeInsufficientInput;
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
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1/account/update_profile.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    NSMutableArray *params = [[NSMutableArray alloc]init];
    
    OARequestParameter *nameP = [[OARequestParameter alloc]initWithName:@"name" value:name];
    OARequestParameter *urlP = [[OARequestParameter alloc]initWithName:@"url" value:url];
    OARequestParameter *locationP = [[OARequestParameter alloc]initWithName:@"location" value:location];
    OARequestParameter *descriptionP = [[OARequestParameter alloc]initWithName:@"description" value:description];
    OARequestParameter *skipStatus = [[OARequestParameter alloc]initWithName:@"skip_status" value:@"true"];
    
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

- (int)updateSettingsWithDictionary:(NSDictionary *)settings {

    if (!settings) {
        return FHSTwitterEngineReturnCodeInsufficientInput;
    }
    
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
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1/account/settings.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *sleep_time_enabledP = [[OARequestParameter alloc]initWithName:@"sleep_time_enabled" value:sleep_time_enabled];
    OARequestParameter *start_sleep_timeP = [[OARequestParameter alloc]initWithName:@"start_sleep_time" value:start_sleep_time];
    OARequestParameter *end_sleep_timeP = [[OARequestParameter alloc]initWithName:@"end_sleep_time" value:end_sleep_time];
    OARequestParameter *time_zoneP = [[OARequestParameter alloc]initWithName:@"time_zone" value:time_zone];
    OARequestParameter *langP = [[OARequestParameter alloc]initWithName:@"lang" value:lang];
    
    NSMutableArray *params = [[NSMutableArray alloc]init];
    
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

- (int)disableNotificationsForID:(NSString *)identifier {
    
    if (identifier.length == 0) {
        return FHSTwitterEngineReturnCodeInsufficientInput;
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1/notifications/leave.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *usernameParam = [[OARequestParameter alloc]initWithName:@"user_id" value:identifier];
    
    return [self sendPOSTRequest:request withParameters:[NSArray arrayWithObjects:usernameParam, nil]];
}

- (int)disableNotificationsForUsername:(NSString *)username {
    
    if (username.length == 0) {
        return FHSTwitterEngineReturnCodeInsufficientInput;
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1/notifications/leave.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *usernameParam = [[OARequestParameter alloc]initWithName:@"screen_name" value:username];
    
    return [self sendPOSTRequest:request withParameters:[NSArray arrayWithObjects:usernameParam, nil]];
}

- (int)enableNotificationsForID:(NSString *)identifier {
    
    if (identifier.length == 0) {
        return FHSTwitterEngineReturnCodeInsufficientInput;
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1/notifications/follow.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *usernameParam = [[OARequestParameter alloc]initWithName:@"user_id" value:identifier];
    
    return [self sendPOSTRequest:request withParameters:[NSArray arrayWithObjects:usernameParam, nil]];
}

- (int)enableNotificationsForUsername:(NSString *)username {
    
    if (username.length == 0) {
        return FHSTwitterEngineReturnCodeInsufficientInput;
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1/notifications/follow.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *usernameParam = [[OARequestParameter alloc]initWithName:@"screen_name" value:username];
    
    return [self sendPOSTRequest:request withParameters:[NSArray arrayWithObjects:usernameParam, nil]];
}

- (id)getUserInformationForUsers:(NSArray *)users areUsers:(BOOL)flag {
    
    if (users.count == 0) {
        return nil;
    }
    
    if (users.count > 99) {
        return nil; // change to error message later
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
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1/users/lookup.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    NSString *paramName = nil;
    
    if (flag) {
        paramName = @"screen_name";
    } else {
        paramName = @"user_id";
    }
    
    OARequestParameter *usernames = [[OARequestParameter alloc]initWithName:paramName value:userString];
    
    return [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:usernames, nil]];
}

- (int)unblock:(NSString *)username {
    
    if (username.length == 0) {
        return FHSTwitterEngineReturnCodeInsufficientInput;
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1/blocks/destroy.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *usernameP = [[OARequestParameter alloc]initWithName:@"screen_name" value:username];
    
    return [self sendPOSTRequest:request withParameters:[NSArray arrayWithObjects:usernameP, nil]];
}

- (int)block:(NSString *)username {
    
    if (username.length == 0) {
        return FHSTwitterEngineReturnCodeInsufficientInput;
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1/blocks/create.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *usernameP = [[OARequestParameter alloc]initWithName:@"screen_name" value:username];
    
    return [self sendPOSTRequest:request withParameters:[NSArray arrayWithObjects:usernameP, nil]];
}

- (BOOL)testService {
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1/help/test.json"];
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
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1/statuses/home_timeline.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    OARequestParameter *since_id = [[OARequestParameter alloc]initWithName:@"since_id" value:sinceID];
    OARequestParameter *countParam = [[OARequestParameter alloc]initWithName:@"count" value:[NSString stringWithFormat:@"%d", count]];
    
    NSArray *params = [NSArray arrayWithObjects:since_id, countParam, nil];
    
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
    NSMutableArray *requestStrings = [[NSMutableArray alloc]init];
    
    int position = 1;
    NSString *list = @"";
    
    int remainder = fmod(count, 99);
    
    for (int ii = 0; ii < count; ii++) {
        int theNumber = 99;
        
        int countMinusRemainder = count-remainder;
        
        if (ii >= countMinusRemainder) {
            theNumber = remainder;
        }
        
        if ((count-position) == theNumber) {
            NSString *usernameAtPosition = [idsArray objectAtIndex:ii];
            list = [list stringByAppendingFormat:@",%@",usernameAtPosition];
            [requestStrings addObject:list];
            list = @"";
            position = 1;
        } else {
            NSString *usernameAtPosition = [idsArray objectAtIndex:ii];
            list = [list stringByAppendingFormat:@",%@",usernameAtPosition];
            position = position+1;
        }
    }
    
    if ((list.length > 0) && (list.length < 100)) {
        [requestStrings addObject:list];
    }
    
    return requestStrings;
}

- (NSArray *)getFollowers {
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1/followers/ids.json"];
    
    OARequestParameter *param = [[OARequestParameter alloc]initWithName:@"screen_name" value:self.loggedInUsername];
    
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    
    id returnedValue = [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:param, nil]];
    
    NSMutableArray *identifiersFromRequest = nil;
    
    if ([returnedValue isKindOfClass:[NSDictionary class]]) {
        id idsRAW = [(NSDictionary *)returnedValue objectForKey:@"ids"];
        if ([idsRAW isKindOfClass:[NSArray class]]) {
            identifiersFromRequest = [NSMutableArray arrayWithArray:(NSArray *)idsRAW];
        }
    }
    
    if (identifiersFromRequest.count == 0) {
        return nil;
    }
    
    NSMutableArray *usernames = [[NSMutableArray alloc]init];
    
    NSArray *usernameListStrings = [self generateRequestURLSForIDs:identifiersFromRequest];
    
    for (NSString *idListString in [usernameListStrings mutableCopy]) {
        baseURL = [NSURL URLWithString:@"https://api.twitter.com/1/users/lookup.json"];
        
        OARequestParameter *iden = [[OARequestParameter alloc]initWithName:@"user_id" value:idListString];
        OARequestParameter *includeEntities = [[OARequestParameter alloc]initWithName:@"include_entities" value:@"false"];
        
        OAMutableURLRequest *requestTwo = [[OAMutableURLRequest alloc] initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
        
        id parsed = [self sendGETRequest:requestTwo withParameters:[NSArray arrayWithObjects:iden, includeEntities, nil]];
        
        if (!parsed) {
            return nil;
        }
        
        if ([parsed isKindOfClass:[NSDictionary class]]) {
            if ([(NSDictionary *)parsed objectForKey:@"error"]) {
                return nil;
            } else {
                [usernames addObject:[parsed objectForKey:@"screen_name"]];
            }
        }
        
        if ([parsed isKindOfClass:[NSMutableArray class]]) {
            NSMutableArray *array = [[NSMutableArray alloc]initWithArray:(NSArray *)parsed];
            for (NSDictionary *dict in [array mutableCopy]) {
                NSString *name = [dict objectForKey:@"screen_name"];
                [usernames addObject:name];
            }
        }
    }
    return usernames;
}

- (NSArray *)getFriends {

    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1/friends/ids.json"];
    
    OARequestParameter *param = [[OARequestParameter alloc]initWithName:@"screen_name" value:self.loggedInUsername];
    
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    
    id returnedValue = [self sendGETRequest:request withParameters:[NSArray arrayWithObjects:param, nil]];

    NSMutableArray *identifiersFromRequest = nil;
    
    if ([returnedValue isKindOfClass:[NSDictionary class]]) {
        id idsRAW = [(NSDictionary *)returnedValue objectForKey:@"ids"];
        if ([idsRAW isKindOfClass:[NSArray class]]) {
            identifiersFromRequest = [NSMutableArray arrayWithArray:(NSArray *)idsRAW];
        }
    }

    if (identifiersFromRequest.count == 0) {
        return nil;
    }
    
    NSMutableArray *usernames = [[NSMutableArray alloc]init];
    
    NSArray *usernameListStrings = [self generateRequestURLSForIDs:identifiersFromRequest];
    
    for (NSString *idListString in [usernameListStrings mutableCopy]) {
        baseURL = [NSURL URLWithString:@"https://api.twitter.com/1/users/lookup.json"];
        
        OARequestParameter *iden = [[OARequestParameter alloc]initWithName:@"user_id" value:idListString];
        OARequestParameter *includeEntities = [[OARequestParameter alloc]initWithName:@"include_entities" value:@"false"];
        
        OAMutableURLRequest *requestTwo = [[OAMutableURLRequest alloc] initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
        
        id parsed = [self sendGETRequest:requestTwo withParameters:[NSArray arrayWithObjects:iden, includeEntities, nil]];
        
        if (!parsed) {
            return nil;
        }
        
        if ([parsed isKindOfClass:[NSDictionary class]]) {
            if ([(NSDictionary *)parsed objectForKey:@"error"]) {
                return nil;
            } else {
                [usernames addObject:[parsed objectForKey:@"screen_name"]];
            }
        }
        
        if ([parsed isKindOfClass:[NSMutableArray class]]) {
            NSMutableArray *array = [[NSMutableArray alloc]initWithArray:(NSArray *)parsed];
            for (NSDictionary *dict in [array mutableCopy]) {
                NSString *name = [dict objectForKey:@"screen_name"];
                [usernames addObject:name];
            }
        }
    }
    return usernames;
}

- (int)postTweet:(NSString *)tweetString inReplyTo:(NSString *)inReplyToString {
    
    if (tweetString.length == 0) {
        return 2;
    }
    
    tweetString = [tweetString trimForTwitter];
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1/statuses/update.json"];
    
    OARequestParameter *status = [[OARequestParameter alloc]initWithName:@"status" value:tweetString];
    OARequestParameter *inReplyToID = [[OARequestParameter alloc]initWithName:@"in_reply_to_status_id" value:inReplyToString];
    
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:self.accessToken realm:nil signatureProvider:nil];
    
    NSMutableArray *params = [[NSMutableArray alloc]init];
    
    [params addObject:status];
    
    if (inReplyToString.length > 0) {
        [params addObject:inReplyToID];
    }

    // PARAMETERS WERE MALFORMED due to setting the params before the HTTP method... lulz
    
    return [self sendPOSTRequest:request withParameters:params];
}

- (int)postTweet:(NSString *)tweetString {
    return [self postTweet:tweetString inReplyTo:@""];
}


//
// XAuth
//

- (int)getXAuthAccessTokenForUsername:(NSString *)username password:(NSString *)password {
    
    if (password.length == 0) {
        return 2;
    }
    
    if (username.length == 0) {
        return 2;
    }

    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"];
    
	OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:self.consumer token:nil realm:nil signatureProvider:nil];
	
	[request setHTTPMethod:@"POST"];
	
	[request setParameters:[NSArray arrayWithObjects:[OARequestParameter requestParameterWithName:@"x_auth_mode" value:@"client_auth"], [OARequestParameter requestParameterWithName:@"x_auth_username" value:username],[OARequestParameter requestParameterWithName:@"x_auth_password" value:password], nil]];
    
    NSError *error = nil;
    NSURLResponse *response = nil;
    
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    NSString *httpBody = [[NSString alloc]initWithData:responseData encoding:NSUTF8StringEncoding];
    
    if (error) {
        [self storeAccessToken:nil];
        return (int)error.code;
    }
    
    if (httpBody.length > 0) {
        [self storeAccessToken:httpBody];
        return 0;
    } else {
        [self storeAccessToken:nil];
        return 1;
    }
    return 0;
}

//
// sendRequest:
//

- (int)sendPOSTRequest:(OAMutableURLRequest *)request withParameters:(NSArray *)params {

    if (![self isAuthorized]) {
        return 4;
    }
    
    [request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    [request setTimeoutInterval:25];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [request setHTTPMethod:@"POST"];
    [request setParameters:params];
    [request prepare];

    NSError *error = nil;
    NSURLResponse *response = [[NSURLResponse alloc]init];
    
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    id parsedJSONResponse = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:nil];
    
    if (response == nil || responseData == nil || error != nil) {
        return (int)error.code;
    }
    
    if (([(NSHTTPURLResponse *)response statusCode] >= 304)) {
        return (int)[(NSHTTPURLResponse *)response statusCode];
    }
    
    if ([parsedJSONResponse isKindOfClass:[NSDictionary class]]) {
        NSString *errorMessage = [parsedJSONResponse objectForKey:@"error"];
        if (errorMessage.length > 0) {
            return 1;
        }
    }
    
    return 0;
}

- (id)sendGETRequest:(OAMutableURLRequest *)request withParameters:(NSArray *)params {
    
    if (![self isAuthorized]) {
        return nil;
    }
    
    [request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    [request setTimeoutInterval:25];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [request setHTTPMethod:@"GET"];
    [request setParameters:params];
    [request prepare];
    
    NSError *error = nil;
    NSHTTPURLResponse *response = nil;
    
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    id parsedJSONResponse = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:nil];
    
    if (response == nil || responseData == nil || error != nil) {
        return nil;
    }
    
    if (([response statusCode] >= 304)) {
        return nil;
    }

    return parsedJSONResponse;
}



//
// OAuth
//

- (NSString *)getRequestTokenString {
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/oauth/request_token"];

    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:url consumer:self.consumer token:nil realm:nil signatureProvider:nil];
    [request setHTTPMethod:@"POST"];
    [request prepare];
    
    NSError *error = nil;
    NSURLResponse *response = nil;
    
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    if (response == nil || responseData == nil || error != nil) {
        return nil;
    }
    
    if (!([(NSHTTPURLResponse *)response statusCode] < 400)) {
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
    
    NSURLResponse *response = nil;
    NSError *error = nil;
    
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    if (response == nil || responseData == nil || error != nil) {
        return (int)error.code;
    }
    
    NSString *responseBody = [[NSString alloc]initWithData:responseData encoding:NSUTF8StringEncoding];
    
    if (responseBody.length == 0) {
        return 1;
    }
    
    [self storeAccessToken:responseBody];

    return 0;
}

- (void)loadAccessToken {
    NSString *savedHttpBody = [[NSUserDefaults standardUserDefaults]objectForKey:@"SavedAccessHTTPBody"];
    self.accessToken = [[OAToken alloc]initWithHTTPResponseBody:savedHttpBody];
    self.loggedInUsername = [self extractUsernameFromHTTPBody:savedHttpBody];
    self.loggedInID = [self extractUserIDFromHTTPBody:savedHttpBody];
    
}

- (void)storeAccessToken:(NSString *)accessTokenZ {
    self.accessToken = [[OAToken alloc]initWithHTTPResponseBody:accessTokenZ];
    self.loggedInUsername = [self extractUsernameFromHTTPBody:accessTokenZ];
    self.loggedInID = [self extractUserIDFromHTTPBody:accessTokenZ];
    [[NSUserDefaults standardUserDefaults]setObject:accessTokenZ forKey:@"SavedAccessHTTPBody"];
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
    // Twitter dates are UTC
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    NSLocale *usLocale = [[NSLocale alloc]initWithLocaleIdentifier:@"en_US"];
    [dateFormatter setLocale:usLocale];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    
    [dateFormatter setDateFormat:@"EEE MMM dd HH:mm:ss +0000 yyyy"];
    
    NSDate *date = [dateFormatter dateFromString:twitterDate];
    return date;
}

- (NSDictionary *)lookupErrorCode:(int)errorCode {
    NSString *title = nil;
    NSString *message = nil;
    
    if (errorCode == 200) {
        title = @"There is nothing wrong!";
        message = @"Quit being such an uptight person. See error 420 (Enhance your calm) for help with this issue.";
    }
    
    if (errorCode == -1009) {
        title = @"You're Offline!";
        message = @"You are disconnected from the internet. Reconnect and try again.";
    }
    
    if (errorCode == -1200) {
        title = @"Secure Connection Failed";
        message = @"This error is not your fault and is a temporary issue.";
    }
    
    if (errorCode == -1012) {
        title = @"Internal OAuth Error";
        message = @"Try logging out and back in.";
    }
    
    if (errorCode == 304) {
        title = @"Error 304\nNot Modified";
        message = @"There was no new data to return.";
    }
    
    if (errorCode == 400) {
        title = @"Error 400\nBad Request";
        message = @"Are you being rate limited? If not its all my fault.";
    }
    
    if (errorCode == 401) {
        title = @"Error 401\nUnauthorized";
        message = @"Are you logged in?";
    }
    
    if (errorCode == 403) {
        title = @"Error 403\nForbidden";
        message = @"Check what you are posting. Twitter doesn't accept duplicate posts.";
    }
    
    if ((errorCode == 404) || (errorCode == 34)) {
        title = @"Error 404\nNot Found";
        message = @"Yeah, you know the drill. The content you requested is not available.";
    }
    
    if (errorCode == 420) {
        title = @"Error 420\nEnhance Your Calm";
        message = @"You're being rate limited bro...";
    }
    
    if ((errorCode == 500) || (errorCode == 131)) {
        title = @"Error 500\nInternal Server Error";
        message = @"Its not your fault, its Twitter's. Just try again later";
    }
    
    if (errorCode == 502) {
        title = @"Error 502\nBad Gateway";
        message = @"Twitter is down right now.";
    }
    
    if ((errorCode == 503) || (errorCode == 130)) {
        title = @"Error 503\nService Unavailable";
        message = @"Back off, Twitter is being accosted by people like you and is over capacity.";
    }
    
    if (errorCode == 504) {
        title = @"Error 504\nGateway Timeout";
        message = @"Twitter is up, but has an internal failure.";
    }
    
    if (errorCode == 1001) { // -1001
        title = @"Error -1001\nRequest timeout";
        message = @"There is something wrong, and it is most likely my fault. So sue me.";
    }
    
    if (errorCode == 1) {
        title = @"API Error";
        message = @"Twitter messed up this time. Or maybe you did o_O";
    }
    
    if (errorCode == 2) {
        title = @"Missing something?";
        message = @"You forgot something...";
    }
    
    if (errorCode == 3) {
        title = @"Image too large";
        message = @"Your image is just too much for Twitter. Please be nice and give it 700KB images maximum.";
    }
    
    if (errorCode == 4) {
        title = @"Who are you?";
        message = @"You forgot to login...?";
    }
    
    if ((message == nil) && (title == nil)) {
        title = [NSString stringWithFormat:@"Error %d\nUnknown",errorCode];
        message = @"This error is probably not your fault and is most likely mine.";
    }
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
    [dict setObject:title forKey:@"title"];
    [dict setObject:message forKey:@"message"];
    return dict;
}

- (BOOL)isAuthorized {
    if (!self.consumer) {
        return NO;
    }
    
	if (self.accessToken.key && self.accessToken.secret) {
        return YES;
    }
	return NO;
}

- (void)clearAccessToken {
    [self storeAccessToken:nil];
	self.accessToken = nil;
    self.loggedInUsername = nil;
}

- (void)showOAuthLoginControllerFromViewController:(UIViewController *)sender {
    [sender presentModalViewController:[self OAuthLoginWindow] animated:YES];
}

- (UIViewController *)OAuthLoginWindow {
    FHSTwitterEngineController *vc = [[FHSTwitterEngineController alloc]initWithEngine:self];
    vc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    return vc;
}

@end



@interface NSString (TwitterOAuth)

- (BOOL)oauthtwitter_isNumeric;

@end

@implementation NSString (TwitterOAuth)

- (BOOL)oauthtwitter_isNumeric {
	const char *raw = (const char *)[self UTF8String];
	
	for (int i = 0; i < strlen(raw); i++) {
		if (raw[i] < '0' || raw[i] > '9') {
            return NO;
        }
	}
	return YES;
}

@end


@implementation FHSTwitterEngineController

@synthesize theWebView, requestToken, engine;

- (id)initWithEngine:(FHSTwitterEngine *)theEngine {
    self = [super init];
    if (self) {
        self.engine = theEngine;
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    self.theWebView.delegate = nil;
    [theWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@""]]];
    self.view = nil;
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
    
    navBar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, 320, 44)];
    navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
	
	[self.view addSubview:self.theWebView];
	[self.view addSubview:navBar];
	
	blockerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 200, 60)];
	blockerView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.8];
	blockerView.center = CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2);
	blockerView.clipsToBounds = YES;
    blockerView.layer.cornerRadius = 10;
	
	UILabel	*label = [[UILabel alloc]initWithFrame:CGRectMake(0, 5, blockerView.bounds.size.width, 15)];
	label.text = @"Please Wait...";
	label.backgroundColor = [UIColor clearColor];
	label.textColor = [UIColor whiteColor];
	label.textAlignment = UITextAlignmentCenter;
	label.font = [UIFont boldSystemFontOfSize:15];
	[blockerView addSubview:label];
	
	UIActivityIndicatorView	*spinner = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	
	spinner.center = CGPointMake(blockerView.bounds.size.width/2, (blockerView.bounds.size.height/2)+10);
	[blockerView addSubview:spinner];
	[self.view addSubview:blockerView];
	[spinner startAnimating];
	
	UINavigationItem *navItem = [[UINavigationItem alloc]initWithTitle:@"Twitter Login"];
	navItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(close)];
	[navBar pushNavigationItem:navItem animated:NO];
    
    dispatch_async(GCDBackgroundThread, ^{
        NSString *reqTokenString = [self.engine getRequestTokenString];
        self.requestToken = [[OAToken alloc]initWithHTTPResponseBody:reqTokenString];

        NSString *address = [NSString stringWithFormat:@"https://api.twitter.com/oauth/authorize?oauth_token=%@",self.requestToken.key];
        NSURL *url = [NSURL URLWithString:address];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        
        dispatch_sync(GCDMainThread, ^{
            [self.theWebView loadRequest:request];
        });
    });
}

- (void)close {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)gotPin:(NSString *)pin {
    [self.requestToken setVerifier:pin];
    [engine finishAuthWithPin:pin andRequestToken:self.requestToken];
    [self close];
}

- (void)pasteboardChanged:(NSNotification *)note {
	UIPasteboard *pb = [UIPasteboard generalPasteboard];
	
	if ([note.userInfo objectForKey:UIPasteboardChangedTypesAddedKey] == nil) {
        return; // no meaningful change
    }
	
	NSString *copied = pb.string;
	
	if (copied.length != 7 || !copied.oauthtwitter_isNumeric) {
        return;
    }
	
	[self gotPin:copied];
}

- (NSString *)locatePin {
    // JavaScript for the newer Twitter PIN image
    // Run this first to cut down the amount of JS executed
	NSString *js = @"var d = document.getElementById('oauth-pin'); if (d == null) d = document.getElementById('oauth_pin'); " \
    "if (d) { var d2 = d.getElementsByTagName('code'); if (d2.length > 0) d2[0].innerHTML; }";
	NSString *pin = [[theWebView stringByEvaluatingJavaScriptFromString:js]stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	if (pin.length == 7) {
		return pin;
	} else {
		// Older version of Twitter PIN Image
        // Used as a fallback
        js = @"var d = document.getElementById('oauth-pin'); if (d == null) d = document.getElementById('oauth_pin'); if (d) d = d.innerHTML; d;";
		pin = [[theWebView stringByEvaluatingJavaScriptFromString:js]stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
		if (pin.length == 7) {
			return pin;
		}
	}
	
	return nil;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    theWebView.userInteractionEnabled = YES;
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
	
    self.theWebView.hidden = NO;
}


- (void)showPinCopyPrompt {
	if (self.pinCopyPromptBar.superview) {
        return;
    }
    
	self.pinCopyPromptBar.center = CGPointMake(self.pinCopyPromptBar.bounds.size.width/2, self.pinCopyPromptBar.bounds.size.height/2);
	[self.view insertSubview:self.pinCopyPromptBar belowSubview:navBar];
	
	[UIView beginAnimations:nil context:nil];
    pinCopyBar.center = CGPointMake(self.pinCopyPromptBar.bounds.size.width/2, navBar.bounds.size.height+pinCopyBar.bounds.size.height/2);
	[UIView commitAnimations];
}

- (void)removePinCopyPrompt {
    if (pinCopyBar.superview) {
        [pinCopyBar removeFromSuperview];
    }
}

- (UIView *)pinCopyPromptBar {
	if (pinCopyBar == nil){
		CGRect bounds = self.view.bounds;
		
		pinCopyBar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 44, bounds.size.width, 44)];
		pinCopyBar.barStyle = UIBarStyleBlackTranslucent;
		pinCopyBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        pinCopyBar.items = [NSArray arrayWithObjects:
                                   [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                                   [[UIBarButtonItem alloc]initWithTitle:@"Select and Copy the PIN" style: UIBarButtonItemStylePlain target:nil action: nil],
                                   [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                                   nil];
        
	}
	return pinCopyBar;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    self.theWebView.userInteractionEnabled = NO;
	[UIView beginAnimations:nil context:nil];
	[blockerView setHidden:NO];
    [self.theWebView setHidden:YES];
	[UIView commitAnimations];
}


- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    BOOL isNotCancelLink = !strstr([[NSString stringWithFormat:@"%@",request.URL]UTF8String], "denied=");
    
	NSData *data = [request HTTPBody];
	char *raw = data ? (char *)[data bytes] : "";
    
    if (!isNotCancelLink) {
        [self close];
        return NO;
    }
	
	if (raw && (strstr(raw, "cancel=") || strstr(raw, "deny="))) {
		[self close];
		return NO;
	}
	return YES;
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
		unsigned char inbuf[4], outbuf[3];
		short i = 0, ixinbuf = 0;
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
                    
					for (i = 0; i < ctcharsinbuf; i++) {
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
	short i = 0;
	short charsonline = 0, ctcopy = 0;
	unsigned long ix = 0;
    
	while (YES) {
		ctremaining = lentext - ixtext;
        
		if (ctremaining <= 0 ) {
            break;
        }
        
		for (i = 0; i < 3; i++) {
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
        
		for (i = 0; i < ctcopy; i++) {
			[result appendFormat:@"%c", encodingTable[outbuf[i]]];
        }
        
		for (i = ctcopy; i < 4; i++) {
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
