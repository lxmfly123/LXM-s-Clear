//
//  LXMTableViewGestureRecognizer.m
//  LXM's Gesture Recoginizer
//
//  Created by FLY.lxm on 3/22/16.
//  Copyright © 2016 FLY.lxm. All rights reserved.
//

#import "LXMTableViewGestureRecognizer.h"

typedef NS_ENUM(NSUInteger, LXMTableViewGestureRecognizerState) {
  LXMTableViewGestureRecognizerStateNone,
  LXMTableViewGestureRecognizerStatePinching,
  LXMTableViewGestureRecognizerStatePanning,
  LXMTableViewGestureRecognizerStateMoving,
  LXMTableViewGestureRecognizerStateDragging,
};

CGFloat const LXMTableViewRowAnimationDuration = 0.25;

@interface LXMTableViewGestureRecognizer () <UIGestureRecognizerDelegate>

@property (nonatomic, assign) LXMTableViewGestureRecognizerState state;
@property (nonatomic, weak, readwrite) UITableView *tableView;
@property (nonatomic, weak) id <LXMTableViewGestureMoveRowDelegate, LXMTableViewGestureAddingRowDelegate, LXMTableViewGestureAddingRowDelegate> delegate;
@property (nonatomic, weak) id tableViewDelegate;

@property (nonatomic, strong) NSIndexPath *addingRowIndexPath;
@property (nonatomic, assign) CGFloat addingRowHeight;
@property (nonatomic, assign) LXMTableViewCellEditingState addingRowState;

@property (nonatomic, strong) UIPinchGestureRecognizer *pinchRecognizer;
@property (nonatomic, strong) UIPanGestureRecognizer *panRecognizer;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressRecognizer;
@property (nonatomic, assign) CGPoint pinchStartingUpperPoint;

@end

@implementation LXMTableViewGestureRecognizer

+ (instancetype)gestureRecognizerWithTableView:(UITableView *)tableView delegate:(id)delegate {
  LXMTableViewGestureRecognizer *recognizer = [LXMTableViewGestureRecognizer new];
  recognizer.delegate = delegate;
  recognizer.tableView = tableView;
  recognizer.tableViewDelegate = tableView.delegate;
  tableView.delegate = recognizer;
  
  // the gesture recognizers
  UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:recognizer action:@selector(handlePinch:)];
  pinchRecognizer.delegate = recognizer;
  recognizer.pinchRecognizer = pinchRecognizer;
  [tableView addGestureRecognizer:recognizer.pinchRecognizer];
  
  UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:recognizer action:@selector(handlePan:)];
  panRecognizer.delegate = recognizer;
  recognizer.panRecognizer = panRecognizer;
  [tableView addGestureRecognizer:recognizer.panRecognizer];
  
  UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:recognizer action:@selector(handleLongPress:)];
  longPressRecognizer.delegate = recognizer;
  recognizer.longPressRecognizer = longPressRecognizer;
  [tableView addGestureRecognizer:recognizer.longPressRecognizer];
  
  return recognizer;
}

#pragma mark logic

- (void)commitOrDiscardCell {
  UITableViewCell *commitingCell = [self.tableView cellForRowAtIndexPath:self.addingRowIndexPath];
  
  [self.tableView beginUpdates];
  
  CGFloat commitingCellHeight = self.tableView.rowHeight;
  if ([self.delegate respondsToSelector:@selector(gestureRecognizer:heightForCommitingRowAtIndexPath:)]) {
    commitingCellHeight = [self.delegate gestureRecognizer:self heightForCommitingRowAtIndexPath:self.addingRowIndexPath];
  }
  
  if (commitingCell.frame.size.height >= commitingCellHeight) {
    [self.delegate gestureRecognizer:self needsCommitRowAtIndexPath:self.addingRowIndexPath];
  } else {
    [self.delegate gestureRecognizer:self needsDiscardRowAtIndexPath:self.addingRowIndexPath];
    [self.tableView deleteRowsAtIndexPaths:@[self.addingRowIndexPath] withRowAnimation:UITableViewRowAnimationMiddle];
  }
  
  [self.tableView performSelector:@selector(reloadVisibleRowsExceptIndexPath:) withObject:self.addingRowIndexPath afterDelay:LXMTableViewRowAnimationDuration];
  self.addingRowIndexPath = nil;

  [self.tableView endUpdates];
  
  [UIView beginAnimations:@"" context:nil];
  [UIView setAnimationBeginsFromCurrentState:YES];
  [UIView setAnimationDuration:0.2];
  self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
  [UIView commitAnimations];

  self.state = LXMTableViewGestureRecognizerStateNone;
}

