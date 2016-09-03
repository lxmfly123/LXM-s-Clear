//
//  LXMTableViewHelper.h
//  LXM's Gesture Recoginizer
//
//  Created by FLY.lxm on 5/4/16.
//  Copyright © 2016 FLY.lxm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class LXMTodoList;

@protocol LXMTableViewHelper

- (UIColor *)backgroundColorForCell:(__kindof UITableViewCell *)cell;
- (UIColor *)textColorForCell:(__kindof UITableViewCell *)cell;

- (UIColor *)colorForRowAtIndexPath:(NSIndexPath *)indexPath;
- (UIColor *)colorForRowAtIndexPath:(NSIndexPath *)indexPath ignoreTodoItem:(BOOL)shouldIgnore;
- (UIColor *)textColorForRowAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface LXMTableViewHelper : NSObject <LXMTableViewHelper>

@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, weak) LXMTodoList *todoList;

+ (instancetype)sharedInstance;

@end
