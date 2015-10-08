//
//  AnnotationContentView.h
//  AirBitz
//
//  Created by Carson Whitsett on 2/23/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AnnotationContentView : UIView

@property (nonatomic, weak) IBOutlet UIImageView *bkg_image;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *subtitleLabel;

+ (AnnotationContentView *)Create;

@end
