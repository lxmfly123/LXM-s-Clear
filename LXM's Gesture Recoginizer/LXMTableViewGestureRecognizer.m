//
//  LXMTableViehGestureRecognizer.m
//  LXM's Gesture Recoginizer
//
//  Created by FLY.lxm on 3/22/16.
//  Copyright © 2016 FLY.lxm. All rights reserved.
//

#import "LXMTableViewGestureRecognizer.h"
#import "LXMTableViewCell.h"
#import "NSArray+LXMTableViewGestureRecognizerHelper.h"
#import "LXMGlobalSettings.h"
#import "LXMTransformableTableViewCell.h"
#import "LXMTodoList.h"
#import "LXMTableViewOperationState.h"
#import <pop/POP.h>

typedef struct {
  CGPoint upper;
  CGPoint lower;
} LXMPinchPoints;

typedef struct {
  CGFloat n;
  CGFloat k;
  CGFloat m;
  CGFloat b;
  CGFloat c;
} LXMPanOffsetXParameters;

CG_INLINE LXMPanOffsetXParameters LXMPanOffsetXParametersMake(CGFloat n, CGFloat k, CGFloat m) {

  CGFloat b = (1 - k * n * logf(m)) / (k * logf(m));
  CGFloat c = k * n - logf(n + b) / logf(m);
  return (LXMPanOffsetXParameters){n, k, m, b, c};
} ///< Make a offset curve from '(n, k, m)'. see http://lxm9.com/2016/04/19/sliding-damping-in-clear-the-app/

NSTimeInterval const LXMTableViewRowAnimationDurationShort = 0.15;
NSTimeInterval const LXMTableViewRowAnimationDurationNormal = 0.25;
NSTimeInterval const LXMTableViewRowAnimationDurationLong = 0.50;

CGFloat const kScrollingRate = 10.0f; ///< 当长按拖动 todo 并移动到 table view 顶部或底部时，table view 的滚动速度。

#define CELL_SNAPSHOT_TAG 100000

@interface LXMTableViewGestureRecognizer () <UIGestureRecognizerDelegate>

@property (nonatomic, weak, readwrite) UITableView *tableView;
@property (nonatomic, weak) id tableViewDelegate;
@property (nonatomic, weak) LXMTableViewState *tableViewState;
@property (nonatomic, assign) LXMTableViewGestureRecognizerState state;
@property (nonatomic, assign) LXMTableViewGestureRecognizerState previousState;
@property (nonatomic, assign) LXMTableViewGestureRecognizerOptions options;

@property (nonatomic, strong) UITapGestureRecognizer *tapRecognizer;
@property (nonatomic, strong) UIPinchGestureRecognizer *pinchRecognizer;
@property (nonatomic, strong) UIPanGestureRecognizer *panRecognizer;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressRecognizer;

@property (nonatomic, strong) LXMTableViewOperationState *state2;
@property (nonatomic, strong) LXMTableViewOperationState *normalState;

@property (nonatomic, strong) NSMutableArray *operationStates;
// ...

#pragma mark Pinch Helper Properties
@property (nonatomic, assign) LXMPinchPoints startingPinchPoints;
@property (nonatomic, assign) CGPoint lastTapPoints;

#pragma mark LongPress Helper Properties
/// 每 0.125 秒判断一次是否需要滚动 tableView。
@property (nonatomic, strong) NSTimer *movingTimer;
/// tableView 的滚动速率，单位 px/sec。
@property (nonatomic, assign) CGFloat scrollingRate;
/// 正在被拖动的 cell 的位图快照。
@property (nonatomic, strong) UIImage *cellSnapshot;

@end

@implementation LXMTableViewGestureRecognizer

@synthesize operationState = _operationState;

+ (instancetype)gestureRecognizerWithTableView:(UITableView *)tableView delegate:(id)delegate {
  LXMTableViewGestureRecognizer *recognizer = [LXMTableViewGestureRecognizer new];
  recognizer.delegate = delegate;
  recognizer.tableView = tableView;
  recognizer.tableViewDelegate = tableView.delegate;
  recognizer.operationStates = [[NSMutableArray alloc] initWithCapacity:10];
  [recognizer allowAllGestures];
  tableView.delegate = recognizer;

  [recognizer configureGestureRecognizers];
//  [recognizer adjustTableViewFrame];

  return recognizer;
}

- (void)dealloc {

  [[NSNotificationCenter defaultCenter] removeObserver:self.panRecognizer];
}

#pragma mark - Init Helper Methods

- (void)configureGestureRecognizers {

  NSAssert(self.tableView, @"Table View does not exist. ");

  // tap recognizer
  self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
  [self.tableView addGestureRecognizer:self.tapRecognizer];

  // pinch recognizer
  self.pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
  self.pinchRecognizer.delegate = self;
  [self.tableView addGestureRecognizer:self.pinchRecognizer];

  // pan recognizer
  self.panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
  self.panRecognizer.delegate = self;
  [self.tableView addGestureRecognizer:self.panRecognizer];

  // 注册响应操作完成的通知，将相关状态值设置为初始值。
  [[NSNotificationCenter defaultCenter]
   addObserverForName:LXMOperationCompleteNotification
   object:nil
   queue:nil
   usingBlock:^(NSNotification * _Nonnull note) {
//     [LXMTableViewState sharedInstance].operationState = LXMTableViewOperationStateCodeNormal;
     self.state = LXMTableViewGestureRecognizerStateNone;
   }];

  //long press recognizer
  UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
  longPressRecognizer.delegate = self;
  self.longPressRecognizer = longPressRecognizer;
  [self.tableView addGestureRecognizer:self.longPressRecognizer];
}

- (void)adjustTableViewFrame {

  NSAssert(self.tableView, @"Table View does not exist. ");

  self.tableView.contentInset =
  UIEdgeInsetsMake(self.tableView.rowHeight * 2,
                   self.tableView.contentInset.left,
                   self.tableView.rowHeight * 2,
                   self.tableView.contentInset.right);

  self.tableView.frame =
  CGRectMake(
             self.tableView.frame.origin.x,
             self.tableView.frame.origin.y - self.tableView.contentInset.top,
             self.tableView.frame.size.width,
             self.tableView.bounds.size.height + self.tableView.contentInset.top + self.tableView.contentInset.bottom);

}

- (void)p_modifyRowAtIndexPath:(NSIndexPath *)indexPath {

  LXMTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
  [cell.strikeThroughText becomeFirstResponder];
}

#pragma mark - setters

