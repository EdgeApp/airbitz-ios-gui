//
//  DL_URLServer.m
//  Ditty Labs
//
//  Created by Adam Harris on 06/18/12.
//  Copyright 2012 Ditty Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SystemConfiguration/SCNetworkReachability.h>
#import <netinet/in.h>
#import "DL_URLServer.h"

#define LIBRARY_VERSION		@"2.3"

#define DebugLog(m, s, ... ) { \
                                if (self.verboseMessageMask & m) \
                                { \
                                    NSLog( @"%@", [NSString stringWithFormat:(s), ##__VA_ARGS__] ); \
                                } \
                             }

typedef enum eRequestType
{
    RequestType_HTTP
} tRequestType;

static BOOL bInitialized = NO;

__strong static DL_URLServer *singleton = nil;  // this will be the one and only object this static singleton class has

@interface DL_URLRequest : NSObject

@end // DL_URLRequest

@interface DL_URLRequest ()

@property (nonatomic, assign)   tRequestType                type;
@property (nonatomic, copy)     NSString                    *strURL;
@property (nonatomic, copy)     NSString                    *strParams;         // for HTTP requests
@property (nonatomic, assign)   id<DL_URLRequestDelegate>   delegate;
@property (nonatomic, strong)   id                          returnObj;
@property (nonatomic, assign)   tDL_URLRequestStatus        status;
@property (nonatomic, strong)   NSDate                      *dateCreated;       // when was the request made
@property (nonatomic, strong)   NSDate                      *dateComplete;      // when were the results returned
@property (nonatomic, assign)   BOOL                        bCache;             // should the results be cache
@property (nonatomic, assign)   double                      cacheAgeAccepted;   // what is the acceptable limit of the cache age
@property (nonatomic, strong)   NSMutableData               *receivedData;      // for HTTP download requests
@property (nonatomic, assign)   NSInteger                   statusCode;
@property (nonatomic, strong)   NSURLConnection             *connection;        // for HTTP requests

@end

@implementation DL_URLRequest

#pragma mark - NSObject overrides

- (id)init
{
    self = [super init];
    if (self) 
	{
        self.type = RequestType_HTTP; // this is default since it was the first created
        self.strURL = @"";
        self.strParams = @"";
        self.delegate = nil;
        self.returnObj = nil;
        self.status = DL_URLRequestStatus_NotStarted;
        self.dateCreated = [NSDate date];
        self.dateComplete = nil;
        self.bCache = NO;
        self.cacheAgeAccepted = DL_URLSERVER_CACHE_AGE_NEVER;
        self.statusCode = 0;
        self.connection = nil;
    }
    return self;
}

- (void)dealloc 
{
    self.strURL = nil;
    self.strParams = nil;

    self.delegate = nil;
    self.returnObj = nil;
    self.dateCreated = nil;
    self.dateComplete = nil;
    self.receivedData = nil;

    if (self.connection)
    {
        [self.connection cancel];
        self.connection = nil;
    }
}

// overriding the description - used in debugging
- (NSString *)description
{
	return([NSString stringWithFormat:
            @"DL_URLRequest: Type: %d, URL=%@, Params=%@, status=%d, dateCreated=%@, dateComplete=%@, bCache=%@, cacheAgeAccepted=%f",
            self.type,
            self.strURL,
            self.strParams,
            self.status,
            self.dateCreated,
            self.dateComplete,
            self.bCache ? @"YES" : @"NO",           
            self.cacheAgeAccepted]);
}

#pragma mark - Public Methods

#pragma mark - Misc Methods

@end

@interface DL_URLServer () <NSStreamDelegate>

@property (nonatomic, strong) NSMutableArray    *arrayRequests;
@property (nonatomic, strong) NSMutableArray    *arrayCachedResults;
@property (nonatomic, assign) int               verboseMessageMask;
@property (nonatomic, strong) NSMutableDictionary			*headerRequests;	// additional HTTP header items user can add to all requests (API key for instance)

- (void)queueUpdate;
- (void)update;
- (DL_URLRequest *)curRequest;
- (DL_URLRequest *)requestForConnection:(NSURLConnection *)connection;
- (void)startRequest:(DL_URLRequest *)request;
- (DL_URLRequest *)findCacheRequest:(DL_URLRequest *)request acceptableCacheAge:(double)cacheAgeAccepted;
- (void)addToCache:(DL_URLRequest *)request;

@end

@implementation DL_URLServer;

#pragma mark - Static Methods

+ (void)initAll
{
	if (NO == bInitialized)
	{
        singleton = [[DL_URLServer alloc] init];
        bInitialized = YES;
	}
    //NSLog(@"%@", singleton);
}

+ (void)freeAll
{
	if (YES == bInitialized)
	{
        // release our singleton
        singleton = nil;
        
		bInitialized = NO;
	}
}


// returns the user held by the singleton 
// (this call is both a container and an object class and the container holds one of itself)
+ (DL_URLServer *)controller
{
    if (!singleton)
    {
        NSLog(@"DL_URLServer: WARNING - not initialized");
    }
    return singleton;
}

#pragma mark - NSObject overrides

- (id)init
{
    self = [super init];
    if (self) 
	{
        // start with default values
        self.arrayRequests = [[NSMutableArray alloc] init];
        self.arrayCachedResults = [[NSMutableArray alloc] init];
		self.headerRequests = [[NSMutableDictionary alloc] init];
		self.verboseMessageMask = VERBOSE_MESSAGES_OFF;
		#if (TARGET_OS_IPHONE)
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
		#endif
    }
    return self;
}

- (void) handleMemoryWarning:(NSNotification *)notification
{
	[self clearCache];
}

- (void)dealloc 
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    self.arrayRequests = nil;
    self.arrayCachedResults = nil;
	self.headerRequests = nil;
}

