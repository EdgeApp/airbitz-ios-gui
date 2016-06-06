//
//  UIPhotoGalleryView.m
//  PhotoGallery
//
//  Created by Ethan Nguyen on 5/23/13.
//  Copyright (c) 2013 Ethan Nguyen. All rights reserved.
//

#import "UIPhotoGalleryView.h"
#import "UIPhotoItemView.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "CommonTypes.h"
#import "Theme.h"

#define kDefaultSubviewGap              30
#define kMaxSpareViews                  1

@interface UIPhotoGalleryView ()
{
    NSURL *remoteImage;
    NSTimer *bgTimer;
}

- (void)initDefaults;
- (void)initMainScrollView;
- (void)setupMainScrollView;
- (BOOL)reusableViewsContainViewAtIndex:(NSInteger)index;
- (void)populateSubviews;
- (UIPhotoContainerView*)viewToBeAddedWithFrame:(CGRect)frame atIndex:(NSInteger)index;

- (void)setupScrollIndicator;
- (UIImage*)scrollIndicatorForDirection:(BOOL)vertical andLength:(CGFloat)length;

@end

@implementation UIPhotoGalleryView

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.autoresizingMask =
        UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin |
        UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.autoresizingMask =
        UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin |
        UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [self initDefaults];
        [self initMainScrollView];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self initDefaults];
    [self initMainScrollView];
}

- (void)layoutSubviews {
    [self setupMainScrollView];
}

#pragma get-set methods
- (void)setGalleryMode:(UIPhotoGalleryMode)galleryMode {
    _galleryMode = galleryMode;
    currentPage = 0;
    [self layoutSubviews];
}

- (void)setCaptionStyle:(UIPhotoCaptionStyle)captionStyle {
    _captionStyle = captionStyle;
    [self layoutSubviews];
}

- (void)setCircleScroll:(BOOL)circleScroll {
    _circleScroll = circleScroll;
}

- (void)setPeakSubView:(BOOL)peakSubView {
    _peakSubView = peakSubView;
    mainScrollView.clipsToBounds = _peakSubView;
}

- (void)setShowsScrollIndicator:(BOOL)showsScrollIndicator {
    _showsScrollIndicator = showsScrollIndicator;
    
    if (_showsScrollIndicator)
        [self setupScrollIndicator];
}

- (void)setVerticalGallery:(BOOL)verticalGallery {
    _verticalGallery = verticalGallery;
    [self setSubviewGap:_subviewGap];
    [self setInitialIndex:_initialIndex];
}

- (void)setSubviewGap:(CGFloat)subviewGap {
    _subviewGap = subviewGap;
    
    CGRect frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    
    if (_verticalGallery)
        frame.size.height += _subviewGap;
    else
        frame.size.width += _subviewGap;
    
    mainScrollView.frame = frame;
    mainScrollView.contentSize = frame.size;
}

- (void)setInitialIndex:(NSInteger)initialIndex {
    [self setInitialIndex:initialIndex animated:NO];
}

- (void)setInitialIndex:(NSInteger)initialIndex animated:(BOOL)animation {
    _initialIndex = initialIndex;
    currentPage = _initialIndex;
    
    [self scrollToPage:currentPage animated:animation];
}

- (NSInteger)currentIndex {
    return currentPage;
}

#pragma public methods
- (BOOL)scrollToPage:(NSInteger)page animated:(BOOL)animation {
    if (page < 0 || page >= dataSourceNumOfViews)
        return NO;
    
    currentPage = page;
    [self populateSubviews];
    
    CGPoint contentOffset = mainScrollView.contentOffset;
    
    if (_verticalGallery)
        contentOffset.y = currentPage * mainScrollView.frame.size.height;
    else
        contentOffset.x = currentPage * mainScrollView.frame.size.width;
    
    float duration = animation ? [Theme Singleton].animationDurationTimeDefault : 0.0;
    [UIView animateWithDuration:duration
                     animations:^
    {
        mainScrollView.contentOffset = contentOffset;
    } completion:^(BOOL finished)
    {
        [self queueBackgroundSetup];
    }];
    
    return YES;
}