- (void)setOperationState:(id <LXMTableViewOperationStateProtocol>)operationState {

  _operationState = operationState;

  if (operationState == self.operationStateNormal) {
    [self allowAllGestures];
  } else if (operationState == self.operationStateRecovering) {
    [self denyAllGestures];
  } else if (operationState == self.operationStateProcessing) {
    [self allowGesturesOnly:LXMTableViewGestureRecognizerOptionsTap | LXMTableViewGestureRecognizerOptionsHorizontalPan];
  } else if (operationState == self.operationStateModifying) {
    [self allowGesturesOnly:LXMTableViewGestureRecognizerOptionsTap | LXMTableViewGestureRecognizerOptionsVerticalPan];
  }
}

#pragma mark - getters

- (LXMTableViewGestureRecognizerHelper *)helper {

  if (!_helper) {
    _helper = [[LXMTableViewGestureRecognizerHelper alloc] initWithGestureRecognizer:self];
  }

  return _helper;
}

- (id <LXMTableViewOperationStateProtocol>)operationState {

  if (!_operationState) {
     _operationState = self.operationStateNormal;
  }

  return _operationState;
}

- (id <LXMTableViewOperationStateProtocol>)operationStateNormal {

  if (!_operationStateNormal) {
    _operationStateNormal = [LXMTableViewOperationState operationStateWithTableViewGestureRecognizer:self operationStateCode:LXMTableViewOperationStateCodeNormal];
  }

  return _operationStateNormal;
}

- (id <LXMTableViewOperationStateProtocol>)operationStatePinchAdding {

  if (!_operationStatePinchAdding) {
    _operationStatePinchAdding = [LXMTableViewOperationState operationStateWithTableViewGestureRecognizer:self operationStateCode:LXMTableViewOperationStateCodePinchAdding];
  }

  return _operationStatePinchAdding;
}

- (id <LXMTableViewOperationStateProtocol>)operationStateRecovering{

  if (!_operationStateRecovering) {
    _operationStateRecovering = [LXMTableViewOperationState operationStateWithTableViewGestureRecognizer:self operationStateCode:LXMTableViewOperationStateCodeRecovering];
  }

  return _operationStateRecovering;
}

//- (void)setState:(LXMTableViewGestureRecognizerState)state {
//
//  _previousState = _state;
//
//  switch (state) {
//    case LXMTableViewGestureRecognizerStateNone:
//      [self allowAllGestures];
//      // TODO: Clear State
//      self.tableViewState.addingRowHeight = 0;
//      self.tableViewState.addingRowIndexPath = nil;
//      break;
//
//    case LXMTableViewGestureRecognizerStateScalingUp:
//    case LXMTableViewGestureRecognizerStateScalingDown:
//      [self allowGesturesOnly:LXMTableViewGestureRecognizerOptionsPinch];
//      break;
//
//    case LXMTableViewGestureRecognizerStateChecking:
//    case LXMTableViewGestureRecognizerStateDeleting:
//      [self allowGesturesOnly:LXMTableViewGestureRecognizerOptionsHorizontalPan | LXMTableViewGestureRecognizerOptionsVerticalPan];
//      break;
//
//    case LXMTableViewGestureRecognizerStateRearranging:
//      [self allowGesturesOnly:LXMTableViewGestureRecognizerOptionsLongPress];
//      break;
//
//    case LXMTableViewGestureRecognizerStateWaiting:
//      [self denyAllGestures];
//      break;
//
////    case LXMTableViewGestureRecognizerStateTapDone: {
////      switch (_previousState) {
////        case LXMTableViewGestureRecognizerStateNone: {
////          if ([self.tableView indexPathForRowAtPoint:self.lastTapPoints]) {
////
////          }
////
////        }
////      }
////    }
//
//    case LXMTableViewGestureRecognizerStateListening: {
//      switch (_previousState) {
//        case LXMTableViewGestureRecognizerStateNone:
//          break;
//
//        case LXMTableViewGestureRecognizerStateScalingUp:
//          [self denyAllGestures];
//
//          case L
//
//      }
//    }
//  }
//
//  _state = state;
//}


#pragma mark  - getters

#pragma mark - options method

- (void)allowAllGestures {
  _options = LXMTableViewGestureRecognizerOptionsTap |
             LXMTableViewGestureRecognizerOptionsPinch |
             LXMTableViewGestureRecognizerOptionsHorizontalPan |
             LXMTableViewGestureRecognizerOptionsVerticalPan |
             LXMTableViewGestureRecognizerOptionsLongPress;

  _state = LXMTableViewGestureRecognizerStateNone;
}

- (void)denyAllGestures {

  _options = 0;
}

- (void)allowGestures:(LXMTableViewGestureRecognizerOptions)options {

  _options = _options | options;
}

- (void)denyGestures:(LXMTableViewGestureRecognizerOptions)options {

  _options = _options & (~options);
}

- (void)allowGesturesOnly:(LXMTableViewGestureRecognizerOptions)options {

  _options = options;
}

- (void)denyGesturesOnly:(LXMTableViewGestureRecognizerOptions)options {

  [self allowAllGestures];
  [self denyGestures:options];
}

- (BOOL)isGesturesAllowed:(LXMTableViewGestureRecognizerOptions)options {

  for (int i = 1; i <= 5; ++i) {
    if ([self nthBit:i ofOptions:options] == 1 &&
        [self nthBit:i ofOptions:_options] != 1) {
      return NO;
    }
  }

  return YES;
}

/// 获取 options 的二进制表示的第 n 位。从右向左，首位为第 1 位，YES 表示 1, NO 表示 0。
- (BOOL)nthBit:(NSUInteger)n ofOptions:(LXMTableViewGestureRecognizerOptions)options {

  NSUInteger bitValue;

  if (n == 1) {
    bitValue = options % (1 << 1);
  } else {
    bitValue = (options >> (n - 1)) % (1 << 1);
  }

  return bitValue == 1 ? YES : NO;
}

#pragma mark - Gesture Recognizer Helper Methods

- (void)p_collectGestureStartingInformation:(UIGestureRecognizer *)recognizer {

  if (recognizer == self.pinchRecognizer) {
    [[LXMTableViewState sharedInstance] saveTableViewLastContentOffsetAndInset];
    self.startingPinchPoints = [self normalizePinchPointsForPinchGestureRecognizer:self.pinchRecognizer];
    [LXMTableViewState sharedInstance].addingRowIndexPath = [self targetIndexPathForPinchPoints:[self normalizePinchPointsForPinchGestureRecognizer:self.pinchRecognizer]];
  } else if (recognizer == self.panRecognizer) {
    NSIndexPath *panningIndexPath = [self.tableView indexPathForRowAtPoint:[self.panRecognizer locationInView:self.tableView]];
//    [LXMTableViewState sharedInstance].panningCell = [self.tableView cellForRowAtIndexPath:panningIndexPath];
  } else if (self.state == LXMTableViewGestureRecognizerStateMoving) {
    // TODO: longpress
  }
}