- (void)verbose:(int)messageMask
{
	self.verboseMessageMask = messageMask;
}

// overriding the description - used in debugging
- (NSString *)description
{
	return([NSString stringWithFormat:@"DL_URLServer v%@ - Requests: %@", LIBRARY_VERSION, self.arrayRequests]);
}

- (void)setHeaderRequestValue:(NSString *)value forKey:(NSString *)key
{
	DebugLog(VERBOSE_MESSAGES_STATS, @"DL_URLServer: Setting header request: %@ for key:%@", value, key);
	[self.headerRequests setObject:value forKey:key];
}

#pragma mark - Private Methods

// returns the current request
- (DL_URLRequest *)curRequest
{
    DL_URLRequest *retVal = nil;
    
    if (self.arrayRequests) 
    {
        if ([self.arrayRequests count])
        {
            retVal = [self.arrayRequests objectAtIndex:0];
        }
    }
    
    return retVal;
}

// returns the request associated with the given connection
- (DL_URLRequest *)requestForConnection:(NSURLConnection *)connection
{
    DL_URLRequest *request = nil;
    for (DL_URLRequest *curRequest in self.arrayRequests)
    {
        if (curRequest.connection == connection)
        {
            request = curRequest;
            break;
        }
    }
    
    return request;
}

// queues an update call (delays it)
- (void)queueUpdate
{
    //[self performSelectorOnMainThread:@selector(update) withObject:nil waitUntilDone:NO]; // this seems to stop other processes from running
    [self performSelector:@selector(update) withObject:nil afterDelay:0];
}