- (BOOL)scrollToBesidePage:(NSInteger)delta animated:(BOOL)animation {
    return [self scrollToPage:currentPage+delta animated:animation];
}

- (UIView *)getCurrentView {
    for (UIView *subView in mainScrollView.subviews)
        if ([subView isKindOfClass:[UIPhotoContainerView class]] && subView.tag == currentPage)
            return subView;
    
    return nil;
}

#pragma UIScrollViewDelegate methods
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat newPage;
    CGFloat scrollIndicatorMoveSpace = 0;
    
    CGRect frame = mainScrollIndicatorView.frame;
    
    if (_verticalGallery) {
        newPage = scrollView.contentOffset.y / scrollView.frame.size.height;
        scrollIndicatorMoveSpace = (dataSourceNumOfViews == 1) ? 0 : (self.frame.size.height - mainScrollIndicatorView.frame.size.height)/(dataSourceNumOfViews-1);
        frame.origin.y = newPage*scrollIndicatorMoveSpace;
    } else {
        newPage = scrollView.contentOffset.x / scrollView.frame.size.width;
        scrollIndicatorMoveSpace = (dataSourceNumOfViews == 1) ? 0 : (self.frame.size.width - mainScrollIndicatorView.frame.size.width)/(dataSourceNumOfViews-1);
        frame.origin.x = newPage*scrollIndicatorMoveSpace;
    }
    
    mainScrollIndicatorView.frame = frame;
    
    BOOL settled = newPage == floor(newPage);
    if (((NSInteger)newPage) != currentPage && settled) {
        currentPage = (NSInteger)newPage;
        [self populateSubviews];
        
        for (UIPhotoContainerView *subView in reusableViews) {
            if (subView.tag != newPage) {
                [subView resetZoom];
            }
        }
    }
    
    if ([_delegate respondsToSelector:@selector(scrollViewDidScroll:)])
        [_delegate scrollViewDidScroll:scrollView];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    mainScrollIndicatorView.tag = 1;
    [UIView animateWithDuration:[Theme Singleton].animationDurationTimeDefault
                     animations:^{
        mainScrollIndicatorView.alpha = 1;
    }];
    
    if ([_delegate respondsToSelector:@selector(scrollViewWillBeginDragging:)])
        [_delegate scrollViewWillBeginDragging:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (decelerate)
        return;
    
    [self scrollViewDidEndDecelerating:scrollView];
    
    if ([_delegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)])
        [_delegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if ([_delegate respondsToSelector:@selector(photoGallery:didMoveToIndex:)])
        [_delegate photoGallery:self didMoveToIndex:currentPage];

    [self queueBackgroundSetup];
    
    mainScrollIndicatorView.tag = 0;

    double delayInSeconds = 2.0;
    dispatch_time_t popTime2 = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime2, dispatch_get_main_queue(), ^(void){
        if (mainScrollIndicatorView.tag == 0) {
            [UIView animateWithDuration:[Theme Singleton].animationDurationTimeDefault animations:^{
                mainScrollIndicatorView.alpha = 0;
            }];
        }
    });
}

#pragma private methods
- (void)initDefaults {
    _photoItemContentMode = UIViewContentModeScaleAspectFill;
    _galleryMode = UIPhotoGalleryModeImageLocal;
    _captionStyle = UIPhotoCaptionStylePlainText;
    _subviewGap = kDefaultSubviewGap;
    _peakSubView = NO;
    _showsScrollIndicator = YES;
    _verticalGallery = NO;
    _showBlurredPhotoBG = NO;
    _initialIndex = 0;
    currentPage = 0;
    remoteImage = nil;
}

- (void)initMainScrollView {
    CGRect frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    
    if (_verticalGallery)
        frame.size.height += _subviewGap;
    else
        frame.size.width += _subviewGap;
    
    [mainScrollView removeFromSuperview];
    
    mainScrollView = [[UIScrollView alloc] initWithFrame:frame];
    mainScrollView.autoresizingMask = self.autoresizingMask;
    mainScrollView.backgroundColor = [UIColor clearColor];
    mainScrollView.clipsToBounds = YES;
    mainScrollView.contentSize = frame.size;
    mainScrollView.delegate = self;
    mainScrollView.pagingEnabled = YES;
    mainScrollView.showsHorizontalScrollIndicator = mainScrollView.showsVerticalScrollIndicator = NO;
    mainScrollView.bounces = NO;
    
    [self addSubview:mainScrollView];
    
    reusableViews = [NSMutableSet set];
}

