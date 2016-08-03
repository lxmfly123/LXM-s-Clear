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

/// 当标记 todo 的操作的全部动画完成时，此通知被发送给当前 table view 的 `LXMTableViewGestureRecoginizer` 的实例。
extern NSString * const LXMOperationCompleteNotification;

typedef NS_ENUM(NSUInteger, LXMTableViewOperationState) {
  LXMTableViewOperationStateNormal, ///< 正常状态，没有任何操作在进行。
  LXMTableViewOperationStateModifying, ///< 正在修改一个 todo 的文字。
  LXMTableViewOperationStateCompleting, ///< 正在（向右拖动）修改一个 todo 的完成状态。
  LXMTableViewOperationStateDeleting, ///< 正在（向左拖动）删除一个 todo。
  LXMTableViewOperationStateAdding, ///< 正在新建一个 todo。
  LXMTableViewOperationStateRearranging, ///< （长按后）正在拖动一个 todo 到某个位置。
  LXMTableViewOperationStateAnimating, ///< 正在执行某些操作完成后的动画，不允许交互。
  LXMTableViewOperationStateAnimating2, ///< 正在执行某些操作完成后的动画，但允许某些交互。
};

@interface LXMTableViewState : NSObject

@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, assign) LXMTableViewOperationState operationState;
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
