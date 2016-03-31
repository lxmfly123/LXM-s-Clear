//
//  LXMTableViewGestureRecognizer.h
//  LXM's Gesture Recoginizer
//
//  Created by FLY.lxm on 3/22/16.
//  Copyright © 2016 FLY.lxm. All rights reserved.
//


typedef NS_ENUM(NSUInteger, LXMTableViewCellEditingState) {
  LXMTableViewCellEditingStateMiddle,
  LXMTableViewCellEditingStateLeft,
  LXMTableViewCellEditingStateRight,
};

extern CGFloat const LXMTableViewRowAnimationDuration;

@interface LXMTableViewGestureRecognizer : NSObject <UITableViewDelegate>

@property (nonatomic, weak, readonly) UITableView *tableView;

+ (instancetype)gestureRecognizerWithTableView:(UITableView *)tableView delegate:(id)delegate;

@end

@protocol LXMTableViewGestureAddingRowDelegate <NSObject>

- (void)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer needsAddRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer needsCommitRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer needsDiscardRowAtIndexPath:(NSIndexPath *)indexPath;

@optional

- (NSIndexPath *)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer willCreatCellAtIndexPath:(NSIndexPath *)indexPath;
- (CGFloat)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer  heightForCommitingRowAtIndexPath:(NSIndexPath *)indexPath;

@end


// swipe to finish/delete cell
@protocol LXMTableViewGestureEditingRowDelegate <NSObject>

- (BOOL)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer canEditRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer didEnterEditState:(LXMTableViewCellEditingState)editingState forRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer didCommitEditState:(LXMTableViewCellEditingState)editingState forRowAtIndexPath:(NSIndexPath *)indexPath;

@optional

- (CGFloat)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer  lengthForCommitEditingRowAtIndexPath:(NSIndexPath *)indexPath;
//- (void)gestureRecognizer:(JTTableViewGestureRecognizer *)gestureRecognizer didChangeContentViewTranslation:(CGPoint)translation forRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)
gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer didChangeContentViewTranslation:(CGPoint)translation forRowAtIndexPath:(NSIndexPath *)indexPath;

@end


// long press to drag a row to any indexPath;
@protocol LXMTableViewGestureMoveRowDelegate <NSObject>

- (BOOL)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer canMoveRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer needsCreatePlaceholderForRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer needsMovePlaceholderForRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath;
- (void)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer needsReplacePlaceholderForRowAtIndexPath:(NSIndexPath *)indexPath;

@end


@interface UITableView (LXMTableViewDelegate)

- (LXMTableViewGestureRecognizer *)enableGestureTableViewWithDelegate:(id)delegate;
- (void)reloadVisibleRowsExceptIndexPath:(NSIndexPath *)indexPath;

@end