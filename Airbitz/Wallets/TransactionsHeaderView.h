//
//  TransactionsHeaderView.h
//  Airbitz
//
//  Created by Paul Puey on 6/12/2016.
//  Copyright (c) 2016 Airbitz. All rights reserved.
//
//  Used as the section headerView for the transactions table in TransactionsViewController.

#import <UIKit/UIKit.h>

@interface TransactionsHeaderView : UITableViewHeaderFooterView

@property(nonatomic, weak) IBOutlet UILabel *titleLabel;
+(TransactionsHeaderView *)CreateWithTitle:(NSString *)title;

@end
