//
//  LXMTableViewCell.h
//  LXM's Gesture Recoginizer
//
//  Created by FLY.lxm on 4/9/16.
//  Copyright © 2016 FLY.lxm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LXMTodoItem.h"
#import "LXMTableViewState.h"
#import "LXMStrikeThroughText.h"

@class LXMTableViewCell;

@protocol LXMTableViewCellDelegate <NSObject>

- (BOOL)tableViewCellShouldBeginTextEditing:(LXMTableViewCell *)cell;
- (void)tableViewCellDidBeginTextEditing:(LXMTableViewCell *)cell;
- (BOOL)tableViewCellShouldEndTextEditing:(LXMTableViewCell *)cell;
- (void)tableViewCellDidEndTextEditing:(LXMTableViewCell *)cell;

@end

@interface LXMTableViewCell : UITableViewCell

@property (nonatomic, strong) LXMTodoItem *todoItem;
@property (nonatomic, strong) UIView *actualContentView;
@property (nonatomic, strong) UIColor *targetColor;
@property (nonatomic, assign) LXMTableViewCellEditingState editingState;
@property (nonatomic, weak) id <LXMTableViewCellDelegate> delegate;
@property (nonatomic, strong) LXMStrikeThroughText *strikeThroughText;

- (void)recoverCellAfterEdit;
//- (void)saveLastStates;
//- (void)updateViewBackgroundColorWithPercentage:(CGFloat)percentage;

@end