#pragma mark gesture handlers

- (void)handlePinch:(UIPinchGestureRecognizer *)recognizer {
  if (recognizer.state == UIGestureRecognizerStateEnded || [recognizer numberOfTouches] < 2) {
    if (self.addingRowIndexPath) {
      [self commitOrDiscardCell];
    }
    return;
  }
  
  CGPoint point1 = [recognizer locationOfTouch:0 inView:self.tableView];
  CGPoint point2 = [recognizer locationOfTouch:1 inView:self.tableView];
  CGPoint upperPoint = point1.y > point2.y ? point2 : point1;
  CGRect rect = (CGRect){point1, point2.x - point1.x, point2.y - point1.y};
  
  if (recognizer.state == UIGestureRecognizerStateBegan) {
    NSAssert(self.addingRowIndexPath != nil, @"self.addingIndexPath must not be nil, we should have set it in recognizerShouldBegin");
    self.state = LXMTableViewGestureRecognizerStatePinching;
    self.pinchStartingUpperPoint = upperPoint;
    self.tableView.contentInset = UIEdgeInsetsMake(self.tableView.bounds.size.height, 0, self.tableView.bounds.size.height, 0);
    
    [self.tableView beginUpdates];
    [self.delegate gestureRecognizer:self needsAddRowAtIndexPath:self.addingRowIndexPath];
    [self.tableView insertRowsAtIndexPaths:@[self.addingRowIndexPath] withRowAnimation:UITableViewRowAnimationMiddle];
    [self.tableView endUpdates];
    
  } else if (recognizer.state == UIGestureRecognizerStateChanged) {
    //TODO: 此处用 scale 值计算 height 的变化，显然有问题。当两个 pinch 点水平移动时，height 不应当变化，但 scale 会变化，导致 height 变化。
    CGFloat diffRowHeight = CGRectGetHeight(rect) - CGRectGetHeight(rect) / [recognizer scale];
//    self.addingRowHeight = diffRowHeight;
//    NSLog(@"%f", self.addingRowHeight);
//    [self.tableView reloadData];
//
//    CGFloat diffOffsetY = self.pinchStartingUpperPoint.y - upperPoint.y;
//    CGPoint newOffset = CGPointMake(self.tableView.contentOffset.x, self.tableView.contentOffset.y + diffOffsetY);
//    self.tableView.contentOffset = newOffset;
    
    
    // ---- 分割线 ----
    self.addingRowHeight = 60.0f;
    if (diffRowHeight > 0) {
      [[self.tableView visibleCells] enumerateObjectsUsingBlock:^(__kindof UITableViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([self.tableView indexPathForCell:obj].row < self.addingRowIndexPath.row) {
          obj.transform = CGAffineTransformMakeTranslation(0, -diffRowHeight);
        } else if ([self.tableView indexPathForCell:obj].row > self.addingRowIndexPath.row) {
          obj.transform = CGAffineTransformMakeTranslation(0, diffRowHeight);
        }
      }];
    }
  } else {
    NSLog(@"Whoops... Something unexpected happened while pinching. ");
    // TODO: show a alert?
  }
}

- (void)handlePan:(UIPanGestureRecognizer *)panRecognizer {
  
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)longPressRecognizer {
  
}