- (void)clearGestureStartingInformation {

  if (self.state == LXMTableViewGestureRecognizerStatePinching) {
//    self.startingTableViewContentOffset = CGPointZero;
//    self.startingTableViewContentInset = UIEdgeInsetsZero;
//    [LXMTableViewState sharedInstance].lastContentOffset = CGPointZero;
//    [LXMTableViewState sharedInstance].lastContentInset = UIEdgeInsetsZero;
    self.startingPinchPoints = (LXMPinchPoints){{0, 0}, {0, 0}};
    [LXMTableViewState sharedInstance].addingRowIndexPath = nil;
  } else if (self.state == LXMTableViewGestureRecognizerStatePanning) {
//    [LXMTableViewState sharedInstance].panningCell = nil;
  } else if (self.state == LXMTableViewGestureRecognizerStateMoving) {
    // TODO: longpress
  }
}

- (LXMPinchPoints)normalizePinchPointsForPinchGestureRecognizer:(UIPinchGestureRecognizer *)recognizer {

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

- (NSIndexPath *)targetIndexPathForPinchPoints:(LXMPinchPoints)pinchPoints {

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

- (CGFloat)pinchDistanceYOfPinchGestureRecognizer:(UIPinchGestureRecognizer *)recognizer {

  LXMPinchPoints pinchPoints = [self normalizePinchPointsForPinchGestureRecognizer:recognizer];
  CGFloat distanceInY = (self.startingPinchPoints.upper.y - pinchPoints.upper.y) + (pinchPoints.lower.y - self.startingPinchPoints.lower.y);
  return distanceInY;
}

#pragma mark - long press gesture recognizer helper methods

- (void)updateAddingIndexPathForCurrentLocation {

  CGPoint location = [self.longPressRecognizer locationInView:self.tableView];;
  NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];

  // FIXME: addingCell 只出现了一次，似乎没啥用？
  if (indexPath && ![indexPath isEqual:[LXMTableViewState sharedInstance].addingCell]) {
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:@[[LXMTableViewState sharedInstance].addingRowIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    [self.delegate gestureRecognizer:self needsMovePlaceholderForRowAtIndexPath:[LXMTableViewState sharedInstance].addingRowIndexPath toIndexPath:indexPath];
    [LXMTableViewState sharedInstance].addingRowIndexPath = indexPath;
    [self.tableView endUpdates];
  }
}

/// 由 movingTimer 定期调用，按 scrollingRate 滚动 table view。
- (void)scrollTable {

  CGPoint location = [self.longPressRecognizer locationInView:self.tableView];

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
      UIImageView *cellSnapshot = [self.tableView viewWithTag:CELL_SNAPSHOT_TAG];
      cellSnapshot.center = CGPointMake(self.tableView.center.x, location.y);
    }
  } completion:nil];

}

/// pan offset, see http://lxm9.com/2016/04/19/sliding-damping-in-clear-the-app/
- (CGFloat)panOffsetXForParameters:(LXMPanOffsetXParameters)parameters {

  CGFloat offsetX;

  if (ABS([self.panRecognizer translationInView:self.tableView].x) < parameters.n) {
    offsetX = parameters.k * [self.panRecognizer translationInView:self.tableView].x;
  } else {
    if ([self.panRecognizer translationInView:self.tableView].x < 0) {
      offsetX = -((logf(-[self.panRecognizer translationInView:self.tableView].x + parameters.b) / logf(parameters.m)) + parameters.c);
    } else {
      offsetX = (logf([self.panRecognizer translationInView:self.tableView].x + parameters.b) / logf(parameters.m)) + parameters.c;
    }
  }

  return offsetX;
}