- (void)setupMainScrollView {
    NSAssert(_dataSource != nil, @"Missing dataSource");
    NSAssert([_dataSource respondsToSelector:@selector(numberOfViewsInPhotoGallery:)],
             @"Missing dataSource method numberOfViewsInPhotoGallery:");
    
    switch (_galleryMode) {
        case UIPhotoGalleryModeImageLocal:
            NSAssert([_dataSource respondsToSelector:@selector(photoGallery:localImageAtIndex:)],
                     @"UIPhotoGalleryModeImageLocal mode missing dataSource method photoGallery:localImageAtIndex:");
            break;
            
        case UIPhotoGalleryModeImageRemote:
            NSAssert([_dataSource respondsToSelector:@selector(photoGallery:remoteImageURLAtIndex:)],
                     @"UIPhotoGalleryModeImageRemote mode missing dataSource method photoGallery:remoteImageURLAtIndex:");
            break;
            
        case UIPhotoGalleryModeCustomView:
            NSAssert([_dataSource respondsToSelector:@selector(photoGallery:customViewAtIndex:)],
                     @"UIPhotoGalleryModeCustomView mode missing dataSource method photoGallery:viewAtIndex:");
            break;
            
        default:
            break;
    }
    
    [self initMainScrollView];
    
    dataSourceNumOfViews = [_dataSource numberOfViewsInPhotoGallery:self];
    
    NSInteger tmpCurrentPage = currentPage;
    
    [self setSubviewGap:_subviewGap];
    
    CGSize contentSize = mainScrollView.contentSize;
    
    if (_verticalGallery)
        contentSize.height = mainScrollView.frame.size.height * dataSourceNumOfViews;
    else
        contentSize.width = mainScrollView.frame.size.width * dataSourceNumOfViews;
    
    mainScrollView.contentSize = contentSize;
    
    for (UIView *view in mainScrollView.subviews)
        if ([view isMemberOfClass:[UIPhotoContainerView class]])
            [view removeFromSuperview];
    
    [reusableViews removeAllObjects];
    
    [self scrollToPage:tmpCurrentPage animated:NO];
    [self setupScrollIndicator];
}

- (BOOL)reusableViewsContainViewAtIndex:(NSInteger)index {
    for (UIView *view in reusableViews)
        if (view.tag == index)
            return YES;
    
    return NO;
}

- (UIView *)getReusableViewAtIndex:(NSInteger)index {
    for (UIView *view in reusableViews)
        if (view.tag == index)
            return view;
    return nil;
}

- (void)populateSubviews {
    NSMutableSet *toRemovedViews = [NSMutableSet set];
    
    for (UIView *view in reusableViews)
        if (view.tag < currentPage - kMaxSpareViews || view.tag > currentPage + kMaxSpareViews) {
            [toRemovedViews addObject:view];
            [view removeFromSuperview];
        }
    
    [reusableViews minusSet:toRemovedViews];
    
    for (NSInteger index = -kMaxSpareViews; index <= kMaxSpareViews; index++) {
        NSInteger assertIndex = currentPage + index;
        if (assertIndex < 0 || assertIndex >= dataSourceNumOfViews ||
            [self reusableViewsContainViewAtIndex:assertIndex])
            continue;
        
        CGRect frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        
        if (_verticalGallery)
            frame.origin.y = assertIndex * mainScrollView.frame.size.height;
        else
            frame.origin.x = assertIndex * mainScrollView.frame.size.width;
        
        UIPhotoContainerView *subView = [self viewToBeAddedWithFrame:frame atIndex:currentPage+index];

        if (subView) {
            [subView resetZoom];
            [subView resetOptions];
            [mainScrollView addSubview:subView];
            [reusableViews addObject:subView];
        }
    }
}

