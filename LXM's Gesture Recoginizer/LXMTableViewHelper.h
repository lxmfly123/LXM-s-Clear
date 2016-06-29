//
//  LXMTableViewHelper.h
//  LXM's Gesture Recoginizer
//
//  Created by FLY.lxm on 5/4/16.
//  Copyright © 2016 FLY.lxm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LXMTableViewCell.h"

@protocol LXMTableViewHelper <NSObject>

@property (nonatomic, weak) UITableView *tableView;

- (UIColor *)backgroundColorForCell:(__kindof UITableViewCell *)cell;
- (UIColor *)textColorForCell:(__kindof UITableViewCell *)cell;

@end

@interface LXMTableViewHelper : NSObject <LXMTableViewHelper>

@end
