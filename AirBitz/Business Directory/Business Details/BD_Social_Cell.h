//
//  BD_Social_Cell.h
//  AirBitz
//
//  Created by Allan Wright on 10/27/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

typedef NS_ENUM(NSUInteger, SocialType) {
    kFacebook,
    kTwitter,
    kFoursquare,
    kYelp,
    kNull
};

@interface BD_Social_Cell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *socialLabel;
@property (nonatomic, weak) IBOutlet UIImageView *socialIcon;
@property (nonatomic, weak) IBOutlet UIImageView *bkg_image;

+ (NSNumber *)getSocialTypeAsEnum:(NSString *)type;
+ (NSString *)getSocialTypeAsString:(NSNumber *)type;
+ (UIImage *)getSocialTypeImage:(NSNumber *)type;

@end
