//
//  Contact.h
//  AirBitz
//
//  Created by Carson Whitsett on 8/14/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Contact : NSObject

@property (nonatomic, copy)     NSString *strName;
@property (nonatomic, copy)     NSString *strData;
@property (nonatomic, copy)     NSString *strDataLabel;
@property (nonatomic, strong)   UIImage  *imagePhoto;

@end
