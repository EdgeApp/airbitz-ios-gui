//
//  InfoPopupView.m
//  Airbitz
//
//  Created by James on 4/13/18.
//  Copyright © 2018 Airbitz. All rights reserved.
//

#import "InfoPopupView.h"
#import "Theme.h"

@interface InfoPopupView ()

@property (nonatomic, strong) UIButton *dismissButton;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *bodyLabel;
@property (nonatomic, strong) UIButton *actionButton;
@property (nonatomic, strong) UIButton *secondaryButton;

@property (nullable, nonatomic, strong) NSString *titleText;
@property (nullable, nonatomic, strong) UIImage *image;
@property (nullable, nonatomic, strong) NSString *bodyText;
@property (nullable, nonatomic, strong) NSString *buttonText;
@property (nullable, copy) void (^buttonAction)();
@property (nullable, nonatomic, strong) NSString *secondaryButtonText;
@property (nullable, copy) void (^secondaryButtonAction)();

@end

@implementation InfoPopupView

#pragma mark Initialization

- (instancetype)initWithTitle:(nullable NSString *)titleText
                        image:(nullable UIImage *)image
                    bodyLabel:(nullable NSString *)bodyText
                   buttonText:(nullable NSString *)buttonText
                 buttonAction:(void(^_Nullable)())buttonAction
{
    self = [super init];
    if (self) {
        self.titleText = titleText;
        self.image = image;
        self.bodyText = bodyText;
        self.buttonText = buttonText;
        self.buttonAction = buttonAction;
        
        [self createViews];
    }
    return self;
}

- (instancetype)initWithTitle:(nullable NSString *)titleText
                        image:(nullable UIImage *)image
                    bodyLabel:(nullable NSString *)bodyText
                   buttonText:(nullable NSString *)buttonText
                 buttonAction:(void(^_Nullable)())buttonAction
          secondaryButtonText:(nullable NSString *)secondaryButtonText
        secondaryButtonAction:(void(^_Nullable)())secondaryButtonAction
{
    self = [super init];
    if (self) {
        self.titleText = titleText;
        self.image = image;
        self.bodyText = bodyText;
        self.buttonText = buttonText;
        self.buttonAction = buttonAction;
        self.secondaryButtonText = secondaryButtonText;
        self.secondaryButtonAction = secondaryButtonAction;
        
        [self createViews];
    }
    return self;
}

- (void)createViews {
    self.translatesAutoresizingMaskIntoConstraints = false;
    self.backgroundColor = [Theme Singleton].colorWhite;
    self.layer.cornerRadius = 10.0;
    self.layer.shadowRadius = 4.0;
    self.layer.shadowOffset = CGSizeMake(0, 0.2);
    self.layer.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.5].CGColor;
    
    [self createDismissButton];
    [self createTitleLabel];
    [self createImageView];
    [self createBodyLabel];
    [self createActionButton];
    
    if (_secondaryButtonText != nil || _secondaryButtonAction != nil) {
        [self createSecondaryButton];
    }
}

- (void)createDismissButton {
    _dismissButton = [[UIButton alloc] initWithFrame:CGRectZero];
    _dismissButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self addSubview:_dismissButton];
    
    [[_dismissButton.topAnchor constraintEqualToAnchor:self.topAnchor constant:20.0] setActive:YES];
    [[_dismissButton.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-20.0] setActive:YES];
    
    [_dismissButton setBackgroundImage:[UIImage imageNamed:@"btn_close"] forState:UIControlStateNormal];
    
    [_dismissButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
}

