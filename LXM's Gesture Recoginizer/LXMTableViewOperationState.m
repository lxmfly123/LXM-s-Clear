//
// Created by FLY.lxm on 2016.18.8.
// Copyright (c) 2016 FLY.lxm. All rights reserved.
//

#import "LXMTableViewOperationState.h"
#import "LXMTableViewState.h"
#import "LXMTableViewGestureRecognizer.h"
#import "LXMTodoItem.h"
#import "LXMTodoList.h"

#define CELL_SNAPSHOT_TAG 10086

NSString* assertFailure(NSString *state, NSString *gesture, NSString *gestureState) {

  return [NSString stringWithFormat:@"operation state: %@, recognizer: %@, recognizer state: %@", state, gesture, gestureState];
}

/// Normal Operation State
@interface LXMTableViewOperationStateNormal <LXMTableViewOperationStateProtocol> : LXMTableViewOperationState
@end

@implementation LXMTableViewOperationStateNormal

- (void)handlePinch:(UIPinchGestureRecognizer *)recognizer {

  if (recognizer.state == UIGestureRecognizerStateBegan) {

    self.tableViewState.addingRowIndexPath = [self.tableViewGestureRecognizer.helper addingRowIndexPathForGestureRecognizer:recognizer];
    NSAssert(self.tableViewState.addingRowIndexPath != nil, @"addingRowIndexPath 不能为 nil。");

    [self.tableViewState saveTableViewContentOffsetAndInset];

    self.tableView.contentInset =
        UIEdgeInsetsMake(self.tableView.contentInset.top + self.tableView.bounds.size.height,
                         self.tableView.contentInset.left,
                         self.tableView.contentInset.bottom + self.tableView.bounds.size.height,
                         self.tableView.contentInset.right);

    self.tableViewState.addingRowHeight = 0;
    [self.tableViewGestureRecognizer.delegate gestureRecognizer:self.tableViewGestureRecognizer
                                         needsAddRowAtIndexPath:self.tableViewState.addingRowIndexPath
                                                          usage:LXMTodoItemUsagePinchAdded];

    self.tableViewGestureRecognizer.operationState = self.tableViewGestureRecognizer.operationStatePinchAdding;
  } else if (recognizer.state == UIGestureRecognizerStateChanged) {
//    NSAssert(NO, assertFailure(@"normal", @"pinch", @"changed"));
  } else if (recognizer.state == UIGestureRecognizerStateEnded) {
//    NSAssert(NO, assertFailure(@"normal", @"pinch", @"ended"));
  }
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer {

//  LXMTableViewCellEditingState lastEditingState = self.tableViewState.panningCellEditingState;
//  static NSIndexPath *panningIndexPath;
//  LXMTableViewCell *panningCell;

  if (recognizer.state == UIGestureRecognizerStateBegan) {
    self.tableViewState.panningRowIndexPath = [self.tableView indexPathForRowAtPoint:[recognizer locationInView:self.tableView]];
  } else if (recognizer.state == UIGestureRecognizerStateChanged) {
    CGFloat offsetX = [self.tableViewGestureRecognizer.helper panOffsetX:recognizer];
    self.tableViewState.panningCell.actualContentView.frame = CGRectOffset(self.tableViewState.panningCell.contentView.bounds, offsetX, 0);
    [self.tableViewState.panningCell setNeedsLayout];

    if (offsetX > [LXMGlobalSettings sharedInstance].editCommitTriggerWidth) {
      if (self.tableViewState.panningCell.editingState != LXMTableViewCellEditingStateWillCheck) {
        NSLog(@"will check");
        self.tableViewState.panningCell.editingState = LXMTableViewCellEditingStateWillCheck;
      }
    } else if (offsetX < -[LXMGlobalSettings sharedInstance].editCommitTriggerWidth) {
      if (self.tableViewState.panningCell.editingState != LXMTableViewCellEditingStateWillDelete) {
        NSLog(@"will delete");
        self.tableViewState.panningCell.editingState = LXMTableViewCellEditingStateWillDelete;
      }
    } else {
      if (self.tableViewState.panningCell.editingState != LXMTableViewCellEditingStateNormal) {
        NSLog(@"normal");
        self.tableViewState.panningCell.editingState = LXMTableViewCellEditingStateNormal;
      }
    }
//    panningCell.editingState = lastEditingState;

    [self.tableViewGestureRecognizer.delegate gestureRecognizer:self.tableViewGestureRecognizer
                                           didEnterEditingState:self.tableViewState.panningCell.editingState
                                              forRowAtIndexPath:self.tableViewState.panningRowIndexPath];

    self.tableViewGestureRecognizer.operationState = offsetX > 0 ? self.tableViewGestureRecognizer.operationStateChecking : self.tableViewGestureRecognizer.operationStateDeleting;

  } else if (recognizer.state == UIGestureRecognizerStateEnded) {
    [self.tableViewGestureRecognizer.delegate gestureRecognizer:self.tableViewGestureRecognizer
                                          didCommitEditingState:self.tableViewState.panningCell.editingState
                                              forRowAtIndexPath:self.tableViewState.panningRowIndexPath];
    self.tableViewState.panningCell.editingState = LXMTableViewCellEditingStateNone;

    self.tableViewGestureRecognizer.operationState =
        self.tableViewState.panningCell.editingState == LXMTableViewCellEditingStateWillDelete ?
            self.tableViewGestureRecognizer.operationStateRecovering :
            self.tableViewGestureRecognizer.operationStateProcessing;
  }
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)recognizer {

  if (recognizer.state == UIGestureRecognizerStateBegan) {

    // 获取拖动 cell 的位图快照。
    CGPoint location = [recognizer locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    UIGraphicsBeginImageContextWithOptions(cell.bounds.size, NO, 0);
    [cell.layer renderInContext:UIGraphicsGetCurrentContext()];
    self.tableViewGestureRecognizer.helper.snapshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    // 将位图快照作为 UIImageView 覆盖显示在拖动 cell 的位置上。
    UIImageView *snapshotView = [self.tableView viewWithTag:CELL_SNAPSHOT_TAG];
    if (!snapshotView) {
      snapshotView = [[UIImageView alloc] initWithImage:self.tableViewGestureRecognizer.helper.snapshot];
      snapshotView.tag = CELL_SNAPSHOT_TAG;
      [self.tableView addSubview:snapshotView];
      snapshotView.frame = [self.tableView rectForRowAtIndexPath:indexPath];
    }

    // （动画）将快照长宽放大至原 1.1 倍。
    [UIView beginAnimations:@"ZoomCellOut" context:nil];
    snapshotView.transform = CGAffineTransformMakeScale(1.1, 1.1);
    snapshotView.center = CGPointMake(self.tableView.center.x, location.y);
    [UIView commitAnimations];

    // 在原位置创建占位行
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableViewGestureRecognizer.delegate gestureRecognizer:self.tableViewGestureRecognizer needsCreatePlaceholderForRowAtIndexPath:indexPath];
    self.tableViewState.addingRowIndexPath = indexPath;
    [self.tableView endUpdates];

    [self.tableViewGestureRecognizer.helper prepareForRearrange:recognizer];

    self.tableViewGestureRecognizer.operationState = self.tableViewGestureRecognizer.operationStateRearranging;
  } else if (recognizer.state == UIGestureRecognizerStateChanged) {
    NSAssert(NO, assertFailure(@"normal", @"longpress", @"changed"));
  } else if (recognizer.state == UIGestureRecognizerStateEnded) {
    NSAssert(NO, assertFailure(@"normal", @"longpress", @"ended"));
  }

}

- (void)handleTap:(UITapGestureRecognizer *)recognizer {

  if (recognizer.state == UIGestureRecognizerStateEnded) {
    CGPoint location = [recognizer locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    LXMTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];

    if ([cell isMemberOfClass:[LXMTableViewCell class]] && !cell.todoItem.isCompleted) {
      [cell.strikeThroughText becomeFirstResponder];
      self.tableViewGestureRecognizer.operationState = self.tableViewGestureRecognizer.operationStateRecovering;
    } else {
      [LXMTableViewState sharedInstance].addingRowIndexPath = [NSIndexPath indexPathForRow:[LXMTableViewState sharedInstance].todoList.numberOfUncompleted inSection:0];
      [LXMTableViewState sharedInstance].addingRowHeight = 0;
      [self.tableViewGestureRecognizer.delegate gestureRecognizer:self.tableViewGestureRecognizer
                                           needsAddRowAtIndexPath:self.tableViewState.addingRowIndexPath
                                                            usage:LXMTodoItemUsageTapAdded];
    }
  }
}
- (void)handleScroll:(UITableView *)tableView {

  if (tableView.contentOffset.y < 0) {
    [LXMTableViewState sharedInstance].addingRowIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [LXMTableViewState sharedInstance].addingRowHeight = fabsf(tableView.contentOffset.y);
    [self.tableViewGestureRecognizer.delegate gestureRecognizer:self.tableViewGestureRecognizer
                                         needsAddRowAtIndexPath:self.tableViewState.addingRowIndexPath
                                                          usage:LXMTodoItemUsagePullAdded];
    self.tableViewGestureRecognizer.operationState = self.tableViewGestureRecognizer.operationStatePullAdding;
  }
}

@end


/// Modifying Operation State
@interface LXMTableViewOperationStateModifying <LXMTableViewOperationStateProtocol>: LXMTableViewOperationState
@end

@implementation LXMTableViewOperationStateModifying

- (void)handlePinch:(UIPinchGestureRecognizer *)recognizer {}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer {}

- (void)handleLongPress:(UILongPressGestureRecognizer *)recognizer {}

- (void)handleTap:(UITapGestureRecognizer *)recognizer {

  if (recognizer.state == UIGestureRecognizerStateEnded) {
    [self.tableView endEditing:YES];
  }
}

- (void)handleScroll:(UITableView *)tableView {}

@end


/// Checking Operation State
@interface LXMTableViewOperationStateChecking <LXMTableViewOperationStateProtocol>: LXMTableViewOperationStateNormal
@end

@implementation LXMTableViewOperationStateChecking

- (void)handlePinch:(UIPinchGestureRecognizer *)recognizer {
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer {

  if (recognizer.state == UIGestureRecognizerStateBegan) {
    NSAssert(NO, assertFailure(@"checking", @"pan", @"began"));
  } else if (recognizer.state == UIGestureRecognizerStateChanged) {
    [super handlePan:recognizer];
  } else if (recognizer.state == UIGestureRecognizerStateEnded) {
    [super handlePan:recognizer];
  }
}

@end


/// Deleting Operation State
@interface LXMTableViewOperationStateDeleting <LXMTableViewOperationStateProtocol>: LXMTableViewOperationStateNormal
@end

@implementation LXMTableViewOperationStateDeleting

- (void)handlePinch:(UIPinchGestureRecognizer *)recognizer {
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer {

  if (recognizer.state == UIGestureRecognizerStateBegan) {
    NSAssert(NO, assertFailure(@"deleting", @"pan", @"began"));
  } else if (recognizer.state == UIGestureRecognizerStateChanged) {
    [super handlePan:recognizer];
  } else if (recognizer.state == UIGestureRecognizerStateEnded) {
    [super handlePan:recognizer];
  }
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)recognizer {}
- (void)handleTap:(UITapGestureRecognizer *)recognizer {}
- (void)handleScroll:(UITableView *)tableView {}

@end


/// Pinch Adding Operation State
@interface LXMTableViewOperationStatePinchAdding <LXMTableViewOperationStateProtocol>: LXMTableViewOperationState
@end

@implementation LXMTableViewOperationStatePinchAdding

- (void)handlePinch:(UIPinchGestureRecognizer *)recognizer {

  if (recognizer.state == UIGestureRecognizerStateBegan) {
    NSAssert(NO, assertFailure(@"pinch adding", @"pinch", @"began"));
  } else if (recognizer.state == UIGestureRecognizerStateChanged && recognizer.numberOfTouches >= 2) {
    [self.tableViewGestureRecognizer.helper updateWithPinchAdding:recognizer];
    if ([self.tableViewGestureRecognizer.delegate respondsToSelector:@selector(gestureRecognizer:isAddingRowAtIndexPath:)]) {
      [self.tableViewGestureRecognizer.delegate gestureRecognizer:self.tableViewGestureRecognizer
                                           isAddingRowAtIndexPath:self.tableViewState.addingRowIndexPath];
    }
    [UIView performWithoutAnimation:^{
      // FIXME: bug ———— 使用 updates 系列方法后，cell 文字不会随高度变化。
      [self.tableView beginUpdates];
      [self.tableView reloadRowsAtIndexPaths:@[[LXMTableViewState sharedInstance].addingRowIndexPath] withRowAnimation:UITableViewRowAnimationNone];
      [self.tableView endUpdates];
    }];
  } else if (recognizer.state == UIGestureRecognizerStateEnded) {
    if ([LXMTableViewState sharedInstance].addingRowIndexPath) {
      [self.tableViewGestureRecognizer.helper commitOrDiscardRow];
      self.tableViewGestureRecognizer.operationState = self.tableViewGestureRecognizer.operationStateRecovering;
    } else {
      self.tableViewGestureRecognizer.operationState = self.tableViewGestureRecognizer.operationStateNormal;
    }
  }
}
- (void)handlePan:(UIPanGestureRecognizer *)recognizer {}
- (void)handleLongPress:(UILongPressGestureRecognizer *)recognizer {}
- (void)handleTap:(UITapGestureRecognizer *)recognizer {}
- (void)handleScroll:(UITableView *)tableView {}

@end


/// Pinch Translating Operation State
@interface LXMTableViewOperationStatePinchTranslating <LXMTableViewOperationStateProtocol>: LXMTableViewOperationState
@end

@implementation LXMTableViewOperationStatePinchTranslating

- (void)handlePinch:(UIPinchGestureRecognizer *)recognizer {}
- (void)handlePan:(UIPanGestureRecognizer *)recognizer {}
- (void)handleLongPress:(UILongPressGestureRecognizer *)recognizer {}
- (void)handleTap:(UITapGestureRecognizer *)recognizer {}
- (void)handleScroll:(UITableView *)tableView {}

@end


/// Pan Translating Operation State
@interface LXMTableViewOperationStatePanTranslating <LXMTableViewOperationStateProtocol>: LXMTableViewOperationState
@end

@implementation LXMTableViewOperationStatePanTranslating

- (void)handlePinch:(UIPinchGestureRecognizer *)recognizer {}
- (void)handlePan:(UIPanGestureRecognizer *)recognizer {}
- (void)handleLongPress:(UILongPressGestureRecognizer *)recognizer {}
- (void)handleTap:(UITapGestureRecognizer *)recognizer {}
- (void)handleScroll:(UITableView *)tableView {}

@end


/// Pull Adding Translating Operation State
@interface LXMTableViewOperationStatePullAdding <LXMTableViewOperationStateProtocol>: LXMTableViewOperationState
@end

@implementation LXMTableViewOperationStatePullAdding

- (void)handlePinch:(UIPinchGestureRecognizer *)recognizer {}
- (void)handlePan:(UIPanGestureRecognizer *)recognizer {}
- (void)handleLongPress:(UILongPressGestureRecognizer *)recognizer {}
- (void)handleTap:(UITapGestureRecognizer *)recognizer {}

- (void)handleScroll:(UITableView *)tableView {

  if (self.tableViewState.addingRowIndexPath) {
    [LXMTableViewState sharedInstance].addingRowHeight -= tableView.contentOffset.y;
    tableView.contentOffset = CGPointZero;
    [UIView performWithoutAnimation:^{
      [self.tableView reloadRowsAtIndexPaths:@[self.tableViewState.addingRowIndexPath]
                            withRowAnimation:UITableViewRowAnimationNone];
    }];
  }
}

@end


/// Rearranging Operation State
@interface LXMTableViewOperationStateRearranging <LXMTableViewOperationStateProtocol>: LXMTableViewOperationState
@end

@implementation LXMTableViewOperationStateRearranging

- (void)handlePinch:(UIPinchGestureRecognizer *)recognizer {}
- (void)handlePan:(UIPanGestureRecognizer *)recognizer {}

- (void)handleLongPress:(UILongPressGestureRecognizer *)recognizer {

  CGPoint location = [recognizer locationInView:self.tableView];

  if (recognizer.state == UIGestureRecognizerStateBegan) {
    NSAssert(NO, assertFailure(@"rearranging", @"longpress", @"began"));
  } else if (recognizer.state == UIGestureRecognizerStateChanged) {
    // 随手指移动 cell 快照，当移动到 table view 顶部或者底部时，滚动 table view。
    self.tableViewGestureRecognizer.helper.snapShotView.center = CGPointMake(self.tableView.center.x, location.y);

    [self.tableViewGestureRecognizer.helper updateAddingIndexPathForCurrentLocation:recognizer];

  } else if (recognizer.state == UIGestureRecognizerStateEnded) {
    __weak __block UIImageView *snapshotView = [self.tableView viewWithTag:CELL_SNAPSHOT_TAG];
    __weak __block LXMTableViewOperationState *weakSelf = self;
    __weak __block NSIndexPath *indexPath = [LXMTableViewState sharedInstance].addingRowIndexPath;

    [self.tableViewGestureRecognizer.helper finishLongPress:recognizer];

    [UIView animateWithDuration:LXMTableViewRowAnimationDurationShort animations:^{
      CGRect rect = [weakSelf.tableView rectForRowAtIndexPath:indexPath];
      snapshotView.transform = CGAffineTransformIdentity;
      snapshotView.frame = rect;
    } completion:^(BOOL finished) {
      [snapshotView removeFromSuperview];

      [UIView beginAnimations:nil context:nil];
      [CATransaction begin];
      [CATransaction setCompletionBlock:^{
        [weakSelf.tableView lxm_reloadVisibleRowsExceptIndexPaths:@[indexPath]];
        weakSelf.tableViewGestureRecognizer.helper.snapshot = nil;
        weakSelf.tableViewState.addingRowIndexPath = nil;
        [[NSNotificationCenter defaultCenter] postNotificationName:LXMOperationCompleteNotification object:self];
        self.tableViewGestureRecognizer.operationState = self.tableViewGestureRecognizer.operationStateNormal;
      }];
      [weakSelf.tableView beginUpdates];
      [weakSelf.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
      [weakSelf.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
      [weakSelf.tableViewGestureRecognizer.delegate gestureRecognizer:weakSelf.tableViewGestureRecognizer
                             needsReplacePlaceholderForRowAtIndexPath:indexPath];
      [weakSelf.tableView endUpdates];
      [CATransaction commit];
      [UIView commitAnimations];
    }];
  }
}

- (void)handleTap:(UITapGestureRecognizer *)recognizer {}
- (void)handleScroll:(UITableView *)tableView {}

@end


/// Recoving Operation State
@interface LXMTableViewOperationStateRecovering <LXMTableViewOperationStateProtocol>: LXMTableViewOperationState
@end

@implementation LXMTableViewOperationStateRecovering

- (void)handlePinch:(UIPinchGestureRecognizer *)recognizer {}
- (void)handlePan:(UIPanGestureRecognizer *)recognizer {}
- (void)handleLongPress:(UILongPressGestureRecognizer *)recognizer {}
- (void)handleTap:(UITapGestureRecognizer *)recognizer {}
- (void)handleScroll:(UITableView *)tableView {}

@end

/// Processing Operation State
@interface LXMTableViewOperationStateProcessing <LXMTableViewOperationStateProtocol>: LXMTableViewOperationState
@end

@implementation LXMTableViewOperationStateProcessing

- (void)handlePinch:(UIPinchGestureRecognizer *)recognizer {}
- (void)handlePan:(UIPanGestureRecognizer *)recognizer {}
- (void)handleLongPress:(UILongPressGestureRecognizer *)recognizer {}
- (void)handleTap:(UITapGestureRecognizer *)recognizer {}
- (void)handleScroll:(UITableView *)tableView {}

@end






@implementation LXMTableViewOperationState

+ (instancetype)operationStateWithTableViewGestureRecognizer:(LXMTableViewGestureRecognizer *)tableViewGestureRecognizer operationStateCode:(LXMTableViewOperationStateCode)stateCode {

  switch (stateCode) {
    case LXMTableViewOperationStateCodeNormal:
      return [[LXMTableViewOperationStateNormal alloc] initWithTableViewGestureRecognizer:tableViewGestureRecognizer];
      break;

    case LXMTableViewOperationStateCodeModifying:
      return [[LXMTableViewOperationStateModifying alloc] initWithTableViewGestureRecognizer:tableViewGestureRecognizer];
      break;

    case LXMTableViewOperationStateCodeChecking:
      return [[LXMTableViewOperationStateChecking alloc] initWithTableViewGestureRecognizer:tableViewGestureRecognizer];
      break;

    case LXMTableViewOperationStateCodeDeleting:
      return [[LXMTableViewOperationStateDeleting alloc] initWithTableViewGestureRecognizer:tableViewGestureRecognizer];
      break;

    case LXMTableViewOperationStateCodePinchAdding:
      return [[LXMTableViewOperationStatePinchAdding alloc] initWithTableViewGestureRecognizer:tableViewGestureRecognizer];
      break;

    case LXMTableViewOperationStateCodePinchTranslating:
      return [[LXMTableViewOperationStatePinchTranslating alloc] initWithTableViewGestureRecognizer:tableViewGestureRecognizer];
      break;

    case LXMTableViewOperationStateCodePanTranslating:
      return [[LXMTableViewOperationStatePanTranslating alloc] initWithTableViewGestureRecognizer:tableViewGestureRecognizer];
      break;

    case LXMTableViewOperationStateCodePullAdding:
      return [[LXMTableViewOperationStatePullAdding alloc] initWithTableViewGestureRecognizer:tableViewGestureRecognizer];
      break;

    case LXMTableViewOperationStateCodeRearranging:
      return [[LXMTableViewOperationStateRearranging alloc] initWithTableViewGestureRecognizer:tableViewGestureRecognizer];
      break;

    case LXMTableViewOperationStateCodeProcessing:
      return [[LXMTableViewOperationStateProcessing alloc] initWithTableViewGestureRecognizer:tableViewGestureRecognizer];
      break;

    case LXMTableViewOperationStateCodeRecovering:
      return [[LXMTableViewOperationStateRecovering alloc] initWithTableViewGestureRecognizer:tableViewGestureRecognizer];
      break;
  }
  return nil;
}

- (instancetype)initWithTableViewGestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer {

  if (self = [super init]) {
    self.tableViewGestureRecognizer = recognizer;
    self.tableView = recognizer.tableView;
    self.tableViewState = [LXMTableViewState sharedInstance];
  }

  return self;
}

- (void)handlePinch:(UIPinchGestureRecognizer *)recognizer {
  NSAssert(NO, @"仅能在子类中调用。");
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
  NSAssert(NO, @"仅能在子类中调用。");
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)recognizer {
  NSAssert(NO, @"仅能在子类中调用。");
}

- (void)handleTap:(UITapGestureRecognizer *)recognizer {
  NSAssert(NO, @"仅能在子类中调用。");
}

- (void)handleScroll:(UITableView *)tableView {
  NSAssert(NO, @"仅能在子类中调用。");
}

- (void)shouldChangeToOperationState:(id<LXMTableViewOperationStateProtocol>)operationState {
  self.tableViewGestureRecognizer.operationState = operationState;
}

@end