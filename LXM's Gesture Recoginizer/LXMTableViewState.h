//
//  LXMTableViewState.h
//  LXM's Gesture Recoginizer
//
//  Created by FLY.lxm on 5/20/16.
//  Copyright © 2016 FLY.lxm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LXMTodoItem.h"
#import "LXMTableViewOperationState.h"
#import "LXMGlobalSettings.h"

@class LXMTableViewCell;
@class LXMTransformableTableViewCell;
@class LXMTodoList;
@class LXMTableViewGestureRecognizer;
@class LXMTableViewGestureRecognizerHelper;
@class LXMTableViewHelper;

extern NSString * const LXMOperationCompleteNotification; ///< 当标记 todo 的操作的全部动画完成时，此通知被发送给当前 table view 的 `LXMTableViewGestureRecognizer` 的实例。

//typedef NS_ENUM(NSUInteger, LXMTableViewOperationStateCode) {
//  LXMTableViewOperationStateCodeNormal,         ///< 正常状态，没有任何操作在进行。
//  LXMTableViewOperationStateCodeModifying,      ///< 正在修改一个 todo 的文字。
//  LXMTableViewOperationStateCodeChecking,     ///< 正在（向右拖动）修改一个 todo 的完成状态。
//  LXMTableViewOperationStateCodeDeleting,       ///< 正在（向左拖动）删除一个 todo。
//  LXMTableViewOperationStateCodeAdding,
//  LXMTableViewOperationStateCodePinchAdding,         ///< 正在新建一个 todo。
//  LXMTableViewOperationStateCodePinchTranslating,  ///< 通过 pinch 缩小来返回上一级菜单。
//  LXMTableViewOperationStateCodePanTranslating,  ///< 通过 pan 来移动到下一个或者上一个列表。
//  LXMTableViewOperationStateCodePullAdding,
//  LXMTableViewOperationStateCodeRearranging,    ///< （长按后）正在拖动一个 todo 到某个位置。
//  LXMTableViewOperationStateCodeAnimating,      ///< 正在执行某些操作完成后的动画，不允许交互。
//  LXMTableViewOperationStateCodeAnimating2,     ///< 正在执行某些操作完成后的动画，但允许某些交互。
//};

@interface LXMTableViewState : NSObject

// shared properties
@property (nonatomic, weak) UIViewController *viewController;
@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, weak) LXMTodoList *list;

// recognizer and helpers
@property (nonatomic, strong) LXMTableViewGestureRecognizer *tableViewGestureRecognizer;
@property (nonatomic, weak) LXMTableViewGestureRecognizerHelper *recognizerHelper;
@property (nonatomic, weak) LXMTableViewHelper *tableViewHelper;
@property (nonatomic, weak) id <UITableViewDelegate> tableViewDelegate; ///< Ordinary delegate of table view.

//@property (nonatomic, assign) LXMTableViewOperationStateCode operationState; ///<  当前 table view 的操作状态。
@property (nonatomic, assign) CGPoint lastContentOffset; ///< 上个 operation state 结束时的 content offset
@property (nonatomic, assign) UIEdgeInsets lastContentInset; ///< 上个 operation state 结束时的 content inset
@property (nonatomic, weak, readonly) LXMTableViewCell *panningCell; ///< 正在部左右拖动的 cell。
@property (nonatomic, assign) LXMTableViewCellEditingState panningCellEditingState; ///< 正在部左右拖动的 cell 的 editingState。
@property (nonatomic, strong) NSIndexPath *panningRowIndexPath;
@property (nonatomic, strong) NSIndexPath *modifyingRowIndexPath; ///< 正在修改文字的的行的 index path。
@property (nonatomic, strong) NSIndexPath *rearrangingRowIndexPath;
@property (nonatomic, weak) LXMTableViewCell *rearrangingCell;
@property (nonatomic, strong) NSMutableArray<LXMTableViewCell *> *floatingCells; ///< 修改完成状态后在处在上下移动状态的所有 cell。
@property (nonatomic, strong) NSMutableArray<LXMTableViewCell *> *bouncingCells; ///< 水平拖动后在原位置左右跳动的所有 cell。
@property (nonatomic, strong) NSMutableArray<NSIndexPath *> *floatingIndexPaths;
@property (nonatomic, strong) NSMutableArray<NSIndexPath *> *bouncingIndexPaths;
@property (nonatomic, strong, readonly) NSArray<NSIndexPath *> *uneditableIndexPaths2;
@property (nonatomic, strong, readonly) NSArray<NSIndexPath *> *uneditableIndexPaths; ///< 因为处于竖直移动或者水平弹簧运动中，不可再进行拖动的所有 cell 的 index path。

// operation state
@property (nonatomic, strong) id <LXMTableViewOperationState> operationState2; ///<  当前 table view 的操作状态。
@property (nonatomic, strong) id <LXMTableViewOperationState> operationStateNormal;
@property (nonatomic, strong) id <LXMTableViewOperationState> operationStateModifying;
@property (nonatomic, strong) id <LXMTableViewOperationState> operationStateChecking;
@property (nonatomic, strong) id <LXMTableViewOperationState> operationStateDeleting;
@property (nonatomic, strong) id <LXMTableViewOperationState> operationStatePinchAdding;
@property (nonatomic, strong) id <LXMTableViewOperationState> operationStatePinchTranslating;
@property (nonatomic, strong) id <LXMTableViewOperationState> operationStatePinchPanTranslating;
@property (nonatomic, strong) id <LXMTableViewOperationState> operationStatePullAdding;
@property (nonatomic, strong) id <LXMTableViewOperationState> operationStateRearranging;
@property (nonatomic, strong) id <LXMTableViewOperationState> operationStateRecovering;
@property (nonatomic, strong) id <LXMTableViewOperationState> operationStateProcessing;

#pragma mark adding properties
@property (nonatomic, weak) LXMTransformableTableViewCell *addingCell;
@property (nonatomic, strong) NSIndexPath *addingRowIndexPath;
@property (nonatomic, assign) CGFloat addingRowHeight;
@property (nonatomic, assign) CGFloat addingProgress; ///< 新增待办项目时的手势操作进度，取值范围 0~1。

+ (instancetype)sharedInstance;

- (void)resetState;

//- (void)saveTableViewContentOffsetAndInset;
//- (void)recoverTableViewContentOffsetAndInset;

- (void)startAnimationWithBlock:(void (^__nonnull)())updatingBlock;
- (void)stopAnimationWithBlock:(void (^__nullable)())endingBlock;

@end
