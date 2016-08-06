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

extern CGFloat const LXMTableViewRowAnimationDurationNormal;
extern CGFloat const LXMTableViewRowAnimationDurationShort;
extern CGFloat const LXMTableViewRowAnimationDurationLong;

typedef NS_OPTIONS(NSUInteger, LXMTableViewGestureRecognizerOptions) {
  LXMTableViewGestureRecognizerOptionsTap           = 1 << 0,
  LXMTableViewGestureRecognizerOptionsPinch         = 1 << 1,
  LXMTableViewGestureRecognizerOptionsHorizontalPan = 1 << 2,
  LXMTableViewGestureRecognizerOptionsVerticalPan   = 1 << 3,
  LXMTableViewGestureRecognizerOptionsLongPress     = 1 << 4,
};

@interface LXMTableViewGestureRecognizer : NSObject <UITableViewDelegate>

@property (nonatomic, weak, readonly) UITableView *tableView;

+ (instancetype)gestureRecognizerWithTableView:(UITableView *)tableView delegate:(id)delegate;

@property (nonatomic, assign) CGFloat addingRowHeight;

- (void)allowAllGestures; ///< 允许识别所有手势。
- (void)denyAllGestures; ///< 不允许识别任何手势。
- (void)allowGesture:(LXMTableViewGestureRecognizerOptions)options; ///< 允许识别指定的手势，不会改变非指定的手势的识别状态。
- (void)denyGestures:(LXMTableViewGestureRecognizerOptions)options; ///< 不允许识别指定的手势，不会改变非指定的手势的识别状态。
- (void)allowGesturesOnly:(LXMTableViewGestureRecognizerOptions)options; ///< 仅允许识别指定的手势，不识别其余手势。
- (void)denyGesturesOnly:(LXMTableViewGestureRecognizerOptions)options; ///< 不允许识别指定的手势，允许识别其余手势的识别状态。
- (BOOL)gesturesIsAllowed:(LXMTableViewGestureRecognizerOptions)options; ///< 返回是否允许识别指定的手势。当参数有多个手势时，只有全部允许识别，才会返回 YES。


@end

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

// use cell directly
- (BOOL)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer canEditCell:(LXMTableViewCell *)cell;
- (void)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer didEnterEditingState:(LXMTableViewCellEditingState)editingState forCell:(LXMTableViewCell *)cell;
- (void)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer didCommitEditingState:(LXMTableViewCellEditingState)editingState forCell:(LXMTableViewCell *)cell;

@optional

- (CGFloat)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer lengthForCommitEditingRowAtIndexPath:(NSIndexPath *)indexPath;
//- (void)gestureRecognizer:(JTTableViewGestureRecognizer *)gestureRecognizer didChangeContentViewTranslation:(CGPoint)translation forRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)
gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer didChangeContentViewTranslation:(CGPoint)translation forRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer isCommittingEditingState:(LXMTableViewCellEditingState)editingState forCell:(LXMTableViewCell *)cell;

@end


/// 长按拖动，重新排序。
@protocol LXMTableViewGestureMoveRowDelegate <NSObject>

/// 能否拖动一个行
- (BOOL)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer canMoveRowAtIndexPath:(NSIndexPath *)indexPath;
/// 为拖动的行创建一个占位行
- (void)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer needsCreatePlaceholderForRowAtIndexPath:(NSIndexPath *)indexPath;
/// 随着移动的行移动占位行
- (void)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer needsMovePlaceholderForRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath;
/// 将占位行替换为实际行
- (void)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer needsReplacePlaceholderForRowAtIndexPath:(NSIndexPath *)indexPath;

@end


@interface UITableView (LXMTableView)

- (LXMTableViewGestureRecognizer *)enableGestureTableViewWithDelegate:(id)delegate;
- (void)reloadVisibleRowsExceptIndexPaths:(NSArray<NSIndexPath *> *)indexPaths;

@end