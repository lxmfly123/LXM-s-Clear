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

/* Make a rect from `(n, k, m)'. */
CG_INLINE LXMPanOffsetXParameters LXMPanOffsetXParametersMake(CGFloat n, CGFloat k, CGFloat m) {
  
  CGFloat b = (1 - k * n * log(m)) / (k * log(m));
  CGFloat c = k * n - log(n + b) / log(m);
  return (LXMPanOffsetXParameters){n, k, m, b, c};
}

CGFloat const LXMTableViewRowAnimationDurationNormal = 0.25f;
CGFloat const LXMTableViewRowAnimationDurationShort = 0.15f;
CGFloat const LXMTableViewRowAnimationDurationLong = 0.50f;

#define CELL_SNAPSHOT_TAG 100000

@interface LXMTableViewGestureRecognizer () <UIGestureRecognizerDelegate>

@property (nonatomic, weak, readwrite) UITableView *tableView;
@property (nonatomic, weak) id <LXMTableViewGestureAddingRowDelegate, LXMTableViewGestureEditingRowDelegate, LXMTableViewGestureMoveRowDelegate> delegate;
@property (nonatomic, weak) id tableViewDelegate;

@property (nonatomic, strong) NSIndexPath *addingCellIndexPath;
@property (nonatomic, assign) CGFloat addingRowHeight;
@property (nonatomic, assign) LXMTableViewCellEditingState addingRowState;
@property (nonatomic, weak) LXMPullDownTransformableTableViewCell *addingCell;

@property (nonatomic, strong) UITapGestureRecognizer *tapRecognizer;
@property (nonatomic, strong) UIPinchGestureRecognizer *pinchRecognizer;
@property (nonatomic, strong) UIPanGestureRecognizer *panRecognizer;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressRecognizer;

#pragma mark Pinch Helper Properties
@property (nonatomic, assign) UIEdgeInsets startingTableViewContentInset;
@property (nonatomic, assign) CGPoint startingTableViewContentOffset;
@property (nonatomic, assign) LXMPinchPoints startingPinchPoints;
//@property (nonatomic, strong) CADisplayLink *displayLink;

#pragma mark LongPress Helper Properties
/// 每 0.125 秒判断一次是否需要滚动 tableView。
@property (nonatomic, strong) NSTimer *movingTimer;
/// tableView 的滚动速率，单位 px/sec。
@property (nonatomic, assign) CGFloat scrollingRate;
/// 正在被拖动的 cell 的位图快照。
@property (nonatomic, strong) UIImage *cellSnapshot;

@end

@implementation LXMTableViewGestureRecognizer

+ (instancetype)gestureRecognizerWithTableView:(UITableView *)tableView delegate:(id)delegate {
  LXMTableViewGestureRecognizer *recognizer = [LXMTableViewGestureRecognizer new];
  recognizer.delegate = delegate;
  recognizer.tableView = tableView;
  recognizer.tableViewDelegate = tableView.delegate;
  tableView.delegate = recognizer;
  
  [recognizer configureGestureRecognizers];
  [recognizer adjustTableViewFrame];
  
  return recognizer;
}

- (void)dealloc {
  
  [[NSNotificationCenter defaultCenter] removeObserver:self.panRecognizer];
}

#pragma mark - Init Helper Methods

