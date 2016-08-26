//
//  LXMTableViewGestureRecognizer.h
//  LXM's Gesture Recoginizer
//
//  Created by FLY.lxm on 3/22/16.
//  Copyright © 2016 FLY.lxm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LXMTableViewState.h"
#import "LXMTableViewCell.h"
#import "LXMTableViewGestureRecognizerHelper.h"

extern NSTimeInterval const LXMTableViewRowAnimationDurationNormal;
extern NSTimeInterval const LXMTableViewRowAnimationDurationShort;
extern NSTimeInterval const LXMTableViewRowAnimationDurationLong;

typedef NS_OPTIONS(NSUInteger, LXMTableViewGestureRecognizerOptions) {
  LXMTableViewGestureRecognizerOptionsTap           = 1 << 0,
  LXMTableViewGestureRecognizerOptionsPinch         = 1 << 1,
  LXMTableViewGestureRecognizerOptionsHorizontalPan = 1 << 2,
  LXMTableViewGestureRecognizerOptionsVerticalPan   = 1 << 3,
  LXMTableViewGestureRecognizerOptionsLongPress     = 1 << 4,
};

typedef NS_ENUM(NSUInteger, LXMTableViewGestureRecognizerState) {
  LXMTableViewGestureRecognizerStateNone,       ///< 正常状态，可触发任一手势，此时的 option 的也会被设置为允许识别全部手势。
//  LXMTableViewGestureRecognizerStateTapDone,
  LXMTableViewGestureRecognizerStatePinching,   ///< 双指缩放，缩小时应切换至上一级列表，放大时在双指中间新增 todo。
  LXMTableViewGestureRecognizerStateScalingUp,
  LXMTableViewGestureRecognizerStateScalingDown,
  LXMTableViewGestureRecognizerStatePanning,    ///< 左右拖动 todo 来将其标记为完成(未完成)或者删除。
  LXMTableViewGestureRecognizerStateChecking,
  LXMTableViewGestureRecognizerStateDeleting,
  LXMTableViewGestureRecognizerStateMoving,     ///< 长按后上下拖动 todo 来改变其在列表中的排位。
  LXMTableViewGestureRecognizerStateRearranging,
  LXMTableViewGestureRecognizerStateDragging,   ///< 向下拖动整个列表来在顶部新建 todo。
  LXMTableViewGestureRecognizerStateWaiting,
  LXMTableViewGestureRecognizerStateWaitingForTap,
  LXMTableViewGestureRecognizerStateListening,
};

@protocol LXMTableViewGestureAddingRowDelegate <NSObject>

- (BOOL)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer canAddCellAtIndexPath:(NSIndexPath *)indexPath;
- (void)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer needsAddRowAtIndexPath:(NSIndexPath *)indexPath usage:(LXMTodoItemUsage)usage;
- (void)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer needsCommitRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer needsDiscardRowAtIndexPath:(NSIndexPath *)indexPath;

@optional

- (NSIndexPath *)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer willCreateCellAtIndexPath:(NSIndexPath *)indexPath;
- (void)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer isAddingRowAtIndexPath:(NSIndexPath *)indexPath;
- (CGFloat)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer  heightForCommitingRowAtIndexPath:(NSIndexPath *)indexPath;

@end


// pan right/left to finish/delete cell
@protocol LXMTableViewGestureEditingRowDelegate <NSObject>

// user indexpath to identify cell
- (BOOL)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer canEditRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer didEnterEditingState:(LXMTableViewCellEditingState)editingState forRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer didCommitEditingState:(LXMTableViewCellEditingState)editingState forRowAtIndexPath:(NSIndexPath *)indexPath;

@optional
// use cell directly
- (BOOL)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer canEditCell:(LXMTableViewCell *)cell;
- (void)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer didEnterEditingState:(LXMTableViewCellEditingState)editingState forCell:(LXMTableViewCell *)cell;
- (void)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer didCommitEditingState:(LXMTableViewCellEditingState)editingState forCell:(LXMTableViewCell *)cell;


- (CGFloat)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer lengthForCommitEditingRowAtIndexPath:(NSIndexPath *)indexPath;
//- (void)gestureRecognizer:(JTTableViewGestureRecognizer *)gestureRecognizer didChangeContentViewTranslation:(CGPoint)translation forRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)
gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer didChangeContentViewTranslation:(CGPoint)translation forRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer isCommittingEditingState:(LXMTableViewCellEditingState)editingState forCell:(LXMTableViewCell *)cell;

