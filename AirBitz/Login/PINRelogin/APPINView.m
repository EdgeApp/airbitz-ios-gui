// The MIT License (MIT)
//
// Copyright (c) 2013 Alterplay
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
// the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "APPINView.h"

@interface APPINView () {
    NSArray *_PINViewsArray;
    UITextField *_fakeTextField;
}
@property (nonatomic, readonly, getter = isInitialized) BOOL initialized;
@end

@implementation APPINView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    if (!self.isInitialized) {
        // You can freely use background color in XIBs
        self.backgroundColor = [UIColor clearColor];
        
        _normalPINImage = [UIImage imageNamed:@"large-digit-input"];
        _selectedPINImage = [UIImage imageNamed:@"large-digit-input_selected"];
        
        // Fake text field
        _fakeTextField = [[UITextField alloc] initWithFrame:CGRectZero];
        _fakeTextField.keyboardType = UIKeyboardTypeNumberPad;
        [_fakeTextField addTarget:self action:@selector(textFieldTextChanged:)
                 forControlEvents:UIControlEventEditingChanged];
        [self addSubview:_fakeTextField];
    
        // Build PIN
        [self buildPIN];
        
        // Tap gesture
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                     action:@selector(tapGestureOccured:)];
        [self addGestureRecognizer:tapGesture];
        
        _initialized = YES;
    }
}

#pragma mark - Build View
- (void)buildPIN {
    // Remove old PIN
    [_PINViewsArray makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    CGFloat width = self.bounds.size.width;
    CGFloat itemWidth = floor(width / (CGFloat)kDefinedPINCount);
    
    // Add PINcodes
    NSMutableArray *PINCodesContainer = [NSMutableArray new];
    for (NSInteger i = 0;i < kDefinedPINCount; i++) {
        UIImageView *PINImageView = [[UIImageView alloc] initWithFrame:CGRectMake(i * itemWidth,
                                                                                  0.0f,
                                                                                  itemWidth,
                                                                                  self.bounds.size.height)];
        PINImageView.image = _normalPINImage;
        PINImageView.highlightedImage = _selectedPINImage;
        PINImageView.contentMode = UIViewContentModeCenter;
        PINImageView.autoresizingMask =
        UIViewAutoresizingFlexibleWidth
        | UIViewAutoresizingFlexibleHeight
        | UIViewAutoresizingFlexibleLeftMargin
        | UIViewAutoresizingFlexibleRightMargin;
        
        [self addSubview:PINImageView];
        
        [PINCodesContainer addObject:PINImageView];
    }
    _PINViewsArray = [PINCodesContainer copy];
}

#pragma mark - Images
- (void)setNormalPINImage:(UIImage *)normalPINImage {
    _normalPINImage = normalPINImage;
    
    // Set normal image
    [_PINViewsArray makeObjectsPerformSelector:@selector(setImage:)
                                    withObject:normalPINImage];
}

- (void)setSelectedPINImage:(UIImage *)selectedPINImage {
    _selectedPINImage = selectedPINImage;
    
    // Set selected image
    [_PINViewsArray makeObjectsPerformSelector:@selector(setHighlightedImage:)
                                    withObject:selectedPINImage];
}

#pragma mark - Responder
- (BOOL)becomeFirstResponder {
    [_fakeTextField becomeFirstResponder];
    return NO;
}

- (BOOL)resignFirstResponder {
    [_fakeTextField resignFirstResponder];
    return NO;
}

#pragma mark - UITextField
- (void)textFieldTextChanged:(UITextField *)textField {
    // Trimmed text
    textField.text = [self trimmedStringWithMaxLenght:textField.text];
    
    _PINCode = textField.text;
    
    // Colorize PIN
    [self colorizePIN];
    
    // Notify delegate if needed
    [self checkForEnteredPIN];
}

- (void)setPINCode:(NSString *)PINCode {
    // Trimmed text
    NSString *enteredCode = [self trimmedStringWithMaxLenght:PINCode];
    
    _PINCode = enteredCode;
    _fakeTextField.text = enteredCode;
    
    // Colorize PIN
    [self colorizePIN];
    
    // Notify delegate if needed
    [self checkForEnteredPIN];
}

#pragma mark - ColorizeViews
- (void)colorizePIN {
    NSInteger PINEntered = self.PINCode.length;
    NSInteger itemsCount = _PINViewsArray.count;
    for (NSInteger i = 0; i < itemsCount; i++) {
        UIImageView *PINImageView = _PINViewsArray[i];
        PINImageView.highlighted = i < PINEntered;
    }
}

#pragma mark - Delegate
- (void)checkForEnteredPIN {
    if (self.PINCode.length == kDefinedPINCount) {
        if ([self.delegate respondsToSelector:@selector(PINCodeView:didEnterPIN:)]) {
            [self.delegate PINCodeView:self didEnterPIN:self.PINCode];
        }
    }
}

#pragma mark - Gestures
- (void)tapGestureOccured:(UITapGestureRecognizer *)tapGesture {
    [self becomeFirstResponder];
}

#pragma mark - Helpers
- (NSString *)trimmedStringWithMaxLenght:(NSString *)sourceString {
    if (sourceString.length > kDefinedPINCount) {
        sourceString = [sourceString substringToIndex:kDefinedPINCount];
    }
    return sourceString;
}

@end