// update the system by handling the current request based upon its state
- (void)update
{
    // get the current request
    DL_URLRequest *curRequest = [self curRequest];
    
    // do we have a request waiting
    if (curRequest)
    {
        // if the request hasn't been started
        if (DL_URLRequestStatus_Started != curRequest.status)
        {
            // if the request is waiting to be started
            if (DL_URLRequestStatus_NotStarted == curRequest.status)
            {
                // start the request
                [self startRequest:curRequest];
            }
            else 
            {
                // finished with some status (success, error or cancelled)
                if ((DL_URLRequestStatus_Success == curRequest.status) || (DL_URLRequestStatus_Failure == curRequest.status))
                {
                    if ((DL_URLRequestStatus_Success == curRequest.status) && (curRequest.bCache))
                    {
                        // add it to the cache
                        [self addToCache:curRequest];
                    }

                    // remove the request
                    [self.arrayRequests removeObject:curRequest];

                    // if we have a delegate
                    if (curRequest.delegate)
                    {
                        if (curRequest.type == RequestType_HTTP)
                        {
                            // if they have set the delegate function
                            if ([curRequest.delegate respondsToSelector:@selector(onDL_URLRequestCompleteWithStatus: resultData: resultObj:)])
                            {
                                // give the delegate the results
                                [curRequest.delegate onDL_URLRequestCompleteWithStatus:curRequest.status resultData:curRequest.receivedData resultObj:curRequest.returnObj];
                            }
                        }
                    }
                }
                else if (DL_URLRequestStatus_Cancelled == curRequest.status)  
                {
                    if (curRequest.connection)
                    {
                        [curRequest.connection cancel];
                    }
                }

                // call ourself again for next request
                [self update];
            }
        }
        
        // update again
        [self queueUpdate];
    }
}

// starts the given request
- (void)startRequest:(DL_URLRequest *)request
{
    if (request)
    {
        if (DL_URLRequestStatus_NotStarted == request.status)
        {
            if (request.type == RequestType_HTTP)
            {
                [self startHTTPRequest:request];
            }
        }
    }
    
    // update
    [self queueUpdate];
}

- (void)startHTTPRequest:(DL_URLRequest *)request
{
    // check for a cache match
    DL_URLRequest *cacheRequestMatch = [self findCacheRequest:request acceptableCacheAge:request.cacheAgeAccepted];
    if (cacheRequestMatch)
    {
        DebugLog(VERBOSE_MESSAGES_STATS, @"DL_URLServer: found a cache match!");
        request.receivedData = cacheRequestMatch.receivedData;
        request.status = DL_URLRequestStatus_Success;
        // don't cache this one since we already have one
        request.bCache = NO;
    }
    else
    {
        // not in cache so send it out
        request.statusCode = 0;
        
        DebugLog(VERBOSE_MESSAGES_STATS, @"DL_URLServer: Request URL: %@", request.strURL);
        DebugLog(VERBOSE_MESSAGES_STATS, @"DL_URLServer: Request params: %@", request.strParams);
        
        NSURL *url = [[NSURL alloc] initWithString:request.strURL];
        NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:url];
        
        
        //cw added.  Library was still returning cached image when image file was renamed on server
        if (request.bCache == NO)
        {
            [[NSURLCache sharedURLCache] removeCachedResponseForRequest:req];
        }
        
        // if we have a parameter string
        if (request.strParams)
        {
            // if there are parameters in the parameter string
            if ([request.strParams length])
            {
                [req setHTTPMethod:@"POST"];
                
                NSData *paramData = [request.strParams dataUsingEncoding:NSUTF8StringEncoding];
                [req setHTTPBody:paramData];
            }
        }
		
		if(self.headerRequests.count)
		{
			NSArray *allKeys = [self.headerRequests allKeys];
			for(NSString *key in allKeys)
			{
				[req addValue:[self.headerRequests objectForKey:key] forHTTPHeaderField:key];
			}
		}
		//NSLog(@"Added API Key");
		
        // old
        //request.connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];

        // new
        request.connection = [[NSURLConnection alloc] initWithRequest:req delegate:self startImmediately:NO];
        [request.connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        [request.connection start];

        // if we created a connection
        if (request.connection)
        {
            [request.receivedData setLength:0];
            request.status = DL_URLRequestStatus_Started;
        }
        else
        {
            DebugLog((VERBOSE_MESSAGES_STATS | VERBOSE_MESSAGES_ERRORS), @"DL_URLServer: Could not create server connection");
            request.status = DL_URLRequestStatus_Failure;
        }
    }
}

