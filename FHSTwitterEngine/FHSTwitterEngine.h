//
//  FHSTwitterEngine.h
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 8/22/12.
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

// For y'all who don't wanna read the above, you can do whatever you want with this code


//
// FHSTwitterEngine
// The synchronous Twitter engine that doesn’t suck!!
//

// FHSTwitterEngine is Synchronous
// That means you will have to thread. Boo Hoo.

// See README.markdown for more

#import <Foundation/Foundation.h>

// BOOL keys
// Used to return boolean values while accounting for errors
#define FHSTwitterEngineBOOLKeyYES @"YES"
#define FHSTwitterEngineBOOLKeyNO @"NO"
#define FHSTwitterEngineBOOLKeyERROR @"ERROR"

// These are for the dispatch_async()/dispatch_sync() calls that you use to get around the synchronous-ness
#define GCDBackgroundThread dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
#define GCDMainThread dispatch_get_main_queue()

typedef enum {
    FHSTwitterEngineAlignModeLeft,
    FHSTwitterEngineAlignModeRight,
    FHSTwitterEngineAlignModeCenter,
    FHSTwitterEngineAlignModeNone
} FHSTwitterEngineAlignMode;

// Return Code Keys
typedef enum {
    FHSTwitterEngineReturnCodeOK,
    FHSTwitterEngineReturnCodeAPIError,
    FHSTwitterEngineReturnCodeInsufficientInput,
    FHSTwitterEngineReturnCodeImageTooLarge,
    FHSTwitterEngineReturnCodeUserUnauthorized
} FHSTwitterEngineReturnCode;

// Image sizes
typedef enum {
    FHSTwitterEngineImageSizeMini, // 24px by 24px
    FHSTwitterEngineImageSizeNormal, // 48x48
    FHSTwitterEngineImageSizeBigger, // 73x73
    FHSTwitterEngineImageSizeOriginal // original size of image
} FHSTwitterEngineImageSize;

@protocol FHSTwitterEngineAccessTokenDelegate <NSObject>

- (void)storeAccessToken:(NSString *)accessToken;
- (NSString *)loadAccessToken;

@end

@class OAToken;
@class OAConsumer;

@interface FHSTwitterEngine : NSObject <UIWebViewDelegate>

//
//
// REST API
//
//

//
// Custom REST API methods
// They call 2 to 10 requests per method. This can be expensive CACHE CACHE CACHE!!!!!
//

- (NSArray *)getFollowers; // followers/ids & users/lookup
- (NSArray *)getFriends; // friends/ids & users/lookup


//
// Normal REST API methods
//

// statuses/update
- (int)postTweet:(NSString *)tweetString inReplyTo:(NSString *)inReplyToString;
- (int)postTweet:(NSString *)tweetString;

// statuses/home_timeline
- (id)getHomeTimelineSinceID:(NSString *)sinceID count:(int)count;

// help/test
- (BOOL)testService;

// blocks/create
- (int)block:(NSString *)username;

// blocks/destroy
- (int)unblock:(NSString *)username;

// users/lookup
- (id)getUserInformationForUsers:(NSArray *)users areUsers:(BOOL)flag;

// notifications/follow & notifications/leave
- (int)disableNotificationsForID:(NSString *)identifier;
- (int)disableNotificationsForUsername:(NSString *)username;
- (int)enableNotificationsForID:(NSString *)identifier;
- (int)enableNotificationsForUsername:(NSString *)identifier;

// account/totals
- (NSDictionary *)getTotals;

// account/update_profile_image
- (int)setProfileImageWithImageAtPath:(NSString *)file;

// account/settings POST & GET
// See FHSTwitterEngine.m for details
- (int)updateSettingsWithDictionary:(NSDictionary *)settings;
- (NSDictionary *)getUserSettings;

// account/update_profile
// See FHSTwitterEngine.m for details
- (int)updateUserProfileWithDictionary:(NSDictionary *)settings;

// account/update_profile_background_image
- (int)setProfileBackgroundImageWithImageAtPath:(NSString *)file tiled:(BOOL)flag;
- (int)setUseProfileImage:(BOOL)shouldUseProfileImage;

// account/update_profile_colors
// See FHSTwitterEngine.m for details
// If the dictionary is nil, FHSTwitterEngine resets the values
- (int)updateProfileColorsWithDictionary:(NSDictionary *)dictionary;

// account/rate_limit_status
- (id)getRateLimitStatus;

// favorites/create, favorites/destroy
- (int)markTweet:(NSString *)tweetID asFavorite:(BOOL)flag;

// favorites
- (id)getFavoritesForUser:(NSString *)user isID:(BOOL)isID andCount:(int)count;

// account/verify_credentials
- (id)verifyCredentials;

// search
- (id)searchTwitterWithQuery:(NSString *)queryString;

// friendships/exists
- (id)user:(NSString *)user followsUser:(NSString *)userTwo areUsernames:(BOOL)areUsernames;

// friendships/create
- (int)followUser:(NSString *)user isUsername:(BOOL)isUsername;

// friendships/destroy
- (int)unfollowUser:(NSString *)user isUsername:(BOOL)isUsername;

