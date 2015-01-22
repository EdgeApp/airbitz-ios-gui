//
//  CommonCell.h
//  AirBitz
//

#import <UIKit/UIKit.h>
#import "MontserratLabel.h"
#import "LatoLabel.h"

@interface CommonCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIImageView        *bkgImage;

- (void)setInfo:(int)index tableHeight:(int)height;

@end
