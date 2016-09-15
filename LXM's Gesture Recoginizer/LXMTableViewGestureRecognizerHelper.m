//
// Created by FLY.lxm on 2016.19.8.
// Copyright (c) 2016 FLY.lxm. All rights reserved.
//

#import "LXMTableViewGestureRecognizerHelper.h"
#import "LXMTableViewState.h"
#import "LXMTableViewGestureRecognizer.h"
#import "LXMAnimationQueue.h"
#import "LXMTransformableTableViewCell.h"
#import "LXMTableViewHelper.h"
#import "LXMTodoList.h"


/// Pinch 时的两个点。
typedef struct {
  CGPoint upper;
  CGPoint lower;
} LXMPinchPoints;

/// 水平拖动时的位移值。
typedef struct {
  CGFloat n;
  CGFloat k;
  CGFloat m;
  CGFloat b;
  CGFloat c;
} LXMPanOffsetXParameters;

CGFloat const kScrollingRate2 = 10.0f; ///< 当长按拖动 todo 并移动到 table view 顶部或底部时，table view 的滚动速度。

CG_INLINE LXMPanOffsetXParameters LXMPanOffsetXParametersMake(CGFloat n, CGFloat k, CGFloat m) {

  CGFloat b = (1 - k * n * logf(m)) / (k * logf(m));
  CGFloat c = k * n - logf(n + b) / logf(m);
  return (LXMPanOffsetXParameters){n, k, m, b, c};
} ///< Make a offset curve from '(n, k, m)'. see http://lxm9.com/2016/04/19/sliding-damping-in-clear-the-app/

@interface LXMTableViewGestureRecognizerHelper ()

@property (nonatomic, assign) LXMPinchPoints startingPinchPoints;
@property (nonatomic, weak) LXMTableViewState *tableViewState;
@property (nonatomic, weak) LXMGlobalSettings *globalSettings;
@property (nonatomic, weak) LXMTableViewHelper *tableViewHelper;
@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, weak) LXMTodoList *list;
@property (nonatomic, strong) NSIndexPath *addingRowIndexPath;
@property (nonatomic, strong) NSTimer *movingTimer;
@property (nonatomic, assign) CGFloat scrollingRate;

@property (nonatomic, assign, readwrite) NSTimeInterval keyboardAnimationDuration;
@property (nonatomic, assign, readwrite) UIViewAnimationOptions keyboardAnimationCurveOption;
@property (nonatomic, strong) LXMAnimationQueue *animationQueue;

@end

@implementation LXMTableViewGestureRecognizerHelper

- (instancetype)initWithTableViewGestureRecognizer:(LXMTableViewGestureRecognizer *)tableViewGestureRecognizer tableViewState:(LXMTableViewState *)tableViewState {

  if (self = [super init]) {
    self.tableViewGestureRecognizer = tableViewGestureRecognizer;
    self.tableViewState = tableViewState;
    self.tableView = self.tableViewState.tableView;
    self.scrollingRate = 10;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
  }

  return self;
}

