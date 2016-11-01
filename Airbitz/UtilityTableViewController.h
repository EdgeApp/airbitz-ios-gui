//
//  UtilityTableViewController.h
//  Airbitz
//
//  Created by Paul P on 8/25/16.
//  Copyright © 2016 Airbitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UtilityTableViewController : UITableViewController

@property                                   CGFloat                     cellHeight;
@property (nonatomic, strong)               NSArray                     *arrayImageUrl;
@property (nonatomic, strong)               NSArray                     *arrayImage;
@property (nonatomic, strong)               NSArray                     *arrayTopString;
@property (nonatomic, strong)               NSArray                     *arrayBottomString;
@property (nonatomic, strong)   void                        (^callback)(int selectedIndex);

+ (void)launchUtilityTableViewController:(UIViewController *)viewController
                              cellHeight:(NSUInteger) cellHeight
                            arrayTopText:(NSArray *)arrayTopText
                         arrayBottomText:(NSArray *)arrayBottomText
                          arrayImageUrls:(NSArray *)arrayImageUrls
                              arrayImage:(NSArray *)arrayImage
                                callback:(void (^)(int selectedIndex)) callback;
@end
