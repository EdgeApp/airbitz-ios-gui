//
//  DL_URLServer.h
//  Ditty Labs
//
//  Created by Adam Harris on 06/18/12.
//  Copyright 2012 Ditty Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum eDL_URLRequestStatus
{
    DL_URLRequestStatus_NotStarted = 0,
    DL_URLRequestStatus_Started,
    DL_URLRequestStatus_Success,
    DL_URLRequestStatus_Failure,
    DL_URLRequestStatus_Cancelled
} tDL_URLRequestStatus;

#define DL_URLSERVER_CACHE_AGE_NEVER   0 // never accept the cache
#define DL_URLSERVER_CACHE_AGE_ANY    -1 // accept any age from the cache

#define VERBOSE_MESSAGES_OFF		0	 // show no messages (default)
#define VERBOSE_MESSAGES_ERRORS		1	 // show error messages in log
#define VERBOSE_MESSAGES_STATS		2	 // show stats messages in log
#define VERBOSE_MESSAGES_DATA		4	 // show actual data returned in log
#define VERBOSE_MESSAGES_ALL        0xff // show all messages

@protocol DL_URLRequestDelegate <NSObject>

@optional
- (void)onDL_URLRequestCompleteWithStatus:(tDL_URLRequestStatus)status resultData:(NSData *)data resultObj:(id)object;
- (void)onDL_URLRequestDidReceiveData:(id)object;
- (void)onDL_URLRequestDidSendData:(id)object sent:(NSInteger)bytesSent remaining:(NSInteger)bytesRemaining totalSent:(NSInteger)totalBytesSent totalToSend:(NSInteger)totalBytesToSend;

@end

@interface DL_URLServer : NSObject

// call this to initialize the DL_URLServer
+ (void)initAll;

// call this to access the one and only DL_URLServer singleton
+ (DL_URLServer *)controller;

// call this to free up DL_URLServer resources and deallocate
+ (void)freeAll;

// public member methods

//Quick test to see if we're connected to the network
- (BOOL)connectedToNetwork;

//issue an HTTP request
//	strURL should be in the format: @"http://www.domain.com/directory/page.php"
//	strParams should be in the format: @"param1=val&param2=val..."
//  delegate will receive result of request
- (void)issueRequestURL:(NSString *)strURL withParams:(NSString *)strParams withObject:(id)returnObj withDelegate:(id<DL_URLRequestDelegate>)callbackDelegate;

//issue an HTTP request with caching
//	same as above but with 2 extra caching parameters:
//	acceptableCacheAge:
//		age is in seconds.  If a cached item is found, and its age is <= specified value then return the cached item
//		if you specify age of DL_URLSERVER_CACHE_AGE_ANY then it will always return the cached value and not hit the server
//	cacheResult:
//		indicates whether or not you wish to cache the server result.
- (void)issueRequestURL:(NSString *)strURL withParams:(NSString *)strParams withObject:(id)returnObj withDelegate:(id<DL_URLRequestDelegate>)callbackDelegate acceptableCacheAge:(double)cacheAgeAccepted cacheResult:(BOOL)bCacheResult;

//cancel all requests
- (void)cancelAllRequests;

//cancel only the requests associated with the specified delegate
//if delegate is nil, all requests will be cancelled
- (void)cancelAllRequestsForDelegate:(id<DL_URLRequestDelegate>)delegate;

//clear all items out of the cache.  This is called automatically on a memory warning
- (void)clearCache;

//call with bitmask to turn desired messages on.  Defaults to 0
- (void)verbose:(int)messageMask;

//allows user to specify additional requests to go into the header such as an API key
- (void)setHeaderRequestValue:(NSString *)value forKey:(NSString *)key;

@end