- (void)dealloc {

  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)collectStartingInformation:(UIGestureRecognizer *)recognizer {

  if ([recognizer isKindOfClass:[UIPinchGestureRecognizer class]]) {
    self.startingPinchPoints = [self p_normalizePinchPointsForPinchGestureRecognizer:recognizer];
  } else if ([recognizer isKindOfClass:[UIPanGestureRecognizer class]]) {

  } else if ([recognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {

  } else {
    NSAssert(NO, @"有别的手势混进来了。");
  }
}

- (LXMPinchPoints)p_normalizePinchPointsForPinchGestureRecognizer:(UIPinchGestureRecognizer *)recognizer {

  LXMPinchPoints pinchPoints = (LXMPinchPoints){
      [recognizer locationOfTouch:0 inView:self.tableView],
      [recognizer locationOfTouch:1 inView:self.tableView]};
  if (pinchPoints.upper.y > pinchPoints.lower.y) {
    CGPoint tempPoint = pinchPoints.upper;
    pinchPoints.upper = pinchPoints.lower;
    pinchPoints.lower = tempPoint;
  }
  return pinchPoints;
}

- (NSIndexPath *)p_targetIndexPathForPinchPoints:(LXMPinchPoints)pinchPoints {

  NSIndexPath *lower = [self.tableView indexPathForRowAtPoint:pinchPoints.lower];

  if (lower) {
    CGPoint middlePoint = (CGPoint){(pinchPoints.upper.x + pinchPoints.lower.x) / 2, (pinchPoints.upper.y + pinchPoints.lower.y) / 2};
    NSIndexPath *middleIndexPath = [self.tableView indexPathForRowAtPoint:middlePoint];
    UITableViewCell *middleCell = [self.tableView cellForRowAtIndexPath:middleIndexPath];
    if (middlePoint.y > middleCell.frame.origin.y + middleCell.frame.size.height / 2) {
      middleIndexPath = [NSIndexPath indexPathForRow:middleIndexPath.row + 1 inSection:0];
    }
    return middleIndexPath;
  } else {
    return [NSIndexPath indexPathForRow:[self.tableView.dataSource tableView:self.tableView numberOfRowsInSection:0] inSection:0];
  }
}

- (void)keyboardWillShow:(NSNotification *)notification {

  _keyboardAnimationDuration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
  _keyboardAnimationCurveOption = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue] << 16;
}

#pragma mark - getters

- (LXMGlobalSettings *)globalSettings {

  if (!_globalSettings) {
    _globalSettings = [LXMGlobalSettings sharedInstance];
  }

  return _globalSettings;
}

- (LXMTableViewHelper *)tableViewHelper {

  return self.tableViewGestureRecognizer.tableViewHelper;
}

- (LXMTodoList *)list {

  return self.tableViewState.list;
}

- (NSTimeInterval)keyboardAnimationDuration {

  return _keyboardAnimationDuration = _keyboardAnimationDuration < 0.01 ? LXMTableViewRowAnimationDurationNormal : _keyboardAnimationDuration;
}

- (UIViewAnimationOptions)keyboardAnimationCurveOption {

  return _keyboardAnimationCurveOption = _keyboardAnimationCurveOption == 0 ? 7 << 16 :
      _keyboardAnimationCurveOption;
}

- (LXMAnimationQueue *)animationQueue {

  if (_animationQueue == nil) {
    _animationQueue = [LXMAnimationQueue new];
  }

  return _animationQueue;
}

#pragma mark - table view helper methods

- (void)deleteRowAtIndexPath:(NSIndexPath *)indexPath {

//  self.tableViewState.operationState = LXMTableViewOperationStateCodeAnimating;

  LXMTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
  LXMAnimationQueue *animationQueue = [LXMAnimationQueue new];

  LXMAnimationBlock moveRowLeft = ^(BOOL finished) {
    [UIView animateWithDuration:LXMTableViewRowAnimationDurationNormal animations:^{
      cell.contentView.frame = CGRectOffset(cell.contentView.frame, -cell.frame.size.width, 0);
    } completion:animationQueue.blockCompletion()];
  };
  LXMAnimationBlock deleteRowAndReload = ^(BOOL finished) {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:LXMTableViewRowAnimationDurationShort];
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
      [[NSNotificationCenter defaultCenter] postNotificationName:LXMOperationCompleteNotification object:self];
      [self.tableView reloadData];
      animationQueue.blockCompletion()(YES);
    }];
    [self.tableViewGestureRecognizer.delegate gestureRecognizer:self.tableViewGestureRecognizer
                                     needsDiscardRowAtIndexPath:indexPath];
//    [self.list.todoItems removeObjectAtIndex:indexPath.row];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
    [CATransaction commit];
    [UIView commitAnimations];
  };

  animationQueue.queueCompletion = ^(BOOL finished) {
    [[NSNotificationCenter defaultCenter] postNotificationName:LXMOperationCompleteNotification object:self];
  };

  [animationQueue addAnimations:moveRowLeft, deleteRowAndReload, nil];
  [animationQueue play];
}