// friendships/lookup
- (id)lookupFriends:(NSArray *)users areIDs:(BOOL)areIDs;

// friendships/incoming
- (id)getPendingIncomingFollowers;

// friendships/outgoing
- (id)getPendingOutgoingFollowers;

// friendships/update
- (int)enableRetweets:(BOOL)enableRTs andDeviceNotifs:(BOOL)devNotifs forUser:(NSString *)user isID:(BOOL)isID;

// friendships/no_retweet_ids
- (id)getNoRetweetIDs;

// legal/tos
- (id)getTermsOfService;

// legal/privacy
- (id)getPrivacyPolicy;

// direct_messages
- (id)getDirectMessages:(int)count;

// direct_messages/destroy
- (int)deleteDirectMessage:(NSString *)messageID;

// direct_messages/sent
- (id)getSentDirectMessages:(int)count;

// direct_messages/new
- (int)sendDirectMessage:(NSString *)body toUser:(NSString *)user isID:(BOOL)isID;

// direct_messages/show
- (id)showDirectMessage:(NSString *)messageID;

// report_spam
- (int)reportUserAsSpam:(NSString *)user isID:(BOOL)isID;

// help/configuration
- (id)getConfiguration;

// help/languages
- (id)getLanguages;

// blocks/blocking/ids
- (id)listBlockedIDs;

// blocks/blocking
- (id)listBlockedUsers;

// blocks/exists
// Returns NSString, use the FHSTwitterEngineBOOLKey's 
- (id)authenticatedUserIsBlocking:(NSString *)user isID:(BOOL)isID;

// users/profile_image
// Returns UIImage
- (id)getProfileImageForUsername:(NSString *)username andSize:(FHSTwitterEngineImageSize)size;

// trends/daily
- (id)getDailyTrends;

// trends/weekly
- (id)getWeeklyTrends;

// statuses/user_timeline
- (id)getTimelineForUser:(NSString *)user isID:(BOOL)isID count:(int)count;
- (id)getTimelineForUser:(NSString *)user isID:(BOOL)isID count:(int)count sinceID:(NSString *)sinceID maxID:(NSString *)maxID;

// statuses/retweet
- (int)retweet:(NSString *)identifier;

// statuses/oembed
- (id)oembedTweet:(NSString *)identifier maxWidth:(float)maxWidth alignmentMode:(FHSTwitterEngineAlignMode)alignmentMode;

// statuses/show
- (int)getDetailsForTweet:(NSString *)identifier;

// statuses/destory
- (int)destoryTweet:(NSString *)identifier;

// statuses/update_with_media
- (int)postTweet:(NSString *)tweetString withImageData:(NSData *)theData;
- (int)postTweet:(NSString *)tweetString withImageData:(NSData *)theData inReplyTo:(NSString *)irt;

// statuses/mentions_timeline
- (id)getMentionedTimelineForUser:(NSString *)user isID:(BOOL)isID count:(int)count;
- (id)getMentionedTimelineForUser:(NSString *)user isID:(BOOL)isID count:(int)count sinceID:(NSString *)sinceID maxID:(NSString *)maxID;

// lists/lists
- (id)getSubscribedToListsForUser:(NSString *)user isID:(BOOL)isID;

// lists/statuses
- (id)getTimelineForUsersInListWithID:(NSString *)listID count:(int)count;
- (id)getTimelineForUsersInListWithID:(NSString *)listID count:(int)count sinceID:(NSString *)sinceID maxID:(NSString *)maxID;

// lists/members/destroy
- (int)removeUser:(NSString *)user isID:(BOOL)isID fromListWithID:(NSString *)listID;


//
//
// Login and Auth
//
//

// XAuth login
- (int)getXAuthAccessTokenForUsername:(NSString *)username password:(NSString *)password;

// OAuth login
- (UIViewController *)OAuthLoginWindow; // You want to use it with something other than presentModalViewController:animated:
- (void)showOAuthLoginControllerFromViewController:(UIViewController *)sender; // just one less line of code

// Access Token Mangement
- (void)clearAccessToken;
- (void)loadAccessToken;
- (BOOL)isAuthorized;


//
//
// Misc Methods
//
//

// Twitter date string to NSDate converter
- (NSDate *)getDateFromTwitterCreatedAt:(NSString *)twitterDate;

// Error code lookup
// (so you don't have to)
// Keys:
// message - (its the error message)
// title - (its the error code and title)
// Feed this to a UIAlertView or something of the like
- (NSDictionary *)lookupErrorCode:(int)errorCode;

// init method
- (id)initWithConsumerKey:(NSString *)consumerKey andSecret:(NSString *)consumerSecret;

// Logged in user's username
@property (nonatomic, strong) NSString *loggedInUsername;

// Logged in user's Twitter ID
@property (nonatomic, strong) NSString *loggedInID;

// I know, A DELEGATE!!! Its for storing the access token in something other than NSUserDefaults
@property (nonatomic, strong) id<FHSTwitterEngineAccessTokenDelegate> delegate;

// OAuthConsumer stuff
@property (strong, nonatomic) OAToken *accessToken;
@property (strong, nonatomic) OAConsumer *consumer;

@end