- (void)queueBackgroundSetup
{
    if (bgTimer) {
        [bgTimer invalidate];
    }
    bgTimer = [NSTimer scheduledTimerWithTimeInterval:0.20
        target:self
        selector:@selector(setupBackgroundView)
        userInfo:nil
        repeats:NO];
}

- (void)setupBackgroundView
{
    if (_showBlurredPhotoBG)
    {
        if (nil == _backgroundImage)
        {
            _backgroundImage = [[UIImageView alloc] initWithFrame:self.frame];
            _backgroundImage.contentMode = UIViewContentModeScaleAspectFill;
            _backgroundImage.clipsToBounds = YES;
            [self addSubview:_backgroundImage];
            [self sendSubviewToBack:_backgroundImage];
        }
        if (nil == _transitionalBgImage)
        {
            _transitionalBgImage = [[UIImageView alloc] initWithFrame:self.frame];
            _transitionalBgImage.contentMode = UIViewContentModeScaleAspectFill;
            _transitionalBgImage.clipsToBounds = YES;
            [self addSubview:_transitionalBgImage];
            [self sendSubviewToBack:_transitionalBgImage];
        }
        if (_backgroundImage.image) {
            _transitionalBgImage.image = _backgroundImage.image;
        }
        _transitionalBgImage.alpha = 1.0;
        _backgroundImage.alpha = 0.0;

        if (UIPhotoGalleryModeImageLocal == _galleryMode)
        {
            UIPhotoItemView *view = (UIPhotoItemView *)[self getReusableViewAtIndex:currentPage];
            if (view)
            {
                UIImage *image = [view getBackgroundImage];
                if (image)
                {
                    [self blurImage:image forURL:nil];
                    [self tweenBgImages];
                }
            }
        }
        else if (UIPhotoGalleryModeImageRemote == _galleryMode)
        {
            remoteImage = [_dataSource photoGallery:self remoteImageURLAtIndex:currentPage];
            if (remoteImage)
            {
                SDWebImageManager *manager = [SDWebImageManager sharedManager];
                [manager downloadImageWithURL:remoteImage
                                      options:0
                                     progress:nil
                                    completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                    if (!error && image) {
                        [self blurImage:image forURL:imageURL];
                    }
                }];
            }
        }
    }
}

- (void)blurImage:(UIImage *)image forURL:(NSURL *)url
{
    NSString *cacheKey = [NSString stringWithFormat:@"%@_cached", url];
    UIImage *cachedImage = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:cacheKey];
    if (cachedImage) {
        [_backgroundImage setImage:cachedImage];
        [self tweenBgImages];
    }
    [[SDImageCache sharedImageCache] queryDiskCacheForKey:cacheKey done:^(UIImage *cachedImage, SDImageCacheType type)
    {
        if (!cachedImage) {
            CIContext *context = [CIContext contextWithOptions:nil];
            CIImage *inputImage = [CIImage imageWithCGImage:image.CGImage];
            
            //setting up Gaussian Blur (we could use one of many filters offered by Core Image)
            CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
            [filter setValue:inputImage forKey:kCIInputImageKey];
            [filter setValue:[NSNumber numberWithFloat:10.0f] forKey:@"inputRadius"];
            CIImage *result = [filter valueForKey:kCIOutputImageKey];
            //CIGaussianBlur has a tendency to shrink the image a little, this ensures it matches up exactly to the bounds of our original image
            CGImageRef cgImage = [context createCGImage:result fromRect:[inputImage extent]];

            UIImage *blurred = [UIImage imageWithCGImage:cgImage];
            [[SDImageCache sharedImageCache] storeImage:blurred forKey:cacheKey];
            cachedImage = blurred;
        }
        [_backgroundImage setImage:cachedImage];
        [self tweenBgImages];
    }];
}

- (void)tweenBgImages
{
    [UIView animateWithDuration:[Theme Singleton].animationDurationTimeDefault animations:^{
        _backgroundImage.alpha = 1.0;
    }];
}

