//
//  InfoView.h
//
//  See LICENSE for copy, modification, and use permissions
//
//  See AUTHORS for contributing developers
//

#import <UIKit/UIKit.h>

@protocol InfoViewDelegate;

@interface InfoView : UIView


@property (nonatomic, assign) id<InfoViewDelegate> delegate;
@property (nonatomic, strong) NSString *htmlInfoToDisplay;

+ (InfoView *)CreateWithDelegate:(id<InfoViewDelegate>)delegate;
+ (void)CreateWithHTML:(NSString *)strHTML forView:(UIView *)theView;

-(void)enableScrolling:(BOOL)scrollEnabled;

@end


@protocol InfoViewDelegate <NSObject>

@optional
- (void) InfoViewFinished:(InfoView *)infoView;
@required

@optional

@end