- (void)commitOrDiscardCell {

  CGFloat committingCellHeight = [LXMTableViewState sharedInstance].addingRowHeight;
  NSIndexPath *committingCellIndexPath = [LXMTableViewState sharedInstance].addingRowIndexPath;
  [LXMTableViewState sharedInstance].addingRowIndexPath = nil;
  [LXMTableViewState sharedInstance].addingRowHeight = 0;

  if ([self.delegate respondsToSelector:@selector(gestureRecognizer:heightForCommitingRowAtIndexPath:)]) {
    committingCellHeight = [self.delegate gestureRecognizer:self heightForCommitingRowAtIndexPath:committingCellIndexPath];
  }

  if (committingCellHeight < self.tableView.rowHeight) {
    [self.delegate gestureRecognizer:self needsDiscardRowAtIndexPath:committingCellIndexPath];
  } else {
    [self.delegate gestureRecognizer:self needsCommitRowAtIndexPath:committingCellIndexPath];
  }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)recognizer {

  if (recognizer == self.tapRecognizer && [self isGesturesAllowed:LXMTableViewGestureRecognizerOptionsTap]) {
    // Tap
    [self.helper collectStartingInformation:recognizer];
    return YES;
  } else if (recognizer == self.pinchRecognizer && [self isGesturesAllowed:LXMTableViewGestureRecognizerOptionsPinch]) {
    // Pinch
    if (![self.delegate conformsToProtocol:@protocol(LXMTableViewGestureAddingRowDelegate)]) {
      NSLog(@"Not conforms to protocal, pinch should not begin.");
      return NO;
    } else {
      self.tableViewState.addingRowIndexPath = [self targetIndexPathForPinchPoints:[self normalizePinchPointsForPinchGestureRecognizer:(UIPinchGestureRecognizer *)recognizer]];

      if (![self.delegate gestureRecognizer:self canAddCellAtIndexPath:self.tableViewState.addingRowIndexPath]) {
        return NO;
      }

      if ([self.delegate respondsToSelector:@selector(gestureRecognizer:willCreateCellAtIndexPath:)]) {
        [self.delegate gestureRecognizer:self willCreateCellAtIndexPath:self.tableViewState.addingRowIndexPath];
      }

      [self.helper collectStartingInformation:recognizer];
      return YES;
    }
  } else if (recognizer == self.panRecognizer && [self isGesturesAllowed:LXMTableViewGestureRecognizerOptionsHorizontalPan]) {
    // Pan
    if (![self.delegate conformsToProtocol:@protocol(LXMTableViewGestureEditingRowDelegate)]) {
      return NO;
    }

    CGPoint translation = [self.panRecognizer translationInView:self.tableView];
    CGPoint location = [self.panRecognizer locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    BOOL isSlidingHorizontally = fabs(translation.x) > fabs(translation.y);
    BOOL canEdit = [self.delegate gestureRecognizer:self canEditRowAtIndexPath:indexPath];

    if (!indexPath) {
      NSLog(@"no indexpath");
      return NO;
    }

    if (!canEdit) {
      NSLog(@"can not edit row");
      return NO;
    }

    if (!isSlidingHorizontally) {
      return NO;
    }

    if (![self isGesturesAllowed:LXMTableViewGestureRecognizerOptionsHorizontalPan]) {
      return NO;
    }

    [self.helper collectStartingInformation:recognizer];
    return YES;

  } else if (recognizer == self.longPressRecognizer && [self isGesturesAllowed:LXMTableViewGestureRecognizerOptionsLongPress]) {
    // TODO: longPressRecognizer
    [self.helper collectStartingInformation:recognizer];
    return YES;
  } else {
    return NO;
  }
}

#pragma mark - animation

- (void)insertRowAtIndexPath:(NSIndexPath *)indexPath forUsage:(LXMTodoItemUsage)usage {

  void (^insertRow)() = ^{
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
  };

  void (^insertRowWithoutAnimation)() = ^{
    [UIView performWithoutAnimation:^{
      insertRow();
    }];
  };

  switch (usage) {
    case LXMTodoItemUsagePinchAdded:
    case LXMTodoItemUsagePullAdded:
      // 仅插入行即可。
      insertRowWithoutAnimation();
      break;

    case LXMTodoItemUsageTapAdded: {

      insertRowWithoutAnimation();

      POPAnimatableProperty *prop = [POPAnimatableProperty propertyWithName:@"test" initializer:^(POPMutableAnimatableProperty *prop) {
        prop.writeBlock = ^(id obj, const CGFloat values[]) {
          [self.tableView beginUpdates];
          self.tableViewState.addingRowHeight = values[0];
          [self.tableView endUpdates];
        };
      }];

      POPBasicAnimation *anim = [POPBasicAnimation easeInEaseOutAnimation];
      anim.property = prop;
      anim.fromValue = @(0);
      anim.toValue = @(self.tableView.rowHeight);
      anim.duration = LXMTableViewRowAnimationDurationNormal;
      anim.completionBlock = ^(POPAnimation *animation, BOOL finished) {
//        [self p_recoverRowAtIndexPath:indexPath withBlock:nil forAdding:YES];
//        [self p_replaceRowAtIndexPathToNormal:indexPath];
//        [self p_assignModifyRowAtIndexPath:indexPath];
//        [self.animationQueue play];
      };
      anim.beginTime = CACurrentMediaTime();

      [self pop_addAnimation:anim forKey:@"LXMKey"];
    }
      break;

    case LXMTodoItemUsagePlaceholder:
    case LXMTodoItemUsageNormal:
      insertRowWithoutAnimation();
      // TODO: 是否需要实现 placeholer 和 normal?
      break;
  }
}

#pragma mark - Gesture Handlers

- (void)assign:(UITextField *)textField {
  [textField becomeFirstResponder];
}

- (void)handleTap:(UITapGestureRecognizer *)recognizer {

  if (recognizer.state == UIGestureRecognizerStateEnded) {

    CGPoint location = [recognizer locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    LXMTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];

//    if ([LXMTableViewState sharedInstance].operationState == LXMTableViewOperationStateCodeNormal) {
    if ([cell isMemberOfClass:[LXMTableViewCell class]] && !cell.todoItem.isCompleted) {
      [cell.strikeThroughText becomeFirstResponder];
    } else {
      [LXMTableViewState sharedInstance].addingRowIndexPath = [NSIndexPath indexPathForRow:[LXMTableViewState sharedInstance].todoList.numberOfUncompleted inSection:0];
      [LXMTableViewState sharedInstance].addingRowHeight = 0;
      [self.delegate gestureRecognizer:self needsAddRowAtIndexPath:[LXMTableViewState sharedInstance].addingRowIndexPath usage:LXMTodoItemUsageTapAdded];
    }
  } else {
    [self.tableView endEditing:YES];
  }
}


- (void)handlePinch:(UIPinchGestureRecognizer *)recognizer {

  [self.operationState handlePinch:recognizer];
}

/*

- (void)handlePinch:(UIPinchGestureRecognizer *)recognizer {

  if (recognizer.state == UIGestureRecognizerStateBegan) {
    self.state = LXMTableViewGestureRecognizerStatePinching;
    [self p_collectGestureStartingInformation:recognizer];
    NSAssert([LXMTableViewState sharedInstance].addingRowIndexPath != nil, @"self.addingIndexPath must not be nil, we should have set it in recognizerShouldBegin");
    self.tableView.contentInset =
        UIEdgeInsetsMake(self.tableView.contentInset.top + self.tableView.bounds.size.height,
                         self.tableView.contentInset.left,
                         self.tableView.contentInset.bottom + self.tableView.bounds.size.height,
                         self.tableView.contentInset.right);

    [LXMTableViewState sharedInstance].addingRowHeight = 0;
    [self.delegate gestureRecognizer:self needsAddRowAtIndexPath:[LXMTableViewState sharedInstance].addingRowIndexPath usage:LXMTodoItemUsagePinchAdded];
  } else if (recognizer.state == UIGestureRecognizerStateChanged && recognizer.numberOfTouches >= 2) {

    [LXMTableViewState sharedInstance].addingRowHeight = [self pinchDistanceYOfPinchGestureRecognizer:recognizer];
    LXMPinchPoints currentPinchPoints = [self normalizePinchPointsForPinchGestureRecognizer:recognizer];
    [LXMTableViewState sharedInstance].addingProgress = [self pinchDistanceYOfPinchGestureRecognizer:recognizer] / [LXMGlobalSettings sharedInstance].normalRowHeight;
    CGFloat upperDistance = self.startingPinchPoints.upper.y - currentPinchPoints.upper.y;
    self.tableView.contentOffset = CGPointMake(0, self.tableView.contentOffset.y + upperDistance);

//    if ([LXMTableViewState sharedInstance].addingProgress >= 0 && [LXMTableViewState sharedInstance].addingProgress <= 1) {
//      [LXMTableViewState sharedInstance].addingRowHeight = [self pinchDistanceYOfPinchGestureRecognizer:recognizer] or 20;
//      self.tableView.contentOffset = CGPointMake(0, self.tableView.contentOffset.y + upperDistance);
//    } else if ([LXMTableViewState sharedInstance].addingProgress > 1) {
//      [LXMTableViewState sharedInstance].addingRowHeight = [self pinchDistanceYOfPinchGestureRecognizer:recognizer];
//      self.tableView.contentOffset = CGPointMake(0, self.tableView.contentOffset.y + upperDistance);
//    } else {
//      [LXMTableViewState sharedInstance].addingRowHeight = 0;
//      // TODO: pinch transform to totolist view
//    }
    if ([self.delegate respondsToSelector:@selector(gestureRecognizer:isAddingRowAtIndexPath:)]) {
      [self.delegate gestureRecognizer:self isAddingRowAtIndexPath:[LXMTableViewState sharedInstance].addingRowIndexPath];
    }
    [UIView performWithoutAnimation:^{
      // FIXME: bug ———— 使用 updates 系列方法后，cell 文字不会随高度变化。
      [self.tableView beginUpdates];
      [self.tableView reloadRowsAtIndexPaths:@[[LXMTableViewState sharedInstance].addingRowIndexPath] withRowAnimation:UITableViewRowAnimationNone];
      [self.tableView endUpdates];
    }];
  } else if (recognizer.state == UIGestureRecognizerStateEnded || [recognizer numberOfTouches] < 2) {
    [self denyAllGestures];
    if ([LXMTableViewState sharedInstance].addingRowIndexPath) {
      [self commitOrDiscardRow];
    }
  } else {
//    self.state = LXMTableViewGestureRecognizerStateNone;
    [LXMTableViewState sharedInstance].operationState = LXMTableViewOperationStateCodeNormal;
    [self allowAllGestures];
    NSLog(@"Whoops... Something unexpected happened while pinching. ");
    // TODO: show a alert?
  }
}*/

- (void)handlePan:(UIPanGestureRecognizer *)recognizer {

  static LXMTableViewCellEditingState lastEditingState = LXMTableViewCellEditingStateNone;
  static NSIndexPath *panningIndexPath;
  static LXMTableViewCell *panningCell;

  if (recognizer.state == UIGestureRecognizerStateBegan) {
    self.state = LXMTableViewGestureRecognizerStatePanning;
    [self p_collectGestureStartingInformation:recognizer];
    panningCell = [LXMTableViewState sharedInstance].panningCell;
    panningIndexPath = [self.tableView indexPathForCell:panningCell];
  } else if (recognizer.state == UIGestureRecognizerStateChanged) {
    CGFloat offsetX;
    if ([recognizer translationInView:self.tableView].x > 0) {
      LXMPanOffsetXParameters completionParameters = LXMPanOffsetXParametersMake([LXMGlobalSettings sharedInstance]
          .editCommitTriggerWidth, 0.9f, 1.07f);
      offsetX = [self panOffsetXForParameters:completionParameters];
    } else {
      LXMPanOffsetXParameters deletionParameters = LXMPanOffsetXParametersMake([LXMGlobalSettings sharedInstance]
          .editCommitTriggerWidth, 0.75f, 1.01f);
      offsetX = [self panOffsetXForParameters:deletionParameters];
    }

//    [LXMTableViewState sharedInstance].operationState = offsetX > 0 ? LXMTableViewOperationStateCodeChecking : LXMTableViewOperationStateCodeDeleting;

    panningCell.actualContentView.frame = CGRectOffset(panningCell.contentView.bounds, offsetX, 0);
    [panningCell setNeedsLayout];

    if (offsetX > [LXMGlobalSettings sharedInstance].editCommitTriggerWidth) {
      if (lastEditingState != LXMTableViewCellEditingStateWillCheck) {
        NSLog(@"completing");
        lastEditingState = LXMTableViewCellEditingStateWillCheck;
      }
    } else if (offsetX < - [LXMGlobalSettings sharedInstance].editCommitTriggerWidth) {
      if (lastEditingState != LXMTableViewCellEditingStateWillDelete) {
        NSLog(@"deleting");
        lastEditingState = LXMTableViewCellEditingStateWillDelete;
      }
    } else {
      if (lastEditingState != LXMTableViewCellEditingStateNormal) {
        NSLog(@"normal");
        lastEditingState = LXMTableViewCellEditingStateNormal;
      }
    }
    panningCell.editingState = lastEditingState;

    [self.delegate gestureRecognizer:self
                   didEnterEditingState:lastEditingState
                   forRowAtIndexPath:panningIndexPath];
  } else if (recognizer.state == UIGestureRecognizerStateEnded) {
//    self.state = LXMTableViewGestureRecognizerStateNone;
    [self allowAllGestures];
    if (lastEditingState == LXMTableViewCellEditingStateWillDelete) {
//      self.state = LXMTableViewGestureRecognizerStateNoInteracting;
      [self allowGesturesOnly:LXMTableViewGestureRecognizerOptionsVerticalPan | LXMTableViewGestureRecognizerOptionsTap];
    }
    panningCell.editingState = LXMTableViewCellEditingStateNone;
    [self.delegate gestureRecognizer:self
                   didCommitEditingState:lastEditingState
                   forRowAtIndexPath:panningIndexPath];
  }
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)longPressRecognizer {

  CGPoint location = [longPressRecognizer locationInView:self.tableView];
  NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];

  if (longPressRecognizer.state == UIGestureRecognizerStateBegan) {
    NSLog(@"Start moving.");
    self.state = LXMTableViewGestureRecognizerStateMoving;
//    [LXMTableViewState sharedInstance].operationState = LXMTableViewOperationStateCodeRearranging;

    // 获取拖动 cell 的位图快照。
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    UIGraphicsBeginImageContextWithOptions(cell.bounds.size, NO, 0);
    [cell.layer renderInContext:UIGraphicsGetCurrentContext()];
    self.cellSnapshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    // 将位图快照作为 UIImageView 覆盖显示在拖动 cell 的位置上。
    UIImageView *snapshotView = [self.tableView viewWithTag:CELL_SNAPSHOT_TAG];
    if (!snapshotView) {
      snapshotView = [[UIImageView alloc] initWithImage:self.cellSnapshot];
      snapshotView.tag = CELL_SNAPSHOT_TAG;
      [self.tableView addSubview:snapshotView];
      snapshotView.frame = [self.tableView rectForRowAtIndexPath:indexPath];
    }

    // （动画）将快照长宽放大至 1.1 倍。
    [UIView beginAnimations:@"zoonCell" context:nil];
    snapshotView.transform = CGAffineTransformMakeScale(1.1, 1.1);
    snapshotView.center = CGPointMake(self.tableView.center.x, location.y);
    [UIView commitAnimations];

    // 在原位置创建占位行。
    // TODO: 可以全放在代理方法里。
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    [self.delegate gestureRecognizer:self needsCreatePlaceholderForRowAtIndexPath:indexPath];
    [LXMTableViewState sharedInstance].addingRowIndexPath = indexPath;
    [self.tableView endUpdates];

    // 设置每 0.15 秒检测一次当前位置，按需要滚动 table view。
    // TODO: 动画卡，应该放在 NSDisplayLink 中。
    self.movingTimer = [NSTimer timerWithTimeInterval:LXMTableViewRowAnimationDurationShort target:self selector:@selector(scrollTable)
                                             userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.movingTimer forMode:NSDefaultRunLoopMode];

  } else if (longPressRecognizer.state == UIGestureRecognizerStateEnded) {
    __weak __block UIImageView *snapshotView = [self.tableView viewWithTag:CELL_SNAPSHOT_TAG];
    __weak __block LXMTableViewGestureRecognizer *weakSelf = self;
    __weak __block NSIndexPath *indexPath = [LXMTableViewState sharedInstance].addingRowIndexPath;

    [self.movingTimer invalidate];
    self.movingTimer = nil;
    self.scrollingRate = 0;

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
        weakSelf.cellSnapshot = nil;
        [LXMTableViewState sharedInstance].addingRowIndexPath = nil;
        [[NSNotificationCenter defaultCenter] postNotificationName:LXMOperationCompleteNotification object:self];
      }];
      [weakSelf.tableView beginUpdates];
      [weakSelf.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
      [weakSelf.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
      [weakSelf.delegate gestureRecognizer:self needsReplacePlaceholderForRowAtIndexPath:indexPath];
      [weakSelf.tableView endUpdates];
      [CATransaction commit];
      [UIView commitAnimations];
    }];
  } else if (longPressRecognizer.state == UIGestureRecognizerStateChanged) {
    // 随手指移动 cell 快照，当移动到 table view 顶部或者底部时，滚动 table view。
    UIImageView *snapshotView = [self.tableView viewWithTag:CELL_SNAPSHOT_TAG];
    snapshotView.center = CGPointMake(self.tableView.center.x, location.y);

    CGRect rect = self.tableView.bounds;
    CGPoint location = [self.longPressRecognizer locationInView:self.tableView];
    location.y -= self.tableView.contentOffset.y;
    [self updateAddingIndexPathForCurrentLocation];

    CGFloat dropZoneHeight = self.tableView.bounds.size.height / 6;

    // FIXME: 动画速度太慢且太卡
    if (location.y > rect.size.height - dropZoneHeight) {
      self.scrollingRate = kScrollingRate;
    } else if (location.y < dropZoneHeight) {
      self.scrollingRate = -kScrollingRate;
    } else {
      self.scrollingRate = 0;
    }
  }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {

  if (scrollView.contentOffset.y < 0 &&
      self.state == LXMTableViewGestureRecognizerStateNone &&
      ![LXMTableViewState sharedInstance].addingRowIndexPath) {
    self.state = LXMTableViewGestureRecognizerStateDragging;
    [LXMTableViewState sharedInstance].addingRowIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [LXMTableViewState sharedInstance].addingRowHeight = fabsf(scrollView.contentOffset.y);
    [self.delegate gestureRecognizer:self needsAddRowAtIndexPath:[LXMTableViewState sharedInstance].addingRowIndexPath usage:LXMTodoItemUsagePullAdded];
  }

  if (self.state == LXMTableViewGestureRecognizerStateDragging &&
      [LXMTableViewState sharedInstance].addingRowIndexPath) {
    [LXMTableViewState sharedInstance].addingRowHeight -= scrollView.contentOffset.y;
    scrollView.contentOffset = CGPointZero;
    [UIView performWithoutAnimation:^{
      [self.tableView reloadRowsAtIndexPaths:@[[LXMTableViewState sharedInstance].addingRowIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    }];
  }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
  NSLog(@"%d", decelerate);
  [self.delegate gestureRecognizer:self needsCommitRowAtIndexPath:[LXMTableViewState sharedInstance].addingRowIndexPath];
}

//- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
//
//  NSLog(@"%@", NSStringFromCGPoint(scrollView.contentOffset));
//
//  if (scrollView.contentOffset.y < 0) {
//    if (![LXMTableViewState sharedInstance].addingRowIndexPath &&
//        self.state == LXMTableViewGestureRecognizerStateNone &&
//        !scrollView.isDecelerating) {
//      self.state = LXMTableViewGestureRecognizerStateDragging;
//      [LXMTableViewState sharedInstance].addingRowIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
//
//      if ([LXMTableViewState sharedInstance].addingRowIndexPath) {
//        [LXMTableViewState sharedInstance].addingRowHeight = fabsf(scrollView.contentOffset.y);
//        [self.delegate gestureRecognizer:self needsAddRowAtIndexPath:[LXMTableViewState sharedInstance].addingRowIndexPath usage:LXMTodoItemUsageNormal];
////        [self.tableView insertRowsAtIndexPaths:@[[LXMTableViewState sharedInstance].addingRowIndexPath] withRowAnimation:UITableViewRowAnimationNone];
//      }
////    } else {
////      [LXMTableViewState sharedInstance].addingRowHeight -= scrollView.contentOffset.y;
////        [UIView performWithoutAnimation:^{
//////        [self.tableView beginUpdates];
//////        [self.tableView endUpdates];
////        [self.tableView reloadRowsAtIndexPaths:@[[LXMTableViewState sharedInstance].addingRowIndexPath] withRowAnimation:UITableViewRowAnimationNone];
////      }];
//    }
//  }
//
//  if ([LXMTableViewState sharedInstance].addingRowIndexPath &&
//      self.state == LXMTableViewGestureRecognizerStateDragging) {
//    [LXMTableViewState sharedInstance].addingRowHeight -= scrollView.contentOffset.y;
//    [UIView performWithoutAnimation:^{
//        [self.tableView beginUpdates];
//        [self.tableView reloadRowsAtIndexPaths:@[[LXMTableViewState sharedInstance].addingRowIndexPath] withRowAnimation:UITableViewRowAnimationNone];
//        [self.tableView endUpdates];
//    }];
//    scrollView.ContentOffset = CGPointZero;
//    NSLog(@"%@", NSStringFromCGPoint(scrollView.contentOffset));
//  }
////       NSLog(@">0");
//}

//- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
//  if (self.state == LXMTableViewGestureRecognizerStateDragging) {
//    self.state = LXMTableViewGestureRecognizerStateNone;
//    [self commitOrDiscardRow];
//  }
//}

//- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
//
//}

//- (void)scrollViewDidScroll:(UIScrollView *)scrollView {

//  if (scrollView.isDragging) {
//    if (![LXMTableViewState sharedInstance].addingRowIndexPath) {
//      if (scrollView.contentOffset.y < 0) {
//        [LXMTableViewState sharedInstance].addingRowIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
//        [LXMTableViewState sharedInstance].addingRowHeight = 0;
//        [self.delegate gestureRecognizer:self needsAddRowAtIndexPath:[LXMTableViewState sharedInstance].addingRowIndexPath usage:LXMTodoItemUsagePullAdded];
//      }
//      scrollView.contentOffset = CGPointZero;}
//    } else {
//      [LXMTableViewState sharedInstance].addingRowHeight -= scrollView.contentOffset.y;
//      [UIView performWithoutAnimation:^{
////        [self.tableView beginUpdates];
////        [self.tableView endUpdates];
//        [self.tableView reloadRowsAtIndexPaths:@[[LXMTableViewState sharedInstance].addingRowIndexPath] withRowAnimation:UITableViewRowAnimationNone];
//      }];
//      NSLog(@"%@", NSStringFromCGPoint(scrollView.contentOffset));
//      NSLog(@"%f", [LXMTableViewState sharedInstance].addingRowHeight);
////      scrollView.contentOffset = CGPointZero;
//    }
//  }
//
//  if (scrollView.contentOffset.y <= 0) {
//    if ([LXMTableViewState sharedInstance].addingRowIndexPath) {
//      [UIView performWithoutAnimation:^{
//        [self.tableView beginUpdates];
//        [LXMTableViewState sharedInstance].addingRowHeight += -scrollView.contentOffset.y;
//        [self.tableView endUpdates];
//      }];
//      scrollView.contentOffset = CGPointMake(0, 0);
//    } else {
//      [LXMTableViewState sharedInstance].addingRowIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
//      [self.delegate gestureRecognizer:self needsAddRowAtIndexPath:[LXMTableViewState sharedInstance].addingRowIndexPath usage:LXMTodoItemUsagePullAdded];
//    }
//  } else {
//    if ([LXMTableViewState sharedInstance].addingRowIndexPath) {
//      [LXMTableViewState sharedInstance].addingRowHeight += -scrollView.contentOffset.y;
//      [UIView performWithoutAnimation:^{
//        [self.tableView beginUpdates];
//        [LXMTableViewState sharedInstance].addingRowHeight += -scrollView.contentOffset.y;
//        [self.tableView endUpdates];
//      }];
//      scrollView.contentOffset = CGPointMake(0, 0);
//    }
//  }
//}

//CGFloat static tempAddingRowHeight = 0;
/*
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {

  if (scrollView.contentOffset.y <= -self.tableView.contentInset.top && [[LXMTableViewState sharedInstance].uneditableIndexPaths count] == 0) {
    if (self.state == LXMTableViewGestureRecognizerStateNone &&

        [scrollView.panGestureRecognizer translationInView:scrollView].y > 0) {
      self.addingCellIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
      self.state = LXMTableViewGestureRecognizerStateDragging;
      [self.delegate gestureRecognizer:self needsAddRowAtIndexPath:self.addingCellIndexPath];
      [LXMTableViewState sharedInstance].lastContentOffset = scrollView.contentOffset;
      [LXMTableViewState sharedInstance].lastContentInset = scrollView.contentInset;
      tempAddingRowHeight = 0;
    }
  }
}*/
/*
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {*/

//   如果 self.delegate 不遵守 addingrow 协议，返回。
//   返回之前，最好看下 self.tableView 的 delegate 有没有 didScroll: 方法，如果能的话，就用它的。
//   好像是个圈啊。
  /*
  if (![self.delegate conformsToProtocol:@protocol(LXMTableViewGestureAddingRowDelegate)]) {
    if ([self.tableViewDelegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
      [self.tableViewDelegate scrollViewDidScroll:scrollView];
    }
    return;
  }*/

  /*
   存储手指向下拖动的长度。

   由于透视投影高度略小于与正射投影高度的原因，不能作为新增行的高度，只能用来辅助计算拖拽手势的完成度。
  */


/*
  if (self.state == LXMTableViewGestureRecognizerStateDragging) {
    tempAddingRowHeight += -(scrollView.contentOffset.y + self.tableView.contentInset.top);
//    tempAddingRowHeight = [scrollView.panGestureRecognizer translationInView:scrollView].y;
    CGFloat fraction = tempAddingRowHeight / [LXMGlobalSettings sharedInstance].modifyingRowHeight;
    fraction = MAX(MIN(1, fraction), 0);
    CGFloat angle = acos(fraction);

    NSLog(@"%f", self.tableView.contentInset.top);

    if (tempAddingRowHeight > 60) {
      NSLog(@"Warning, <<%f>> > 60", tempAddingRowHeight);
    } else {
      NSLog(@"<<%f>> < 60", tempAddingRowHeight);
    }

    /// 临时使用的 view，其变换设置与 pullDownCell 中 transformableView 一致，用于为 pullDownCell 计算行高。
    UIView *view = [LXMTableViewState sharedInstance].assistView;
    view.layer.anchorPoint = CGPointMake(0.5, 1);
    CATransform3D identity = CATransform3DIdentity;
    identity.m34 = [LXMGlobalSettings sharedInstance].addingM34;
    CATransform3D transform = CATransform3DRotate(identity, angle, 1, 0, 0);
    view.layer.transform = transform;

    if (view.frame.size.height < [LXMGlobalSettings sharedInstance].modifyingRowHeight) {
      self.modifyingRowHeight = view.frame.size.height;
    } else {
      self.modifyingRowHeight = MIN(tempAddingRowHeight, self.tableView.contentInset.bottom);
    }

    [LXMTableViewState sharedInstance].addingProgress = fraction;
//    [scrollView setContentOffset:[LXMTableViewState sharedInstance].lastContentOffset];
    scrollView.contentOffset = [LXMTableViewState sharedInstance].lastContentOffset;

    [UIView performWithoutAnimation:^{
      [self.tableView reloadRowsAtIndexPaths:@[self.addingCellIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    }];
  }
}*/

 /*
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
  NSLog(@"******end dragging******");
  if (self.state == LXMTableViewGestureRecognizerStateDragging) {
    NSLog(@"drag ended");
    [self commitOrDiscardRow];
    self.state = LXMTableViewGestureRecognizerStateNoInteracting;
  }
  if (decelerate) {
    NSLog(@"yes");
  }
}*/

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {

  NSLog(@"Will begin decelerating: %@", NSStringFromCGPoint(scrollView.contentOffset));
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {

  NSLog(@"******end decelerating******");
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

  CGFloat rowHeight;

  if ([LXMTableViewState sharedInstance].addingRowIndexPath && [indexPath isEqual:[LXMTableViewState sharedInstance].addingRowIndexPath]) {
//    if (self.state == LXMTableViewGestureRecognizerStatePinching ||
//        self.state == LXMTableViewGestureRecognizerStateDragging) {
      rowHeight = MAX(0, [LXMTableViewState sharedInstance].addingRowHeight);

//    } else {
//      rowHeight = self.tableView.rowHeight;
//    }
  } else {
    rowHeight = [self.tableViewDelegate respondsToSelector:@selector(tableView:heightForRowAtIndexPath:)] ? [self.tableViewDelegate tableView:tableView heightForRowAtIndexPath:indexPath] : self.tableView.rowHeight;
  }

  if (indexPath.section == 1) {
    rowHeight = [self.tableViewDelegate tableView:tableView heightForRowAtIndexPath:indexPath];
  }

  return rowHeight;
}

#pragma mark - LXMTableViewCellDelegate

- (BOOL)tableViewCellShouldBeginTextEditing:(LXMTableViewCell *)cell {

  return YES;
}

- (void)tableViewCellDidBeginTextEditing:(LXMTableViewCell *)cell {

  cell.isModifying = YES;

  self.tableViewState.modifyingRowIndexPath = [self.tableView indexPathForCell:cell];
  [self.tableViewState saveTableViewLastContentOffsetAndInset];
//  self.tableViewState.operationState = LXMTableViewOperationStateCodeModifying;
  [self allowGesturesOnly:LXMTableViewGestureRecognizerOptionsTap | LXMTableViewGestureRecognizerOptionsVerticalPan];

  // 重要：如不设置 contentInset.bottom，当点击屏幕上最后几个 cell 时会出现意想不到的情况。
  self.tableView.contentInset =
      UIEdgeInsetsMake(self.tableView.contentInset.top,
          self.tableView.contentInset.left,
          self.tableView.contentInset.bottom + self.tableView.bounds.size.height - self.tableView.rowHeight,
          self.tableView.contentInset.right);

  [UIView animateWithDuration:self.helper.keyboardAnimationDuration delay:0 options:self.helper.keyboardAnimationCurveOption animations:^{
    self.tableView.contentOffset =
        (CGPoint){self.tableView.contentOffset.x, cell.frame.origin.y - self.tableView.contentInset.top};
    for (LXMTableViewCell *visibleCell in self.tableView.visibleCells) {
      if (cell != visibleCell) {
        visibleCell.alpha = 0.3;
      }
    }
  } completion:^(BOOL finished){
    self.tableView.scrollEnabled = NO;
    self.tableView.bounces = NO;
  }];
}

- (BOOL)tableViewCellShouldEndTextEditing:(LXMTableViewCell *)cell {

  return YES;
}

- (void)tableViewCellDidEndTextEditing:(LXMTableViewCell *)cell {

  [UIView animateWithDuration:self.helper.keyboardAnimationDuration delay:0 options:self.helper.keyboardAnimationCurveOption animations:^{
    for (LXMTableViewCell *visibleCell in self.tableView.visibleCells) {
      if (cell != visibleCell) {
        visibleCell.alpha = 1.0f;
      }
    }
    [self.tableViewState recoverTableViewContentOffsetAndInset];
  } completion:^(BOOL finished) {
    self.operationState = self.operationStateNormal;
    self.tableView.scrollEnabled = YES;
    self.tableView.bounces = YES;
    cell.isModifying = NO;
    self.tableViewState.modifyingRowIndexPath = nil;

    if ([cell.strikeThroughText.text isEqualToString:@""]) {
      [self.helper deleteRowAtIndexPath:[self.tableView indexPathForCell:cell]];
    } else {
      [[NSNotificationCenter defaultCenter] postNotificationName:LXMOperationCompleteNotification object:self];
      [self.tableView reloadData];
    }
  }];
}

@end

#pragma mark - LXMTableViewDelegate Category

@implementation UITableView (LXMTableView)

- (void)lxm_updateTableViewWithDuration:(NSTimeInterval)duration updates:(void (^ __nullable)())updates completion:(void (^ __nullable)())completion {

  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationDuration:duration];
  [CATransaction begin];
  [CATransaction setCompletionBlock:completion];
  [self beginUpdates];
  updates();
  [self endUpdates];
  [CATransaction commit];
  [UIView commitAnimations];
}

- (LXMTableViewGestureRecognizer *)lxm_enableGestureTableViewWithDelegate:(id)delegate {
  
  if (![delegate conformsToProtocol:@protocol(LXMTableViewGestureAddingRowDelegate) ] && ![delegate conformsToProtocol:@protocol(LXMTableViewGestureEditingRowDelegate)] && ![delegate conformsToProtocol:@protocol(LXMTableViewGestureMoveRowDelegate)]) {
    [NSException raise:
     NSInternalInconsistencyException format:@"Delegate should at least conform to one of LXMTableViewGestureAddingRowDelegate, LXMTableViewGestureEditingRowDelegate or LXMTableViewGestureMoveRowDelegate"];
  }
  LXMTableViewGestureRecognizer *recognizer = [LXMTableViewGestureRecognizer gestureRecognizerWithTableView:self delegate:delegate];
  return recognizer;
}

- (void)lxm_reloadVisibleRowsExceptIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
  
  NSMutableArray *visibleIndexPaths = [self.indexPathsForVisibleRows mutableCopy];
  for (NSIndexPath *indexPath in indexPaths) {
      [visibleIndexPaths removeObject:indexPath];
  }
  [UIView performWithoutAnimation:^{
    [self reloadRowsAtIndexPaths:visibleIndexPaths withRowAnimation:UITableViewRowAnimationNone];
  }];
}

@end

@implementation UIView (FindViewThatIsFirstResponder)
- (UIView *)findViewThatIsFirstResponder
{
  if (self.isFirstResponder) {
    return self;
  }

  for (UIView *subView in self.subviews) {
    UIView *firstResponder = [subView findViewThatIsFirstResponder];
    if (firstResponder != nil) {
      return firstResponder;
    }
  }

  return nil;
}
@end