- (UIPhotoContainerView*)viewToBeAddedWithFrame:(CGRect)frame atIndex:(NSInteger)index {
    UIPhotoContainerView *subView = nil;
    id galleryItem = nil;
    
    switch (_galleryMode) {
        case UIPhotoGalleryModeImageLocal:
            galleryItem = [_dataSource photoGallery:self localImageAtIndex:index];
            break;
            
        case UIPhotoGalleryModeImageRemote:
            galleryItem = [_dataSource photoGallery:self remoteImageURLAtIndex:index];
            break;
            
        default:
            galleryItem = [_dataSource photoGallery:self customViewAtIndex:index];
            break;
    }
    
    if (!galleryItem)
        return nil;
    
    subView = [[UIPhotoContainerView alloc] initWithFrame:frame andGalleryMode:_galleryMode withItem:galleryItem];
    subView.tag = index;
    subView.galleryDelegate = self;

    if (!subView)
        return nil;
    
    id captionItem = nil;
    
    switch (_captionStyle) {
        case UIPhotoCaptionStylePlainText:
            if ([_dataSource respondsToSelector:@selector(photoGallery:plainTextCaptionAtIndex:)])
                captionItem = [_dataSource photoGallery:self plainTextCaptionAtIndex:index];
            
            break;
            
        case UIPhotoCaptionStyleAttributedText:
            if ([_dataSource respondsToSelector:@selector(photoGallery:attributedTextCaptionAtIndex:)])
                captionItem = [_dataSource photoGallery:self attributedTextCaptionAtIndex:index];
            
            break;
            
        default:
            if ([_dataSource respondsToSelector:@selector(photoGallery:customViewAtIndex:)])
                captionItem = [_dataSource photoGallery:self customViewCaptionAtIndex:index];
            
            break;
    }
    
    if (captionItem)
        [subView setCaptionWithStyle:_captionStyle andItem:captionItem];
    
    return subView;
}

- (void)setupScrollIndicator {
    [mainScrollIndicatorView removeFromSuperview];
    
    if (!_showsScrollIndicator)
        return;
    
    CGFloat scrollIndicatorLength = 0;
    
    if (_verticalGallery)
        scrollIndicatorLength = self.frame.size.height / dataSourceNumOfViews;
    else
        scrollIndicatorLength = self.frame.size.width / dataSourceNumOfViews;
    
    UIImage *scrollIndicator = [self scrollIndicatorForDirection:_verticalGallery andLength:scrollIndicatorLength];
    
    mainScrollIndicatorView = [[UIImageView alloc] initWithImage:scrollIndicator];
    
    CGRect frame = mainScrollIndicatorView.frame;
    
    if (_verticalGallery) {
        frame.origin.x = self.frame.size.width-frame.size.width;
        frame.origin.y = 0;
    } else {
        frame.origin.x = 0;
        frame.origin.y = self.frame.size.height-frame.size.height;
    }
    
    mainScrollIndicatorView.frame = frame;
    mainScrollIndicatorView.alpha = 0;
    [self addSubview:mainScrollIndicatorView];
}

- (UIImage*)scrollIndicatorForDirection:(BOOL)vertical andLength:(CGFloat)length {
    CGFloat radius = 3.5;
    CGFloat ratio = 1.5*length/radius;
    
    if (ratio < 2.5)
        ratio = 2.5;
    
    CGSize size = CGSizeMake(radius*2*(vertical ?: ratio), radius*2*(vertical*ratio ?: 1));
    CGFloat lineWidth = 0.5;
    
    UIGraphicsBeginImageContext(size);
	CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, lineWidth);
    CGContextSetAlpha(context, 0.8);
    
    CGContextBeginPath(context);
    CGContextAddArc(context, radius, radius, radius-lineWidth,
                    -M_PI_2 - M_PI_2*vertical, M_PI_2 - M_PI_2*vertical, !vertical);
    CGContextAddArc(context, size.width-radius, size.height-radius, radius-lineWidth,
                    M_PI_2 - M_PI_2*vertical, -M_PI_2 - M_PI_2*vertical, !vertical);
    CGContextClosePath(context);
    
    [[UIColor grayColor] set];
    CGContextStrokePath(context);
	UIImage *scrollIndicator = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return scrollIndicator;
}

@end
