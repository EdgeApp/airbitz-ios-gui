//
//  BD_Social_Cell.m
//  AirBitz
//
//  Created by Allan Wright on 10/27/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "BD_Social_Cell.h"

static NSDictionary *_socialTypeAsEnum;
static NSDictionary *_socialTypeImages;
static NSDictionary *_socialTypeAsString;

@implementation BD_Social_Cell

/*
 * define all static data
 */
+ (void)initialize {
    if (self == [BD_Social_Cell class])
    {
        _socialTypeAsEnum = @{
            @"facebook" : [NSNumber numberWithInt:kFacebook],
            @"twitter" : [NSNumber numberWithInt:kTwitter],
            @"foursquare" : [NSNumber numberWithInt:kFoursquare],
            @"yelp" : [NSNumber numberWithInt:kYelp]
        };
        _socialTypeImages = @{
            [NSNumber numberWithInt:kFacebook] : [UIImage imageNamed:@"bd_icon_facebook"],
            [NSNumber numberWithInt:kTwitter] : [UIImage imageNamed:@"bd_icon_twitter"],
            [NSNumber numberWithInt:kFoursquare] : [UIImage imageNamed:@"bd_icon_foursquare"],
            [NSNumber numberWithInt:kYelp] : [UIImage imageNamed:@"bd_icon_yelp"],
        };
        _socialTypeAsString = @{
            [NSNumber numberWithInt:kFacebook] : @"Facebook",
            [NSNumber numberWithInt:kTwitter] : @"Twitter",
            [NSNumber numberWithInt:kFoursquare] : @"Foursquare",
            [NSNumber numberWithInt:kYelp] : @"Yelp",
        };
    }
}

/*
 * Return the enum version of the social media type as an NSNumber
 * NSString *type : String version of the social media type
 */
+ (NSNumber *)getSocialTypeAsEnum:(NSString *)type
{
    NSStringCompareOptions options = NSCaseInsensitiveSearch;
    for (NSString *social in _socialTypeAsEnum)
    {
        if (NSOrderedSame == [type compare:social options:options])
        {
            return (NSNumber *)[_socialTypeAsEnum objectForKey:[type lowercaseString]];
        }
    }
    return [NSNumber numberWithInt:kNull];
}

/*
 * Return the string version of the social media type. Suitable for display to user.
 * NSNumber *type : Enum version of the social media type as an NSNumber
 */
+ (NSString *)getSocialTypeAsString:(NSNumber *)type;
{
    return [_socialTypeAsString objectForKey:type];
}

/*
 * Return the image associated with the social media type
 * SocialType social : Enum version of the social media type
 */
+ (UIImage *)getSocialTypeImage:(NSNumber *)type
{
    return [_socialTypeImages objectForKey:type];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
