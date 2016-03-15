//
// Created by Paul P on 3/14/16.
// Copyright (c) 2016 Airbitz. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Affiliate : NSObject

- (void) getAffliateURL:(void (^)(NSString *url)) completionHandler
                  error:(void (^)(void)) errorHandler;
@end