@end

/// 长按拖动，重新排序。
@protocol LXMTableViewGestureMoveRowDelegate <NSObject>

- (BOOL)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer canMoveRowAtIndexPath:(NSIndexPath *)indexPath; ///< 能否拖动一个行
- (void)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer needsCreatePlaceholderForRowAtIndexPath:(NSIndexPath *)indexPath; /// <为拖动的行创建一个占位行
- (void)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer needsMovePlaceholderForRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath; ///< 随着移动的行移动占位行
- (void)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer needsReplacePlaceholderForRowAtIndexPath:(NSIndexPath *)indexPath; ///< 将占位行替换为实际行

@end

@interface LXMTableViewGestureRecognizer : NSObject <UITableViewDelegate, LXMTableViewCellDelegate>

@property (nonatomic, strong) LXMTableViewGestureRecognizerHelper *helper;
@property (nonatomic, weak, readonly) UITableView *tableView;
@property (nonatomic, assign, readonly) LXMTableViewGestureRecognizerState state;
@property (nonatomic, assign, readonly) LXMTableViewGestureRecognizerState previousState;

@property (nonatomic, weak) id <LXMTableViewGestureAddingRowDelegate, LXMTableViewGestureEditingRowDelegate, LXMTableViewGestureMoveRowDelegate> delegate;

// operation state
@property (nonatomic, strong) id <LXMTableViewOperationStateProtocol> operationState; ///<  当前 table view 的操作状态。
@property (nonatomic, strong) id <LXMTableViewOperationStateProtocol> operationStateNormal;
@property (nonatomic, strong) id <LXMTableViewOperationStateProtocol> operationStateModifying;
@property (nonatomic, strong) id <LXMTableViewOperationStateProtocol> operationStateChecking;
@property (nonatomic, strong) id <LXMTableViewOperationStateProtocol> operationStateDeleting;
@property (nonatomic, strong) id <LXMTableViewOperationStateProtocol> operationStatePinchAdding;
@property (nonatomic, strong) id <LXMTableViewOperationStateProtocol> operationStatePinchTranslating;
@property (nonatomic, strong) id <LXMTableViewOperationStateProtocol> operationStatePinchPanTranslating;
@property (nonatomic, strong) id <LXMTableViewOperationStateProtocol> operationStatePullAdding;
@property (nonatomic, strong) id <LXMTableViewOperationStateProtocol> operationStateRearranging;
@property (nonatomic, strong) id <LXMTableViewOperationStateProtocol> operationStateRecovering;
@property (nonatomic, strong) id <LXMTableViewOperationStateProtocol> operationStateProcessing;

+ (instancetype)gestureRecognizerWithTableView:(UITableView *)tableView delegate:(id)delegate;

- (void)allowAllGestures; ///< 允许识别所有手势。
- (void)denyAllGestures; ///< 不允许识别任何手势。
- (void)allowGestures:(LXMTableViewGestureRecognizerOptions)options; ///< 允许识别指定的手势，不会改变非指定的手势的识别状态。
- (void)denyGestures:(LXMTableViewGestureRecognizerOptions)options; ///< 不允许识别指定的手势，不会改变非指定的手势的识别状态。
- (void)allowGesturesOnly:(LXMTableViewGestureRecognizerOptions)options; ///< 仅允许识别指定的手势，不识别其余手势。
- (void)denyGesturesOnly:(LXMTableViewGestureRecognizerOptions)options; ///< 不允许识别指定的手势，允许识别其余手势的识别状态。
- (BOOL)isGesturesAllowed:(LXMTableViewGestureRecognizerOptions)options; ///< 返回是否允许识别指定的手势。当参数有多个手势时，只有全部允许识别，才会返回 YES。

@end


@interface UITableView (LXMTableView)

- (void)lxm_updateTableViewWithDuration:(NSTimeInterval)duration updates:(void (^__nullable) ())updates completion:(void (^__nullable) ())completion;

- (LXMTableViewGestureRecognizer *)lxm_enableGestureTableViewWithDelegate:(id)delegate;
- (void)lxm_reloadVisibleRowsExceptIndexPaths:(NSArray<NSIndexPath *> *)indexPaths;

@end

@interface UIView (FindViewThatIsFirstResponder)
- (UIView *)findViewThatIsFirstResponder;
@end