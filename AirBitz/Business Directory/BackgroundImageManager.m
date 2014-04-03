//
//  BackgroundImageManager.m
//  AirBitz
//
//  Created by Carson Whitsett on 2/16/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "BackgroundImageManager.h"
#import "DL_URLServer.h"
#import "Server.h"
#import "UIImage+Colorize.h"

@interface BackgroundImageManager () <DL_URLRequestDelegate>
{
	NSMutableDictionary *images;
}

@end

@implementation BackgroundImageManager

-(id)init
{
	self = [super init];
	if(self)
	{
		images = [[NSMutableDictionary alloc] init];
	}
	return self;
}

-(void)dealloc
{
	images = nil;
}

-(void)loadImageForBusiness:(NSDictionary *)business
{
	NSDictionary *imageInfo = [business objectForKey:@"profile_image"];
	[DL_URLServer cancelPreviousPerformRequestsWithTarget:self];
	if(imageInfo)
	{
		if(imageInfo.count)
		{
			NSString *imageURL = [imageInfo objectForKey:@"thumbnail"];
			//NSLog(@"imageURL: %@", imageURL);
			NSString *requestURL = [NSString stringWithFormat:@"%@%@", SERVER_URL, imageURL];
			//NSLog(@"Requesting: %@ for row: %i", requestURL, row);
			[[DL_URLServer controller] issueRequestURL:requestURL
											withParams:nil
											withObject:[business objectForKey:@"bizId"]
										  withDelegate:self
									acceptableCacheAge:CACHE_24_HOURS
										   cacheResult:YES];
		}
		else
		{
			NSLog(@"No image for %@", [business objectForKey:@"name"]);
		}
	}
}

-(UIImage *)imageForBusiness:(NSDictionary *)business
{
	UIImage *image = [images objectForKey:[business objectForKey:@"bizId"]];
	//NSLog(@"Image %f, %f for row: %i", image.size.width, image.size.height, row);
	return image;
}

-(UIImage *)darkImageForBusiness:(NSDictionary *)business
{
	UIImage *image = [UIImage colorizeImage:[images objectForKey:[business objectForKey:@"bizId"]] withColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.4]];
	return image;
}

-(void)removeImageForBusiness:(NSDictionary *)business
{
	[images removeObjectForKey:[business objectForKey:@"bizId"]];
}

-(void)removeAllImages
{
	[images removeAllObjects];
}

#pragma mark - DLURLServer Callbacks

- (void)onDL_URLRequestCompleteWithStatus:(tDL_URLRequestStatus)status resultData:(NSData *)data resultObj:(id)object
{
	if(data)
	{
        if (DL_URLRequestStatus_Success == status)
        {
			//UIImageView *imageView = (UIImageView *)self.backgroundView;
			//imageView.image = [self darkenImage:[UIImage imageWithData:data] toLevel:0.5];
			//imageView.image = [UIImage imageWithData:data];
			[images setObject:[UIImage imageWithData:data] forKey:object];
			if([self.delegate respondsToSelector:@selector(BackgroundImageManagerImageLoadedForBizID:)])
			{
				[self.delegate BackgroundImageManagerImageLoadedForBizID:object];
			}
		}
    }
}

-(NSString *)description
{
	return [NSString stringWithFormat:@"Images: %@", images];
}

@end