- (void)resetCellAtIndexPath:(NSIndexPath *)indexPath forAdding:(BOOL)shouldAdd {

//  [LXMTableViewState sharedInstance].operationState = LXMTableViewOperationStateCodeAnimating;

  LXMTransformableTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
  CGFloat finishedRowHeight;
  CGFloat currentRowHeight = cell.frame.size.height;
  if (shouldAdd) {
    finishedRowHeight = self.globalSettings.modifyingRowHeight;
  } else {
    finishedRowHeight = 0;
  }

  LXMAnimationQueue *animationQueue = [LXMAnimationQueue new];
  LXMAnimationBlock resetTableView;

  if (indexPath.row == 0) {/*
    resetTableView = [^(BOOL finished) {

      CATransform3D identity, transform;
      if (shouldAdd) {
        ;
      } else {
        identity = CATransform3DIdentity;
        identity.m34 = self.globalSettings.addingM34;
        transform = CATransform3DRotate(identity, (CGFloat)M_PI_2, 1, 0, 0);
        [self startAnimation];
      }

      [UIView animateWithDuration:LXMTableViewRowAnimationDurationNormal animations:^{
        if (shouldAdd) {
          for (UITableViewCell *visibleCell in self.tableView.visibleCells) {
            if ([self.tableView indexPathForCell:visibleCell].row != indexPath.row) {
              visibleCell.frame = CGRectOffset(visibleCell.frame, 0, -(cell.frame.size.height - self.globalSettings.modifyingRowHeight));
            }
          }
          cell.frame =
          CGRectMake(cell.frame.origin.x,
                     cell.frame.origin.y,
                     cell.frame.size.width,
                     finishedRowHeight);
        } else {
          ((LXMFlippingTransformableTableViewCell *)cell).transformableView.layer.transform = transform;
        }
      } completion:^(BOOL finished) {
        if (!shouldAdd) {
          [self stopAnimation];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:LXMOperationCompleteNotification object:self];
        [self.tableView reloadData];
        animationQueue.blockCompletion()(YES);
      }];
    } copy];*/
  } else {
    resetTableView = [^(BOOL finished) {
      [UIView animateWithDuration:LXMTableViewRowAnimationDurationNormal animations:^{
        cell.frame =
            CGRectMake(cell.frame.origin.x,
                cell.frame.origin.y,
                cell.frame.size.width,
                finishedRowHeight);

        [self.tableViewState.tableViewHelper recoverTableViewContentOffsetAndInset];

        for (UITableViewCell *visibleCell in self.tableView.visibleCells) {
          if ([self.tableView indexPathForCell:visibleCell].row > indexPath.row) {
            if (shouldAdd) {
              visibleCell.frame = CGRectOffset(visibleCell.frame, 0, self.tableView.rowHeight - currentRowHeight);
            } else {
              visibleCell.frame = CGRectOffset(visibleCell.frame, 0, -currentRowHeight);
            }
          }
        }
      } completion:^(BOOL finished) {
        [[NSNotificationCenter defaultCenter] postNotificationName:LXMOperationCompleteNotification object:self];
        [self.tableView reloadData];
        animationQueue.blockCompletion()(YES);
      }];
    } copy];
  }

  LXMAnimationBlock assignFirstResponder = ^(BOOL finished){
    [UIView animateWithDuration:LXMTableViewRowAnimationDurationNormal animations:^{
      LXMTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
      if (shouldAdd) {
        [cell.strikeThroughText becomeFirstResponder];
      }
    } completion:^(BOOL finished) {
      if (!shouldAdd) {
        [[NSNotificationCenter defaultCenter] postNotificationName:LXMOperationCompleteNotification object:self];
      }
      self.tableViewGestureRecognizer.operationState = self.tableViewGestureRecognizer.operationStateNormal;
      animationQueue.blockCompletion()(YES);
    }];
  };

  [animationQueue addAnimations:resetTableView, assignFirstResponder, nil];
  [animationQueue play];
}

#pragma mark - pinch helper methods