- (void)createTitleLabel {
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _titleLabel.font = [UIFont fontWithName:[Theme Singleton].appFont size:25.0];
    _titleLabel.textColor = [Theme Singleton].colorDarkGray;
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    
    [self addSubview:_titleLabel];
    
    [[_titleLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:30.0] setActive:YES];
    [[_titleLabel.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:30.0] setActive:YES];
    [[_titleLabel.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-30.0] setActive:YES];
    [_titleLabel setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
    
    if (self.titleText == nil) {
        [[_titleLabel.heightAnchor constraintEqualToConstant:0] setActive:YES];
    } else {
        _titleLabel.text = self.titleText;
    }
}

- (void)createImageView {
    _imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _imageView.translatesAutoresizingMaskIntoConstraints = NO;
    _imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    [self addSubview:_imageView];
    
    [[_imageView.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:20.0] setActive:YES];
    [[_imageView.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:40.0] setActive:YES];
    [[_imageView.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-40.0] setActive:YES];
    
    if (self.image == nil) {
        [[_imageView.heightAnchor constraintEqualToConstant:0] setActive:YES];
    } else {
        _imageView.image = self.image;
    }
}

- (void)createBodyLabel {
    _bodyLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _bodyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _bodyLabel.font = [UIFont fontWithName:[Theme Singleton].appFont size:16.0];
    _bodyLabel.textColor = [Theme Singleton].colorDarkGray;
    _bodyLabel.textAlignment = NSTextAlignmentCenter;
    _bodyLabel.numberOfLines = 0;
    _bodyLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    [self addSubview:_bodyLabel];
    
    [[_bodyLabel.topAnchor constraintEqualToAnchor:self.imageView.bottomAnchor constant:20.0] setActive:YES];
    [[_bodyLabel.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:30.0] setActive:YES];
    [[_bodyLabel.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-30.0] setActive:YES];
    [_bodyLabel setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
    
    if (self.bodyText == nil) {
        [[_bodyLabel.heightAnchor constraintEqualToConstant:0] setActive:YES];
    } else {
        _bodyLabel.text = self.bodyText;
    }
}

- (void)createActionButton {
    _actionButton = [[UIButton alloc] initWithFrame:CGRectZero];
    _actionButton.translatesAutoresizingMaskIntoConstraints = NO;
    _actionButton.titleLabel.font = [UIFont fontWithName:[Theme Singleton].appFont size:18.0];
    _actionButton.backgroundColor = [Theme Singleton].colorFirstAccent;
    
    [self addSubview:_actionButton];
    
    [[_actionButton.topAnchor constraintEqualToAnchor:self.bodyLabel.bottomAnchor constant:30.0] setActive:YES];
    [[_actionButton.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:40.0] setActive:YES];
    [[_actionButton.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-40.0] setActive:YES];
    [[_actionButton.heightAnchor constraintEqualToConstant:40.0] setActive:YES];
    
    if (_secondaryButtonText == nil && _secondaryButtonAction == nil) {
        [[_actionButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-30.0] setActive:YES];
    }
    
    if (self.buttonText == nil) {
        [_actionButton setTitle:@"OK" forState:UIControlStateNormal];
    } else {
        [_actionButton setTitle:self.buttonText forState:UIControlStateNormal];
    }
   
    [_actionButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)createSecondaryButton {
    _secondaryButton = [[UIButton alloc] initWithFrame:CGRectZero];
    _secondaryButton.translatesAutoresizingMaskIntoConstraints = NO;
    _secondaryButton.titleLabel.font = [UIFont fontWithName:[Theme Singleton].appFont size:18.0];
    _secondaryButton.backgroundColor = [Theme Singleton].colorSecondAccent;
    
    [self addSubview:_secondaryButton];
    
    [[_secondaryButton.topAnchor constraintEqualToAnchor:self.actionButton.bottomAnchor constant:10.0] setActive:YES];
    [[_secondaryButton.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:40.0] setActive:YES];
    [[_secondaryButton.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-40.0] setActive:YES];
    [[_secondaryButton.heightAnchor constraintEqualToConstant:40.0] setActive:YES];
    
    [[_secondaryButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-30.0] setActive:YES];
    
    if (self.secondaryButtonText == nil) {
        [_secondaryButton setTitle:@"Cancel" forState:UIControlStateNormal];
    } else {
        [_secondaryButton setTitle:self.secondaryButtonText forState:UIControlStateNormal];
    }
    
    [_secondaryButton addTarget:self action:@selector(secondaryButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark Action

- (void)show:(UIView *)parentView {
    [parentView addSubview:self];
    
    [[self.widthAnchor constraintEqualToAnchor:parentView.widthAnchor constant:-40.0] setActive:YES];
    [[self.centerXAnchor constraintEqualToAnchor:parentView.centerXAnchor] setActive:YES];
    NSLayoutConstraint *centerYConstraint = [self.centerYAnchor constraintEqualToAnchor:parentView.centerYAnchor constant:parentView.frame.size.height];
    
    [centerYConstraint setActive:YES];
    
    [parentView layoutIfNeeded];
    
    [UIView animateWithDuration:0.5
                          delay:0
         usingSpringWithDamping:0.7
          initialSpringVelocity:4
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         centerYConstraint.constant = 0;
                         [parentView layoutIfNeeded];
                     } completion:^(BOOL finished) {
                         
                     }];
}

- (void)buttonPressed:(id)sender {
    if (self.buttonAction == nil) {
        [self dismiss];
    } else {
        self.buttonAction();
    }
}

- (void)secondaryButtonPressed:(id)sender {
    if (self.secondaryButtonAction == nil) {
        [self dismiss];
    } else {
        self.secondaryButtonAction();
    }
}

- (void)dismiss {
    CGRect newFrame = self.frame;
    newFrame.origin.y = [[UIApplication sharedApplication] keyWindow].bounds.size.height + 200.0;
    
    [UIView animateWithDuration:0.7
                          delay:0
         usingSpringWithDamping:0.4
          initialSpringVelocity:4
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.frame = newFrame;
                     } completion:^(BOOL finished) {
                         [self removeFromSuperview];
                     }];
}

@end