- (void)configureGestureRecognizers {
  
  NSAssert(self.tableView, @"Table View does not exist. ");
  
  // tap recoginizer
  self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
  [self.tableView addGestureRecognizer:self.tapRecognizer];
  
  //pinch recognizer
  UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
  pinchRecognizer.delegate = self;
  self.pinchRecognizer = pinchRecognizer;
  [self.tableView addGestureRecognizer:self.pinchRecognizer];

  //pan recognizer
  UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
  panRecognizer.delegate = self;
  self.panRecognizer = panRecognizer;
  [self.tableView addGestureRecognizer:self.panRecognizer];
  
  [[NSNotificationCenter defaultCenter] 
   addObserverForName:LXMEditCompleteNotification  
   object:nil 
   queue:nil 
   usingBlock:^(NSNotification * _Nonnull note) {
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

#pragma mark - Gesture Recognizer Helper Methods 

- (void)collectGestureStartingInfomation {
  
  if (self.state == LXMTableViewGestureRecognizerStatePinching) {
//    self.startingTableViewContentOffset = self.tableView.contentOffset;
//    self.startingTableViewContentInset = self.tableView.contentInset;
    [LXMTableViewState sharedInstance].lastContentOffset = self.tableView.contentOffset;
    [LXMTableViewState sharedInstance].lastContentInset = self.tableView.contentInset;
    self.startingPinchPoints = [self normalizePinchPointsForPinchGestureRecognizer:self.pinchRecognizer];
    self.addingCellIndexPath = [self targetIndexPathForPinchPoints:[self normalizePinchPointsForPinchGestureRecognizer:self.pinchRecognizer]];
  } else if (self.state == LXMTableViewGestureRecognizerStatePanning) {
    NSIndexPath *panningIndexPath = [self.tableView indexPathForRowAtPoint:[self.panRecognizer locationInView:self.tableView]];
    [LXMTableViewState sharedInstance].panningCell = [self.tableView cellForRowAtIndexPath:panningIndexPath];;
  } else if (self.state == LXMTableViewGestureRecognizerStateMoving) {
    // TODO: longpress
  }
}

- (void)clearGestureStartingInformation {
  
  if (self.state == LXMTableViewGestureRecognizerStatePinching) {
//    self.startingTableViewContentOffset = CGPointZero;
//    self.startingTableViewContentInset = UIEdgeInsetsZero;
    [LXMTableViewState sharedInstance].lastContentOffset = CGPointZero;
    [LXMTableViewState sharedInstance].lastContentInset = UIEdgeInsetsZero;
    self.startingPinchPoints = (LXMPinchPoints){{0, 0}, {0, 0}};
    self.addingCellIndexPath = nil;
  } else if (self.state == LXMTableViewGestureRecognizerStatePanning) {
    [LXMTableViewState sharedInstance].panningCell = nil;
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

/// long press gesture recognizer helper method

- (void)updateAddingIndexPathForCurrentLocation {
  
  NSIndexPath *indexPath = nil;
  CGPoint location = CGPointZero;
  
  // 更新 indexPath
  location = [self.longPressRecognizer locationInView:self.tableView];
  indexPath = [self.tableView indexPathForRowAtPoint:location];
  if (indexPath && ![indexPath isEqual:self.addingCell]) {
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:@[self.addingCellIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    [self.delegate gestureRecognizer:self needsMovePlaceholderForRowAtIndexPath:self.addingCellIndexPath toIndexPath:indexPath];
    self.addingCellIndexPath = indexPath;
    [self.tableView endUpdates];
  }
}

/// 当长按拖动时触摸点移到屏幕底/顶部时，滚动 table view。
- (void)scrollTable {
  
  CGPoint location = CGPointZero;
  location = [self.longPressRecognizer locationInView:self.tableView];
  
  CGPoint currentOffset = self.tableView.contentOffset;
  CGPoint newOffset = CGPointMake(currentOffset.x, currentOffset.y + self.scrollingRate);
  
  if (newOffset.y < -self.tableView.contentInset.top) {
    newOffset.y = 0;
  } else if (self.tableView.contentSize.height < self.tableView.frame.size.height - self.tableView.contentInset.top - self.tableView.contentInset.bottom) {
    newOffset = currentOffset;
  } else if (newOffset.y > self.tableView.contentSize.height - (self.tableView.frame.size.height - self.tableView.contentInset.top - self.tableView.contentInset.bottom)) {
    newOffset.y = self.tableView.contentSize.height - (self.tableView.frame.size.height - self.tableView.contentInset.top - self.tableView.contentInset.bottom);
  } else {
    //TODO: Just in case
    NSLog(@"Oops, something unexpected happened...");
  }
  
  [self.tableView setContentOffset:newOffset];
  
  if (location.y >= self.tableView.contentInset.top) {
    UIImageView *cellSnapshot = (id)[self.tableView viewWithTag:CELL_SNAPSHOT_TAG];
    cellSnapshot.center = CGPointMake(self.tableView.center.x, location.y);
  }
    
}

// pan offset, see http://lxm9.com/2016/04/19/sliding-damping-in-clear-the-app/

- (CGFloat)panOffsetXForParameters:(LXMPanOffsetXParameters)parameters {
  
  CGFloat offsetX;
  
  if (ABS([self.panRecognizer translationInView:self.tableView].x) < parameters.n) {
    offsetX = parameters.k * [self.panRecognizer translationInView:self.tableView].x;
  } else {
    if ([self.panRecognizer translationInView:self.tableView].x < 0) {
      offsetX = -((log(-[self.panRecognizer translationInView:self.tableView].x + parameters.b) / log(parameters.m)) + parameters.c); 
    } else {
      offsetX = (log([self.panRecognizer translationInView:self.tableView].x + parameters.b) / log(parameters.m)) + parameters.c; 
    }
  }
  
  return offsetX;
}

- (void)commitOrDiscardCell {
  
  CGFloat commitingCellHeight = self.addingRowHeight;
  NSIndexPath *commitingCellIndexPath = self.addingCellIndexPath;
  self.addingCellIndexPath = nil;
  self.addingRowHeight = 0;
  
  if ([self.delegate respondsToSelector:@selector(gestureRecognizer:heightForCommitingRowAtIndexPath:)]) {
    commitingCellHeight = [self.delegate gestureRecognizer:self heightForCommitingRowAtIndexPath:commitingCellIndexPath];
  }

  if (commitingCellHeight < self.tableView.rowHeight) {
    [self.delegate gestureRecognizer:self needsDiscardRowAtIndexPath:commitingCellIndexPath];
  } else {
    [self.delegate gestureRecognizer:self needsCommitRowAtIndexPath:commitingCellIndexPath];
  }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)recognizer {
  
  if (self.state != LXMTableViewGestureRecognizerStateNone) {
    NSLog(@"is in state, can not start a new one. ");
    return NO;
  }
  
  if (recognizer == self.pinchRecognizer) {
    // Pinch 
    if (![self.delegate conformsToProtocol:@protocol(LXMTableViewGestureAddingRowDelegate)]) {
      NSLog(@"Not conforms to protocal, pinch should not begin.");
      return NO;
    } else {
      NSIndexPath *targetIndexPath = [self targetIndexPathForPinchPoints:[self normalizePinchPointsForPinchGestureRecognizer:(UIPinchGestureRecognizer *)recognizer]];
      
      if (![self.delegate gestureRecognizer:self canAddCellAtIndexPath:targetIndexPath]) {
        return NO;
      }
      
      if ([self.delegate respondsToSelector:@selector(gestureRecognizer:willCreateCellAtIndexPath:)]) {
        [self.delegate gestureRecognizer:self willCreateCellAtIndexPath:targetIndexPath];
      }
        return YES;
    }
    
  } else if (recognizer == self.panRecognizer) {
    // Pan 
    if (![self.delegate conformsToProtocol:@protocol(LXMTableViewGestureEditingRowDelegate)]) {
      return NO;
    }
    CGPoint translation = [self.panRecognizer translationInView:self.tableView];
    CGPoint location = [self.panRecognizer locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    BOOL isSlidingHorizentally = fabs(translation.x) > fabs(translation.y);
    BOOL canEdit = [self.delegate gestureRecognizer:self canEditRowAtIndexPath:indexPath];
    
    if (!indexPath) {
      NSLog(@"no indexpath");
      return NO;
    }
    
    if (!isSlidingHorizentally) {
      NSLog(@"scroll");
      return NO;
    } 
    
    if (!canEdit) {
      NSLog(@"can not edit row");
      return NO;
    }
    
    return YES;
    
  } else if (recognizer == self.longPressRecognizer) {
    // TODO: longPressRecognizer
    NSInteger static counter = 0;
    NSLog(@"%ld yes", counter++);
    return YES;
  } else {
    return NO; 
  }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
  if (gestureRecognizer == self.panRecognizer) {
    if (otherGestureRecognizer == self.pinchRecognizer) {
      return NO;
    }
  }
  return NO;
}

#pragma mark - Gesture Handlers

- (void)handleTap:(UITapGestureRecognizer *)recognizer {
  
  if (recognizer.state == UIGestureRecognizerStateEnded) {
//    CGPoint location = [recognizer locationInView:self.tableView];
//    LXMTableViewCell *cell = [self.tableView cellForRowAtIndexPath:[self.tableView indexPathForRowAtPoint:location]];
//    
//    if (cell.userInteractionEnabled) {
//      [cell.strikeThroughText becomeFirstResponder];
//    } else {
      [self.tableView endEditing:YES];
//    }
  }
}

- (void)handlePinch:(UIPinchGestureRecognizer *)recognizer {
  
  if (recognizer.state == UIGestureRecognizerStateBegan) {
    self.state = LXMTableViewGestureRecognizerStatePinching;
    [self collectGestureStartingInfomation];
    NSAssert(self.addingCellIndexPath != nil, @"self.addingIndexPath must not be nil, we should have set it in recognizerShouldBegin");
    self.tableView.contentInset = 
    UIEdgeInsetsMake(self.tableView.contentInset.top + self.tableView.bounds.size.height, 
                     self.tableView.contentInset.left, 
                     self.tableView.contentInset.bottom + self.tableView.bounds.size.height, 
                     self.tableView.contentInset.right);
    
//    [UIView performWithoutAnimation:^{
      [self.delegate gestureRecognizer:self needsAddRowAtIndexPath:self.addingCellIndexPath];
//      [self.tableView insertRowsAtIndexPaths:@[self.addingCellIndexPath] withRowAnimation:UITableViewRowAnimationNone];
//    }];
  } else if (recognizer.state == UIGestureRecognizerStateChanged && recognizer.numberOfTouches >= 2) {
    self.addingRowHeight = [self pinchDistanceYOfPinchGestureRecognizer:recognizer];
    LXMPinchPoints currentPinchPoints = [self normalizePinchPointsForPinchGestureRecognizer:recognizer];
    
    if (self.addingRowHeight >= 0) {
      CGFloat upperDistance = self.startingPinchPoints.upper.y - currentPinchPoints.upper.y;
      self.tableView.contentOffset = CGPointMake([LXMTableViewState sharedInstance].lastContentOffset.x, self.tableView.contentOffset.y + upperDistance);
    } else {
      self.addingRowHeight = 0;
      // TODO: pinch transform to totolist view
    }
    if ([self.delegate respondsToSelector:@selector(gestureRecognizer:isAddingRowAtIndexPath:)]) {
      [self.delegate gestureRecognizer:self isAddingRowAtIndexPath:self.addingCellIndexPath];
    }
    [UIView performWithoutAnimation:^{
      [self.tableView reloadRowsAtIndexPaths:@[self.addingCellIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    }];
  } else if (recognizer.state == UIGestureRecognizerStateEnded || [recognizer numberOfTouches] < 2) {
    self.state = LXMTableViewGestureRecognizerStateNoInteracting;
    if (self.addingCellIndexPath) {
      [self commitOrDiscardCell];
    }
  } else {
    self.state = LXMTableViewGestureRecognizerStateNone;
    NSLog(@"Whoops... Something unexpected happened while pinching. ");
    // TODO: show a alert?
  }
}



- (void)handlePan:(UIPanGestureRecognizer *)panRecognizer {
  
  static LXMTableViewCellEditingState lastEditingState = LXMTableViewCellEditingStateNone;
  static NSIndexPath *panningIndexPath;
  static LXMTableViewCell *panningCell;
  
  if (panRecognizer.state == UIGestureRecognizerStateBegan) {
    self.state = LXMTableViewGestureRecognizerStatePanning;
    [self collectGestureStartingInfomation];
    panningCell = [LXMTableViewState sharedInstance].panningCell;
    panningIndexPath = [self.tableView indexPathForCell:panningCell];
  } else if (panRecognizer.state == UIGestureRecognizerStateChanged) {
    CGFloat offsetX;
    if ([panRecognizer translationInView:self.tableView].x > 0) {
      LXMPanOffsetXParameters completionParameters = LXMPanOffsetXParametersMake([LXMGlobalSettings sharedInstance].editCommitTriggerWidth, 0.9, 1.07);
      offsetX = [self panOffsetXForParameters:completionParameters];
    } else {
      LXMPanOffsetXParameters deletionParameters = LXMPanOffsetXParametersMake([LXMGlobalSettings sharedInstance].editCommitTriggerWidth, 0.75, 1.01);
      offsetX = [self panOffsetXForParameters:deletionParameters];
    }
    
    panningCell.actualContentView.frame = CGRectOffset(panningCell.contentView.bounds, offsetX, 0);
    [panningCell setNeedsLayout];
    
    if (offsetX > [LXMGlobalSettings sharedInstance].editCommitTriggerWidth) {
      if (lastEditingState != LXMTableViewCellEditingStateCompleting) {
        NSLog(@"completing");
        lastEditingState = LXMTableViewCellEditingStateCompleting;
      }
    } else if (offsetX < - [LXMGlobalSettings sharedInstance].editCommitTriggerWidth) {
      if (lastEditingState != LXMTableViewCellEditingStateDeleting) {
        NSLog(@"deleting");
        lastEditingState = LXMTableViewCellEditingStateDeleting;
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
  } else if (panRecognizer.state == UIGestureRecognizerStateEnded) {
    self.state = LXMTableViewGestureRecognizerStateNone;
    if (lastEditingState == LXMTableViewCellEditingStateDeleting) {
      self.state = LXMTableViewGestureRecognizerStateNoInteracting;
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
    self.state = LXMTableViewGestureRecognizerStateMoving;
    NSLog(@"moving");
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    UIGraphicsBeginImageContextWithOptions(cell.bounds.size, NO, 0);
    [cell.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *cellImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIImageView *snapshotView = (UIImageView *)[self.tableView viewWithTag:CELL_SNAPSHOT_TAG];
    if (!snapshotView) {
      snapshotView = [[UIImageView alloc] initWithImage:cellImage];
      snapshotView.tag = CELL_SNAPSHOT_TAG;
      [self.tableView addSubview:snapshotView];
      snapshotView.frame = [self.tableView rectForRowAtIndexPath:indexPath];
    }
    
    [UIView beginAnimations:@"zoonCell" context:nil];
    snapshotView.transform = CGAffineTransformMakeScale(1.1, 1.1);
    snapshotView.center = CGPointMake(self.tableView.center.x, location.y);
    [UIView commitAnimations];
    
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    [self.delegate gestureRecognizer:self needsCreatePlaceholderForRowAtIndexPath:indexPath];
    self.addingCellIndexPath = indexPath;
    [self.tableView endUpdates];
      
    self.movingTimer = [NSTimer timerWithTimeInterval:0.125 target:self selector:@selector(scrollTable) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.movingTimer forMode:NSDefaultRunLoopMode];
    
  } else if (longPressRecognizer.state == UIGestureRecognizerStateEnded) {
    __weak __block UIImageView *snapshotView = (UIImageView *)[self.tableView viewWithTag:CELL_SNAPSHOT_TAG];
    __weak __block LXMTableViewGestureRecognizer *weakSelf = self;
    __weak __block NSIndexPath *indexPath = self.addingCellIndexPath;
    
    [self.movingTimer invalidate];
    self.movingTimer = nil;
    self.scrollingRate = 0;
    
    [UIView animateWithDuration:LXMTableViewRowAnimationDurationShort animations:^{
      CGRect rect = [weakSelf.tableView rectForRowAtIndexPath:indexPath];
      snapshotView.transform = CGAffineTransformIdentity;
      snapshotView.frame = rect;
    } completion:^(BOOL finished) {
      [snapshotView removeFromSuperview];
      
      [weakSelf.tableView beginUpdates];
      [weakSelf.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
      [weakSelf.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
      [weakSelf.delegate gestureRecognizer:self needsReplacePlaceholderForRowAtIndexPath:indexPath];
      [weakSelf.tableView endUpdates];
      
      [weakSelf.tableView reloadVisibleRowsExceptIndexPaths:@[indexPath]];
      weakSelf.cellSnapshot = nil;
      weakSelf.addingCellIndexPath = nil;
      weakSelf.state = LXMTableViewGestureRecognizerStateNone;
    }];
  } else if (longPressRecognizer.state == UIGestureRecognizerStateChanged) {
    
    UIImageView *snapshotView = (UIImageView *)[self.tableView viewWithTag:CELL_SNAPSHOT_TAG];
    snapshotView.center = CGPointMake(self.tableView.center.x, location.y);
    
    CGRect rect = self.tableView.bounds;
    CGPoint location = [self.longPressRecognizer locationInView:self.tableView];
    // TODO: to be fixed
    location.y -= self.tableView.contentOffset.y;
    [self updateAddingIndexPathForCurrentLocation];
    
    CGFloat bottomDropZoneHeight = self.tableView.bounds.size.height / 6;
    CGFloat topDropZoneHeight = bottomDropZoneHeight;
    CGFloat bottomDiff = location.y - (rect.size.height - bottomDropZoneHeight);
    if (bottomDiff > 0) {
      self.scrollingRate = bottomDiff / (bottomDropZoneHeight / 1);
    } else if (location.y <= topDropZoneHeight) {
      self.scrollingRate = -(topDropZoneHeight - MAX(location.y, 0));
    } else {
      self.scrollingRate = 0;
    }
  }
}

#pragma mark - UIScrollViewDelegate

CGFloat static tempAddingRowHeight = 0;

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
  
  if (scrollView.contentOffset.y <= -self.tableView.contentInset.top && [[LXMTableViewState sharedInstance].uneditableIndexPathes count] == 0) {
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
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  
//   如果 self.delegate 不遵守 addingrow 协议，返回。
//   返回之前，最好看下 self.tableView 的 delegate 有没有 didScroll: 方法，如果能的话，就用它的。
//   好像是个圈啊。
  if (![self.delegate conformsToProtocol:@protocol(LXMTableViewGestureAddingRowDelegate)]) {
    if ([self.tableViewDelegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
      [self.tableViewDelegate scrollViewDidScroll:scrollView];
    }
    return;
  }
  
  /** 
   存储手指向下拖动的长度。
   
   由于透视投影高度略小于与正射投影高度的原因，不能作为新增行的高度，只能用来辅助计算拖拽手势的完成度。
  */
  

  
  if (self.state == LXMTableViewGestureRecognizerStateDragging) {
    tempAddingRowHeight += -(scrollView.contentOffset.y + self.tableView.contentInset.top);
//    tempAddingRowHeight = [scrollView.panGestureRecognizer translationInView:scrollView].y;
    CGFloat fraction = tempAddingRowHeight / [LXMGlobalSettings sharedInstance].addingRowFinishedHeight;
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
    
    if (view.frame.size.height < [LXMGlobalSettings sharedInstance].addingRowFinishedHeight) {
      self.addingRowHeight = view.frame.size.height;
    } else {
      self.addingRowHeight = MIN(tempAddingRowHeight, self.tableView.contentInset.bottom);
    }
    
    [LXMTableViewState sharedInstance].addingProgress = fraction;
//    [scrollView setContentOffset:[LXMTableViewState sharedInstance].lastContentOffset];
    scrollView.contentOffset = [LXMTableViewState sharedInstance].lastContentOffset;
    
    [UIView performWithoutAnimation:^{
      [self.tableView reloadRowsAtIndexPaths:@[self.addingCellIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    }];
  }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
  NSLog(@"******end dragging******");
  if (self.state == LXMTableViewGestureRecognizerStateDragging) {
    NSLog(@"drag ended");
    [self commitOrDiscardCell];
    self.state = LXMTableViewGestureRecognizerStateNoInteracting;
  }
  if (decelerate) {
    NSLog(@"yes");
  }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  
  NSLog(@"******end decelerating******");
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  CGFloat rowHeight;
  if (self.addingCellIndexPath && [indexPath isEqual:self.addingCellIndexPath]) {
    if (self.state == LXMTableViewGestureRecognizerStatePinching || 
        self.state == LXMTableViewGestureRecognizerStateDragging) {
      rowHeight = MAX(0, self.addingRowHeight);
    } else {
      rowHeight = self.tableView.rowHeight;
    }
  } else if ([self.tableViewDelegate respondsToSelector:@selector(tableView:heightForRowAtIndexPath:)]) {
    rowHeight = [self.tableViewDelegate tableView:tableView heightForRowAtIndexPath:indexPath];
  } else {
    rowHeight = self.tableView.rowHeight;
  }
  return rowHeight;
}

@end

#pragma mark - LXMTableViewDelegate Category

@implementation UITableView (LXMTableView)

- (LXMTableViewGestureRecognizer *)enableGestureTableViewWithDelegate:(id)delegate {
  
  if (![delegate conformsToProtocol:@protocol(LXMTableViewGestureAddingRowDelegate) ] && ![delegate conformsToProtocol:@protocol(LXMTableViewGestureEditingRowDelegate)] && ![delegate conformsToProtocol:@protocol(LXMTableViewGestureMoveRowDelegate)]) {
    [NSException raise:
     NSInternalInconsistencyException format:@"Delegate should at least conform to one of LXMTableViewGestureAddingRowDelegate, LXMTableViewGestureEditingRowDelegate or LXMTableViewGestureMoveRowDelegate"];
  }
  LXMTableViewGestureRecognizer *recognizer = [LXMTableViewGestureRecognizer gestureRecognizerWithTableView:self delegate:delegate];
  return recognizer;
}

- (void)reloadVisibleRowsExceptIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
  
  NSMutableArray *visibleIndexPaths = [self.indexPathsForVisibleRows mutableCopy];
  for (NSIndexPath *indexPath in indexPaths) {
      [visibleIndexPaths removeObject:indexPath];
  }
  [UIView performWithoutAnimation:^{
    [self reloadRowsAtIndexPaths:visibleIndexPaths withRowAnimation:UITableViewRowAnimationNone];
  }];
}

@end