- (NSIndexPath *)addingRowIndexPathForGestureRecognizer:(UIGestureRecognizer *)recognizer {

  if ([recognizer isKindOfClass:[UIPinchGestureRecognizer class]]) {
    // pinch
    return [self p_targetIndexPathForPinchPoints:self.startingPinchPoints];
  } else if ([recognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
    // pull down
    return self.tableViewState.modifyingRowIndexPath ?
        [NSIndexPath indexPathForRow:self.tableViewState.modifyingRowIndexPath.row inSection:0] :
        [NSIndexPath indexPathForRow:0 inSection:0];
  } else if ([recognizer isKindOfClass:[UITapGestureRecognizer class]]) {
    // tap
    return [NSIndexPath indexPathForRow:self.tableViewState.list.numberOfCompleted inSection:0];
  } else {
    // error
    NSAssert(NO, @"Gesture Recognizer 有问题");
    return nil;
  }
}

- (CGFloat)p_pinchYDistanceOfPinchGestureRecognizer:(UIPinchGestureRecognizer *)recognizer {

  LXMPinchPoints pinchPoints = [self p_normalizePinchPointsForPinchGestureRecognizer:recognizer];
  CGFloat distanceInY = (self.startingPinchPoints.upper.y - pinchPoints.upper.y) + (pinchPoints.lower.y - self.startingPinchPoints.lower.y);
  return distanceInY;
}

- (void)updateWithPinchAdding:(UIPinchGestureRecognizer *)recognizer {

  self.tableViewState.addingRowHeight = [self p_pinchYDistanceOfPinchGestureRecognizer:recognizer];
  LXMPinchPoints currentPinchPoints = [self p_normalizePinchPointsForPinchGestureRecognizer:recognizer];
  [LXMTableViewState sharedInstance].addingProgress = [self p_pinchYDistanceOfPinchGestureRecognizer:recognizer] / [LXMGlobalSettings sharedInstance].normalRowHeight;
  CGFloat upperDistance = self.startingPinchPoints.upper.y - currentPinchPoints.upper.y;
  self.tableView.contentOffset = CGPointMake(0, self.tableView.contentOffset.y + upperDistance);
}

- (void)commitOrDiscardRow {

  NSIndexPath *indexPath = [LXMTableViewState sharedInstance].addingRowIndexPath;

  // TODO: 似乎没啥用?
//  if ([self.tableViewGestureRecognizer.delegate respondsToSelector:@selector(gestureRecognizer:heightForCommitingRowAtIndexPath:)]) {
//    self.tableViewState.addingRowHeight = [self.tableViewGestureRecognizer.delegate gestureRecognizer:self.tableViewGestureRecognizer
//                                                      heightForCommitingRowAtIndexPath:self.tableViewState.addingRowIndexPath];
//  }

  BOOL shouldCommit = [LXMTableViewState sharedInstance].addingRowHeight > self.tableView.rowHeight;

  __weak LXMTableViewGestureRecognizerHelper *weakSelf = self;
  self.animationQueue.queueCompletion = ^(BOOL finished) {
    NSLog(@"100");
    // TODO: 也有可能是 modifying
    weakSelf.tableViewGestureRecognizer.operationState = weakSelf.tableViewGestureRecognizer.operationStateNormal;
    weakSelf.tableViewState.addingRowIndexPath = nil;
    weakSelf.tableViewState.addingRowHeight = 0;
  };
  if (!shouldCommit) {
    [self p_recoverRowAtIndexPath:indexPath forAdding:shouldCommit];
    [self.animationQueue play];
  } else {
    [self p_recoverRowAtIndexPath:indexPath forAdding:shouldCommit];
    [self p_replaceRowAtIndexPathToNormal:indexPath];
    [self p_assignModifyRowAtIndexPath:indexPath];
    [self.animationQueue play];
  }
}

#pragma mark - pan helper methods
- (CGFloat)panOffsetX:(UIPanGestureRecognizer *)recognizer {

  CGFloat offsetX;

  if ([recognizer translationInView:self.tableView].x > 0) {
    LXMPanOffsetXParameters completionParameters = LXMPanOffsetXParametersMake([LXMGlobalSettings sharedInstance]
        .editCommitTriggerWidth, 0.9f, 1.07f);
    offsetX = [self p_panOffsetXForParameters:completionParameters panRecognizer:recognizer];
  } else {
    LXMPanOffsetXParameters deletionParameters = LXMPanOffsetXParametersMake([LXMGlobalSettings sharedInstance]
        .editCommitTriggerWidth, 0.75f, 1.01f);
    offsetX = [self p_panOffsetXForParameters:deletionParameters panRecognizer:recognizer];
  }

  return offsetX;
}

/// pan offset, see http://lxm9.com/2016/04/19/sliding-damping-in-clear-the-app/
- (CGFloat)p_panOffsetXForParameters:(LXMPanOffsetXParameters)parameters panRecognizer:(UIPanGestureRecognizer *)recognizer{

  CGFloat offsetX;

  if (ABS([recognizer translationInView:self.tableView].x) < parameters.n) {
    offsetX = parameters.k * [recognizer translationInView:self.tableView].x;
  } else {
    if ([recognizer translationInView:self.tableView].x < 0) {
      offsetX = -((logf(-[recognizer translationInView:self.tableView].x + parameters.b) / logf(parameters.m)) + parameters.c);
    } else {
      offsetX = (logf([recognizer translationInView:self.tableView].x + parameters.b) / logf(parameters.m)) + parameters.c;
    }
  }

  return offsetX;
}

#pragma mark - rearrange helper methods

- (void)prepareForRearrange:(UILongPressGestureRecognizer *)recognizer {
  self.movingTimer = [NSTimer timerWithTimeInterval:LXMTableViewRowAnimationDurationNormal
                                             target:self
                                           selector:@selector(p_scrollTable:)
                                           userInfo:@{@"recognizer": recognizer}
                                            repeats:YES];
  [[NSRunLoop mainRunLoop] addTimer:self.movingTimer forMode:NSDefaultRunLoopMode];
}

- (void)p_scrollTable:(NSTimer *)timer {

  UILongPressGestureRecognizer *recognizer = timer.userInfo[@"recognizer"];
  CGPoint location = [recognizer locationInView:self.tableView];

  CGPoint currentContentOffset = self.tableView.contentOffset;
  CGPoint __block newContentOffset = CGPointMake(currentContentOffset.x, currentContentOffset.y + self.scrollingRate);

  // FIXME: 用线性动画块包起来执行，不会很卡，但是每经过一行，就稍有停顿。
  [UIView animateWithDuration:LXMTableViewRowAnimationDurationShort delay:0 options:UIViewAnimationCurveLinear animations:^{
    if (newContentOffset.y < -self.tableView.contentInset.top) {
      // 如果 table view 将要滚动超过顶部，就让它停在顶部。
      newContentOffset.y = 0;
    } else if (self.tableView.contentSize.height < self.tableView.frame.size.height - self.tableView.contentInset.top - self.tableView.contentInset.bottom) {
      // 如果 table view 的内容不满一屏，不改变其 contentOffset。
      newContentOffset = currentContentOffset;
    } else if (newContentOffset.y > self.tableView.contentSize.height - (self.tableView.frame.size.height - self.tableView.contentInset.top - self.tableView.contentInset.bottom)) {
      // 如果 table view 的内容已经超出一屏且将要滚动到底部。
      NSLog(@"stop scroll");
      newContentOffset.y = self.tableView.contentSize.height - (self.tableView.frame.size.height - self.tableView.contentInset.top - self.tableView.contentInset.bottom);
    } else {
      // 滚动一个 scrollingRate 的长度。（scrollingRate 有可能为零）
    }

    [self.tableView setContentOffset:newContentOffset];

    // 更新 cell 位图快照的位置，跟随手指位置。
    if (location.y >= self.tableView.contentInset.top) {
      self.snapShotView.center = CGPointMake(self.tableView.center.x, location.y);
    }
  } completion:nil];
}

- (void)updateAddingIndexPathForCurrentLocation:(UILongPressGestureRecognizer *)recognizer {

  CGPoint location = [recognizer locationInView:self.tableView];;
  NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];

  CGRect rect = self.tableView.bounds;
  location.y -= self.tableView.contentOffset.y;

  if (indexPath && ![indexPath isEqual:[LXMTableViewState sharedInstance].addingRowIndexPath]) {
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:@[[LXMTableViewState sharedInstance].addingRowIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableViewGestureRecognizer.delegate gestureRecognizer:self.tableViewGestureRecognizer needsMovePlaceholderForRowAtIndexPath:[LXMTableViewState sharedInstance].addingRowIndexPath toIndexPath:indexPath];
    [LXMTableViewState sharedInstance].addingRowIndexPath = indexPath;
    [self.tableView endUpdates];
  }

  CGFloat dropZoneHeight = self.tableView.bounds.size.height / 6;

  // FIXME: 动画速度太慢且太卡
  if (location.y > rect.size.height - dropZoneHeight) {
    self.scrollingRate = kScrollingRate2;
  } else if (location.y < dropZoneHeight) {
    self.scrollingRate = -kScrollingRate2;
  } else {
    self.scrollingRate = 0;
  }
}