- (NSURL *)smartURLForString:(NSString *)str
{
    NSURL *     result;
    NSString *  trimmedStr;
    NSRange     schemeMarkerRange;
    NSString *  scheme;
    
    assert(str != nil);
    
    result = nil;
    
    trimmedStr = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ( (trimmedStr != nil) && ([trimmedStr length] != 0) )
    {
        schemeMarkerRange = [trimmedStr rangeOfString:@"://"];
        
        if (schemeMarkerRange.location == NSNotFound)
        {
            result = [NSURL URLWithString:[NSString stringWithFormat:@"ftp://%@", trimmedStr]];
        } else
        {
            scheme = [trimmedStr substringWithRange:NSMakeRange(0, schemeMarkerRange.location)];
            assert(scheme != nil);
            
            if ( ([scheme compare:@"ftp"  options:NSCaseInsensitiveSearch] == NSOrderedSame) )
            {
                result = [NSURL URLWithString:trimmedStr];
            }
            else
            {
                DebugLog(VERBOSE_MESSAGES_ERRORS, @"DL_URLServer: Unsupported URL- %@", str);
            }
        }
    }
    
    return result;
}

#pragma mark - Cache Methods

// looks for a request in the cache that matches the given request and, if found, returns it
- (DL_URLRequest *)findCacheRequest:(DL_URLRequest *)request acceptableCacheAge:(double)cacheAgeAccepted
{
    DL_URLRequest *matchingRequest = nil;
    
    // if there is an acceptable time
    if (cacheAgeAccepted != DL_URLSERVER_CACHE_AGE_NEVER)
    {
        for (DL_URLRequest *curRequest in self.arrayCachedResults)
        {
            // if this is a match
            if ([curRequest.strURL isEqualToString:request.strURL] && [curRequest.strParams isEqualToString:request.strParams])
            {
                // if age doesn't matter then use it
                if (cacheAgeAccepted < 0.0)
                {
                    matchingRequest = curRequest;
                }
                else
                {
                    // check the age
                    NSTimeInterval timeInterval = fabs([curRequest.dateComplete timeIntervalSinceNow]);
                    if (timeInterval < (double) request.cacheAgeAccepted)
                    {
						matchingRequest = curRequest;
                    }
                    else 
                    {
                        DebugLog(VERBOSE_MESSAGES_STATS, @"DL_URLServer: found a cache match but it's too old");
                        matchingRequest = nil;
                    }
                }
                break;
            }
        }
    }
    
    return matchingRequest;
}

// adds the specific request to the cache
// removes any previous request that matches it
- (void)addToCache:(DL_URLRequest *)request
{
    // first look for an existing one first in case we need to replace it
    DL_URLRequest *existingRequest = [self findCacheRequest:request acceptableCacheAge:DL_URLSERVER_CACHE_AGE_ANY];
    if (existingRequest)
    {
        DebugLog(VERBOSE_MESSAGES_STATS, @"DL_URLServer: Found an identical cache item, removing the old one before adding this new one");
        [self.arrayCachedResults removeObject:existingRequest];
    }
    
    // now add this one
    [self.arrayCachedResults addObject:request];
    
    //NSLog(@"Cache size: %d", [self.arrayCachedResults count]);
}

#pragma mark - Public Methods

