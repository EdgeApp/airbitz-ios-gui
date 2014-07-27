//
//  BackgroundImageManager.m
//
//  Copyright (c) 2014, Airbitz
//  All rights reserved.
//
//  Redistribution and use in source and binary forms are permitted provided that
//  the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//  3. Redistribution or use of modified source code requires the express written
//  permission of Airbitz Inc.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  The views and conclusions contained in the software and documentation are those
//  of the authors and should not be interpreted as representing official policies,
//  either expressed or implied, of the Airbitz Project.
//
//  See AUTHORS for contributing developers
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
	//[DL_URLServer.controller cancelAllRequestsForDelegate:self]; // Note: not sure why this was being done before
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