- (void)finishLongPress:(UILongPressGestureRecognizer *)recognizer {

  [self.movingTimer invalidate];
  self.movingTimer = nil;
  self.scrollingRate = 0;
}

#pragma mark - table view row change method

- (void)p_recoverRowAtIndexPath:(NSIndexPath *)indexPath forAdding:(BOOL)shouldAdd {

  LXMAnimationBlock recoverHeightAnimation = ^(BOOL finished) {
    [self.tableView lxm_updateTableViewWithDuration:LXMTableViewRowAnimationDurationShort updates:^{
      [self.tableViewState.tableViewHelper recoverTableViewContentOffsetAndInset];
      self.tableViewState.addingRowHeight = shouldAdd ? self.tableView.rowHeight : 0;
    } completion:^{
//      [self.tableView reloadData];
      if (!shouldAdd) {
        [self.tableViewGestureRecognizer.delegate gestureRecognizer:self.tableViewGestureRecognizer
                                         needsDiscardRowAtIndexPath:indexPath];
        [self.tableView reloadData];
      }
      self.animationQueue.blockCompletion()(YES);
    }];
  };

  [self.animationQueue addAnimations:recoverHeightAnimation, nil];
}

- (void)p_replaceRowAtIndexPathToNormal:(NSIndexPath *)indexPath {

  LXMAnimationBlock replaceWithNoAnimation = ^(BOOL finished) {
    [UIView performWithoutAnimation:^{
      [self.tableViewGestureRecognizer.delegate gestureRecognizer:self.tableViewGestureRecognizer
                                        needsCommitRowAtIndexPath:indexPath];
      [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }];
//    [self.tableView reloadData];
    NSLog(@"reload");
    self.animationQueue.blockCompletion()(YES);
  };

  [self.animationQueue addAnimations:replaceWithNoAnimation, nil];
}

- (void)p_assignModifyRowAtIndexPath:(NSIndexPath *)indexPath {

  LXMAnimationBlock assignRowAnimation = ^(BOOL finished){
    LXMTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (!cell.todoItem.isCompleted) {
      [cell.strikeThroughText becomeFirstResponder];
    }
    self.animationQueue.blockCompletion()(YES);
  };

  [self.animationQueue addAnimations:assignRowAnimation, nil];
}


- (void)moveRowAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath {

  LXMTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
  if (cell.todoItem.isCompleted) {
    cell.actualContentView.backgroundColor = [self.tableViewHelper colorForRowAtIndexPath:indexPath];
    cell.strikeThroughText.textColor = [self.tableViewHelper textColorForRowAtIndexPath:indexPath];
  }

//  [self.tableViewState.floatingCells insertObject:cell atIndex:0];
  [self.tableViewState.floatingIndexPaths insertObject:newIndexPath atIndex:0];

  void (^completionBlock)(void) = ^{
//    [self.tableViewState.floatingCells removeLastObject];
    [self.tableViewState.floatingIndexPaths removeLastObject];
    [[NSNotificationCenter defaultCenter] postNotificationName:LXMOperationCompleteNotification object:self];
//    if (self.tableViewState.uneditableIndexPaths.count == 0) {
    if (self.tableViewState.uneditableIndexPaths2.count == 0) {
      [[NSNotificationCenter defaultCenter] postNotificationName:LXMOperationCompleteNotification object:self];
      [self.tableView reloadData];
    }
  };

  NSIndexPath *firstVisibleIndexPath = [self.tableView indexPathForCell:[self.tableView.visibleCells firstObject]];
  NSIndexPath *lastVisibleIndexPath = [self.tableView indexPathForCell:[self.tableView.visibleCells lastObject]];

//  if (newIndexPath.row > lastVisibleIndexPath.row || newIndexPath.row < firstVisibleIndexPath.row) {
//    NSIndexPath *tempTargetIndexPath;
//    if (newIndexPath.row > lastVisibleIndexPath.row) {
//      tempTargetIndexPath = lastVisibleIndexPath;
//    } else {
//      tempTargetIndexPath = firstVisibleIndexPath;
//    }
//
//    [UIView beginAnimations:nil context:nil];
//    [UIView setAnimationDuration:LXMTableViewRowAnimationDurationNormal];
//    [CATransaction begin];
//    [CATransaction setCompletionBlock:^{
//      LXMTodoItem *tempItem = self.list.todoItems[tempTargetIndexPath.row];
//      [self.list.todoItems removeObjectAtIndex:tempTargetIndexPath.row];
//      [self.list.todoItems insertObject:tempItem atIndex:newIndexPath.row];
//      completionBlock();
//    }];
//    LXMTodoItem *tempItem = self.list.todoItems[indexPath.row];
//    [self.list.todoItems removeObjectAtIndex:indexPath.row];
//    [self.list.todoItems insertObject:tempItem atIndex:tempTargetIndexPath.row];
//    [self.tableView moveRowAtIndexPath:indexPath toIndexPath:tempTargetIndexPath];
//    [CATransaction commit];
//    [UIView commitAnimations];
//  } else {
  LXMTodoItem *tempItem = self.list.todoItems[indexPath.row];
  [self.list.todoItems removeObjectAtIndex:indexPath.row];
  [self.list.todoItems insertObject:tempItem atIndex:newIndexPath.row];
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationDuration:LXMTableViewRowAnimationDurationNormal];
  [CATransaction begin];
  [CATransaction setCompletionBlock:completionBlock];
  [self.tableView moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
  [CATransaction commit];
  [UIView commitAnimations];
//  }
}

@end