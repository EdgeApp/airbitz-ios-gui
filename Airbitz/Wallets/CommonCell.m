//
//  CommonCell.m
//  AirBitz
//
//

#import "CommonCell.h"

@interface CommonCell ()
{
    long row;
    long tableHeight;
}

@end

@implementation CommonCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) { }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
//    [self setBackground:selected];
}

//- (void)setInfo:(long)index tableHeight:(long)height
//{
//    row = index;
//    tableHeight = height;
//
//    [self setBackground:NO];
//}
//
//- (void)setBackground:(BOOL)selected
//{
//    if (selected) {
//        if (row == 0) {
//            if (row == tableHeight) {
//                _bkgImage.image = [UIImage imageNamed:@"bd_highlighted_cell_single"];
//            } else {
//                _bkgImage.image = [UIImage imageNamed:@"bd_highlighted_cell_top"];
//            }
//        } else if (row == tableHeight - 1) {
//            _bkgImage.image = [UIImage imageNamed:@"bd_highlighted_cell_bottom"];
//        } else {
//            _bkgImage.image = [UIImage imageNamed:@"bd_highlighted_cell_middle"];
//        }
//    } else {
//        if (row == 0) {
//            if (1 == tableHeight) {
//                _bkgImage.image = [UIImage imageNamed:@"bd_cell_single"];
//            } else {
//                _bkgImage.image = [UIImage imageNamed:@"bd_cell_top"];
//            }
//        } else if (row == tableHeight - 1) {
//            _bkgImage.image = [UIImage imageNamed:@"bd_cell_bottom"];
//        } else {
//            _bkgImage.image = [UIImage imageNamed:@"bd_cell_middle"];
//        }
//    }
//}

@end