#pragma mark UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
  // pinch
  if (gestureRecognizer == self.pinchRecognizer) {
    if (![self.delegate conformsToProtocol:@protocol(LXMTableViewGestureAddingRowDelegate)]) {
      NSLog(@"Not conforms to protocal, pinch should not begin.");
      return NO;
    } else {
      CGPoint point1 = [gestureRecognizer locationOfTouch:0 inView:self.tableView];
      CGPoint point2 = [gestureRecognizer locationOfTouch:1 inView:self.tableView];
      CGRect rect = (CGRect){point1, point2.x - point1.x, point2.y - point1.y};
      NSArray *indexPaths = [self.tableView indexPathsForRowsInRect:rect];
      if ([indexPaths count] < 2) {
        NSLog(@"Too few rows between pinch points, pinch should not begin.");
        return NO;
      } else {
        NSIndexPath *firstIndexPath = indexPaths[0];
        NSIndexPath *lastIndexPath = [indexPaths lastObject];
        NSIndexPath *middleIndexPath = [NSIndexPath indexPathForRow:((CGFloat)(firstIndexPath.row + lastIndexPath.row) / 2) + 0.5 inSection:firstIndexPath.section];
        if ([self.delegate respondsToSelector:@selector(gestureRecognizer:willCreatCellAtIndexPath:)]) {
          self.addingRowIndexPath = [self.delegate gestureRecognizer:self willCreatCellAtIndexPath:middleIndexPath];
        } else {
          self.addingRowIndexPath = middleIndexPath;
        }
        
        if (!self.addingRowIndexPath) {
          NSLog(@"index path does not exist, pinch should not begin.");
          return NO;
        } else {
          return YES;
        }
      }
    }
  } else if (gestureRecognizer == self.panRecognizer) {
    // TODO: panRecognizer
    return NO;
  } else if (gestureRecognizer == self.longPressRecognizer) {
    // TODO: longPressRecognizer
    return NO;
  } else {
    return NO; 
  }
}

#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  // 如果 self.delegate 不遵守 addingrow 协议，返回。
  // 返回之前，最好看下 self.tableView 的 delegate 有没有 didScroll: 方法，如果能的话，就用它的。
  // 好像是个圈啊。
  if (![self.delegate conformsToProtocol:@protocol(LXMTableViewGestureAddingRowDelegate)]) {
    if ([self.tableViewDelegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
      [self.tableViewDelegate scrollViewDidScroll:scrollView];
    }
    return;
  }
  
//  if (scrollView.contentOffset <= 0) {
//    <#statements#>
//  }
}

#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  CGFloat rowHeight;
  if ([indexPath isEqual:self.addingRowIndexPath]) {
    if (self.state == LXMTableViewGestureRecognizerStatePinching) {
      rowHeight = MAX(1, self.addingRowHeight);
      rowHeight = 60.0f;
    } else {
      rowHeight = 60.0f;
    }
  } else if ([self.tableViewDelegate respondsToSelector:@selector(tableView:heightForRowAtIndexPath:)]) {
    rowHeight = [self.tableViewDelegate tableView:tableView heightForRowAtIndexPath:indexPath];
  } else {
    rowHeight = 60.0f;
  }
  return rowHeight;
}

@end

@implementation UITableView (LXMTableViewDelegate)

- (LXMTableViewGestureRecognizer *)enableGestureTableViewWithDelegate:(id)delegate {
  if (![delegate conformsToProtocol:@protocol(LXMTableViewGestureAddingRowDelegate) ] && ![delegate conformsToProtocol:@protocol(LXMTableViewGestureEditingRowDelegate)] && ![delegate conformsToProtocol:@protocol(LXMTableViewGestureMoveRowDelegate)]) {
    [NSException raise:
     NSInternalInconsistencyException format:@"delegate should at least conform to one of JTTableViewGestureAddingRowDelegate, JTTableViewGestureEditingRowDelegate or JTTableViewGestureMoveRowDelegate"];
  }
  LXMTableViewGestureRecognizer *recognizer = [LXMTableViewGestureRecognizer gestureRecognizerWithTableView:self delegate:delegate];
  return recognizer;
}

- (void)reloadVisibleRowsExceptIndexPath:(NSIndexPath *)indexPath {
  NSMutableArray *indexPaths = [self.indexPathsForVisibleRows mutableCopy];
  [indexPaths removeObject:indexPath];
  [self reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
}

@end
