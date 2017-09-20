//
//  UtilityTableViewController.m
//  Airbitz
//
//  Created by Paul P on 8/25/16.
//  Copyright © 2016 Airbitz. All rights reserved.
//

#import "UtilityTableViewController.h"
#import "PluginCell.h"
#import "Theme.h"
#import "UIImageView+AFNetworking.h"
#import "Util.h"

@interface UtilityTableViewController()
{
    UIImage                         *_blankImage;
}


@end

@implementation UtilityTableViewController

+ (void)launchUtilityTableViewController:(UIViewController *)viewController
                              cellHeight:(NSUInteger) cellHeight
                            arrayTopText:(NSArray *)arrayTopText
                         arrayBottomText:(NSArray *)arrayBottomText
                          arrayImageUrls:(NSArray *)arrayImageUrls
                              arrayImage:(NSArray *)arrayImage
                                callback:(void (^)(int selectedIndex)) callback;
{
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
    UtilityTableViewController *utilityTableViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"UtilityTableViewController"];
    
    utilityTableViewController.cellHeight = cellHeight;
    utilityTableViewController.arrayTopString = arrayTopText;
    utilityTableViewController.arrayBottomString = arrayBottomText;
    utilityTableViewController.arrayImageUrl = arrayImageUrls;
    utilityTableViewController.arrayImage = arrayImage;
    utilityTableViewController.callback = callback;
    
    [viewController presentViewController:utilityTableViewController animated:YES completion:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(36, 36), NO, 0.0);
    _blankImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
{
    return self.arrayTopString.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    return self.cellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"PluginCell";
    
    PluginCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[PluginCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.topLabel.text = self.arrayTopString[indexPath.row];
    cell.topLabel.textColor = [Theme Singleton].colorDarkPrimary;
    
    if (self.arrayBottomString && self.arrayBottomString.count >= indexPath.row - 1)
    {
        cell.bottomLabel.text = self.arrayBottomString[indexPath.row];
    }
    
    cell.image.image = _blankImage;
    
    if (self.arrayImage && self.arrayImage.count >= indexPath.row - 1)
    {
        cell.bottomLabel.text = @"";
    }
    else if (self.arrayImageUrl && self.arrayImageUrl.count >= indexPath.row  - 1)
    {
        NSURLRequest *imageRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:self.arrayImageUrl[indexPath.row]]
                                                      cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                                  timeoutInterval:60];
        
        [cell.image setImageWithURLRequest:imageRequest placeholderImage:_blankImage success:nil failure:nil];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.rightImage.hidden = YES;

    return cell;

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.callback)
        self.callback((int) indexPath.row);
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