- (BOOL)connectedToNetwork
{
    // Create zero addy
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
	
    // Recover reachability flags
    SCNetworkReachabilityRef defaultRouteReachability = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&zeroAddress);
    SCNetworkReachabilityFlags flags;
	
    BOOL didRetrieveFlags = SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags);
    CFRelease(defaultRouteReachability);
	
    if (!didRetrieveFlags)
    {
        DebugLog(VERBOSE_MESSAGES_ERRORS, @"DL_URLServer: Error. Could not recover network reachability flags");
        return NO;
    }
	
    BOOL isReachable = flags & kSCNetworkFlagsReachable;
    BOOL needsConnection = flags & kSCNetworkFlagsConnectionRequired;
	BOOL nonWiFi = flags & kSCNetworkReachabilityFlagsTransientConnection;
	
	NSURL *testURL = [NSURL URLWithString:@"http://www.apple.com/"];
	NSURLRequest *testRequest = [NSURLRequest requestWithURL:testURL  cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:20.0];
	NSURLConnection *testConnection = [[NSURLConnection alloc] initWithRequest:testRequest delegate:self];
	BOOL testConnectionSuccess = NO;
	if(testConnection) testConnectionSuccess = YES;

    return ((isReachable && !needsConnection) || nonWiFi) ? (testConnectionSuccess ? YES : NO) : NO;
}

- (void)issueRequestURL:(NSString *)strURL withParams:(NSString *)strParams withObject:(id)returnObj withDelegate:(id<DL_URLRequestDelegate>)callbackDelegate;
{
    // don't cache and don't accept cache
    [self issueRequestURL:strURL withParams:strParams withObject:returnObj withDelegate:callbackDelegate acceptableCacheAge:DL_URLSERVER_CACHE_AGE_NEVER cacheResult:NO];
}

// -1 for cacheAgeAccepted means any
- (void)issueRequestURL:(NSString *)strURL withParams:(NSString *)strParams withObject:(id)returnObj withDelegate:(id<DL_URLRequestDelegate>)callbackDelegate acceptableCacheAge:(double)cacheAgeAccepted cacheResult:(BOOL)bCacheResult
{
    // create the new request
    DL_URLRequest *newRequest = [[DL_URLRequest alloc] init];
    
    newRequest.type = RequestType_HTTP;
    newRequest.strURL = strURL;
    newRequest.returnObj = returnObj;
    newRequest.delegate = callbackDelegate;
    newRequest.cacheAgeAccepted = cacheAgeAccepted;
    newRequest.bCache = bCacheResult;
    newRequest.status = DL_URLRequestStatus_NotStarted;
    newRequest.strParams = strParams;
    newRequest.receivedData = [[NSMutableData alloc] init];

    if (newRequest.strParams == nil)
    {
        newRequest.strParams = @"";
    }
    
    // check the cache for the request before we even queue it
    DL_URLRequest *cacheRequestMatch = [self findCacheRequest:newRequest acceptableCacheAge:cacheAgeAccepted];
    if (cacheRequestMatch)
    {
        DebugLog(VERBOSE_MESSAGES_STATS, @"DL_URLServer: found a cache match before queueing!");
        if (callbackDelegate)
        {
            // if they have set the delegate function
            if ([callbackDelegate respondsToSelector:@selector(onDL_URLRequestCompleteWithStatus: resultData: resultObj:)])
            {
                // give the delegate the results
                [callbackDelegate onDL_URLRequestCompleteWithStatus:DL_URLRequestStatus_Success resultData:cacheRequestMatch.receivedData resultObj:returnObj];
            }
        }
    }
    else
    {
        // no match in the queue
        
        // add the new request to the array of requests
        [self.arrayRequests addObject:newRequest];
        
        // update the system
        [self update];
    }
}

// cancel's all outstanding requests
- (void)cancelAllRequests
{
    [self cancelAllRequestsForDelegate:nil];
}

