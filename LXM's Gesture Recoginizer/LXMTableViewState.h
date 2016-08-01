//
//  LXMTableViewState.h
//  LXM's Gesture Recoginizer
//
//  Created by FLY.lxm on 5/20/16.
//  Copyright © 2016 FLY.lxm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class LXMTableViewCell;

/// 一个通知的名称，当标记 todo 项的操作的全部动画完成时，被发送给当前 table view 的 `LXMTableViewGestureRecoginizer` 的实例。
extern NSString * const LXMOperationCompleteNotification;

@interface LXMTableViewState : NSObject

@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, strong) LXMTableViewCell *panningCell;
@property (nonatomic, strong) NSMutableArray<LXMTableViewCell *> *floatingCells;
@property (nonatomic, strong) NSMutableArray<LXMTableViewCell *> *bouncingCells;

/// 因为处于竖直移动或者水平弹簧运动中，不可再进行拖动的所有 cell 的 index path。
@property (nonatomic, strong, readonly) NSArray<NSIndexPath *> *uneditableIndexPaths;

/// 新增待办项目时的手势操作进度，取值范围 0~1。
@property (nonatomic, assign) CGFloat addingProgress;

/// 一个不在屏幕上显示的，辅助计算 cell 透视投影时的在屏幕上的显示高度的 view。
@property (nonatomic, strong, readonly) UIView *assistView;

+ (instancetype)sharedInstance;

- (void)resetState;

- (void)saveTableViewLastContentOffsetAndInset;
- (void)recoverTableViewContentOffsetAndInset;

@end