// cancel's all outstanding calls request by the given delegate
- (void)cancelAllRequestsForDelegate:(id<DL_URLRequestDelegate>)delegate
{
    // go through all requests back to front so we can remove them
    for (NSInteger i = [self.arrayRequests count] - 1; i >= 0; i--)
    {
        DL_URLRequest *request = [self.arrayRequests objectAtIndex:i];
        if ((request.delegate == delegate) || (delegate == nil))
        {
            if (request.connection)
            {
                [request.connection cancel];
                request.connection = nil;
            }

            [self.arrayRequests removeObjectAtIndex:i];
        }
    }
}

// clears the cache
- (void)clearCache
{
    if (self.arrayCachedResults)
    {
        [self.arrayCachedResults removeAllObjects];
    }
}

#pragma mark - NSURLConnection Callbacks

// called when a response is received
// note: you could get a few of these before data is received (e.g., redirects)
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    DL_URLRequest *curRequest = [self requestForConnection:connection];
    if (curRequest)
    {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
        curRequest.statusCode = [httpResponse statusCode];  
        DebugLog(VERBOSE_MESSAGES_STATS, @"DL_URLServer: Connection response: %ld",  (long)curRequest.statusCode);
        
        if (200 !=  curRequest.statusCode)
        {
            DebugLog(VERBOSE_MESSAGES_ERRORS, @"DL_URLServer: Received failure response (status code = %ld)", (long)curRequest.statusCode);
			DebugLog(VERBOSE_MESSAGES_ERRORS, @"DL_URLServer: Header fields: %@", [httpResponse allHeaderFields]);
            curRequest.status = DL_URLRequestStatus_Failure;
            
            // update the system
            [self queueUpdate];
        }
        
        // beginning of data coming in
        [curRequest.receivedData setLength:0];
    }
}

// called when data comes in
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    DL_URLRequest *curRequest = [self requestForConnection:connection];
    if (curRequest)
    {
        DebugLog(VERBOSE_MESSAGES_STATS, @"DL_URLServer: Received: %lu bytes", (unsigned long)[data length]);
        
        // save the data
        [curRequest.receivedData appendData:data];
        
        // if we have a delegate
        if (curRequest.delegate)
        {
            // if they have set the delegate function
            if ([curRequest.delegate respondsToSelector:@selector(onDL_URLRequestDidReceiveData:)])
            {
                // give the delegate the results
                [curRequest.delegate onDL_URLRequestDidReceiveData:curRequest.returnObj];
            }
        }
    }
}

// called with the something in the request failed
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    DL_URLRequest *curRequest = [self requestForConnection:connection];
    if (curRequest)
    {
        DebugLog((VERBOSE_MESSAGES_STATS | VERBOSE_MESSAGES_ERRORS), @"DL_URLServer: Connection failed!");
        
        curRequest.status = DL_URLRequestStatus_Failure;
        
        // update the system
        [self queueUpdate];
    }
}

// called when the request is complete
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    DL_URLRequest *curRequest = [self requestForConnection:connection];
    if (curRequest)
    {
        curRequest.dateComplete = [NSDate date];
        
        if (curRequest.statusCode == 200)
        {
            DebugLog(VERBOSE_MESSAGES_STATS, @"DL_URLServer: Receive total: %lu bytes", (unsigned long)[curRequest.receivedData length]);
			DebugLog(VERBOSE_MESSAGES_DATA, @"%@", curRequest.receivedData);
            curRequest.status = DL_URLRequestStatus_Success;
        }
        else 
        {
            DebugLog((VERBOSE_MESSAGES_STATS | VERBOSE_MESSAGES_ERRORS), @"DL_URLServer: failed with response: %ld",  (long)curRequest.statusCode);
			DebugLog(VERBOSE_MESSAGES_DATA ,@"DL_URLServer: Data returned: %@", [[NSString alloc] initWithBytes:[curRequest.receivedData bytes] length:[curRequest.receivedData length] encoding:NSUTF8StringEncoding]);
            curRequest.status = DL_URLRequestStatus_Failure;
        }
        
        // update the system
        //[self queueUpdate];
        [self update];
    }
}

@end
