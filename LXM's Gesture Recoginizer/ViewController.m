//
//  ViewController.m
//  LXM's Gesture Recoginizer
//
//  Created by FLY.lxm on 3/22/16.
//  Copyright © 2016 FLY.lxm. All rights reserved.
//

#import "ViewController.h"
#import "LXMGlobalSettings.h"
#import "LXMAnimationQueue.h"
#import "LXMTableViewCell.h"
#import "LXMTableViewGestureRecognizer.h"
#import "LXMTransformableTableViewCell.h"
#import "LXMTodoList.h"
#import <pop/POP.h>
#import "LXMTableViewState.h"
#import "LXMStrikeThroughText.h"
#import "UIColor+LXMTableViewGestureRecognizerHelper.h"#import "POPBasicAnimationInternal.h"#import "POPAnimationInternal.h"

static NSString * const kAddingCell = @"Continue";
static NSString * const kDoneCell = @"Done";
static NSString * const kDummyCell = @"Dummy";
static const CGFloat kNormalCellFinishedHeight = 60.0f;

@interface ViewController () <LXMTableViewGestureAddingRowDelegate, LXMTableViewGestureEditingRowDelegate, LXMTableViewGestureMoveRowDelegate, LXMTableViewCellDelegate, POPAnimationDelegate>

@property (nonatomic, strong) LXMTableViewGestureRecognizer *tableViewRecognizer;
@property (nonatomic, weak) LXMTableViewState *tableViewState;
@property (nonatomic, strong) LXMTodoList *todoList;
//@property (nonatomic, strong) NSMutableArray<LXMTodoItem *> *todoItems;
@property (nonatomic, assign) NSTimeInterval keyboardAnimationDuration;
@property (nonatomic, assign) UIViewAnimationOptions keyboardAnimationCurveOption;
@property (nonatomic, strong) LXMTodoItem *grabbedTodoItem; ///< 长按时要移动的项目。

// 动画相关属性
@property (nonatomic, strong) LXMAnimationQueue *animationQueue;

@end

@implementation ViewController

#pragma mark view lifecycle

- (void)viewDidLoad {
  
  [super viewDidLoad];
  
  self.todoList.todoItems = [[NSMutableArray alloc] initWithCapacity:10];
  self.todoList = [LXMTodoList new];
  NSArray *array = @[@"右划完成", 
                    @"左划删除", 
                    @"Pinch 新建", 
                    @"向下拖动新建", 
                    @"长按移动",
                    @"长按移动1",
                    @"长按移动2",
                    @"长按移动3",
                    @"长按移动4",
                    @"长按移动5",
                    @"长按移动6",
                    @"长按移动7",
                    @"长按移动8"];
  [array enumerateObjectsUsingBlock:^(LXMTodoItem * _Nonnull todoText, NSUInteger idx, BOOL * _Nonnull stop) {
    [self.todoList.todoItems addObject:[LXMTodoItem todoItemWithText:todoText]];
  }];
  
  self.tableView.backgroundColor = [UIColor blackColor];
  self.tableView.rowHeight = [LXMGlobalSettings sharedInstance].normalRowHeight;
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  
  self.tableViewState = [LXMTableViewState sharedInstance];
  self.tableViewState.tableView = self.tableView;
  self.tableViewState.todoList = self.todoList;
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification {
  
  _keyboardAnimationDuration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
  _keyboardAnimationCurveOption = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue] << 16;
}

- (void)viewWillAppear:(BOOL)animated {
  
  self.tableViewRecognizer = [self.tableView lxm_enableGestureTableViewWithDelegate:self];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)dealloc {

  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - CADisplayLink

//- (void)startAnimation{
//  //  self.displayLink.beginTime = CACurrentMediaTime();
//  if (!self.displayLink) {
//    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(test:)];
//  }
//  self.displayLink.paused = NO;
//  [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
//}
//
//- (void)stopAnimation{
//  self.displayLink.paused = YES;
//  [self.displayLink invalidate];
//  self.displayLink = nil;
//  [self.tableView.visibleCells enumerateObjectsUsingBlock:^(__kindof UITableViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//    obj.layer.transform = CATransform3DIdentity;
//  }];
//  [self.tableViewState recoverTableViewContentOffsetAndInset];
//}

/*
- (void)test:(CADisplayLink *)displayLink {

  LXMFlippingTransformableTableViewCell *theCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
//  NSLog(@"%@", theCell);
  CALayer *presentationLayer = theCell.transformableView.layer.presentationLayer;
  
//  static UIView *view;
//  view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, self.tableView.rowHeight)];
//  view.layer.anchorPoint = CGPointMake(0.5, 1);
//  CATransform3D identity = CATransform3DIdentity;
//  identity.m34 = -1 / 500.0f;
//  CATransform3D transform = CATransform3DRotate(identity, acos(presentationLayer.transform.m22), 1, 0, 0);
//  view.layer.transform = transform;
  
//  self.tableView.contentOffset = CGPointMake(0, self.tableViewState.lastContentOffset.y + (theCell.frame.size.height - view.frame.size.height));
//  self.tableView.contentOffset = CGPointMake(0, self.tableViewState.lastContentOffset.y + presentationLayer.frame.origin.y);
//  theCell.frame = CGRectOffset(theCell.frame, 0, -(theCell.frame.size.height - presentationLayer.frame.size.height));
//  theCell.transform = CGAffineTransformMakeTranslation(0, -(theCell.frame.size.height - presentationLayer.frame.size.height));
//  theCell.layer.transform = CATransform3DTranslate(theCell.layer.transform, 0, -(theCell.frame.size.height - presentationLayer.frame.size.height), 0);
//  theCell.layer.transform = CATransform3DMakeTranslation(0, -(theCell.frame.size.height - presentationLayer.frame.size.height), 0);
  
  CATransform3D transform = CATransform3DMakeTranslation(0, - presentationLayer.frame.origin.y, 0);
  [self.tableView.visibleCells enumerateObjectsUsingBlock:^(__kindof UITableViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    obj.layer.transform = transform;
  }];

  /*
  NSInteger static counter = 1;
  NSLog(@"%ld", counter++);
  NSLog(@"%@", NSStringFromCGPoint(point));
  
  NSLog(@"view height: %f",theCell.transformableView.frame.size.height);
  NSLog(@"layer height: %f", presentationLayer.frame.size.height);
  NSLog(@"offset1: %f", theCell.frame.size.height - presentationLayer.frame.size.height);
  NSLog(@"offset2: %f", self.tableView.contentOffset.y + 120);*/
/*}*/

#pragma mark - getters

- (NSTimeInterval)keyboardAnimationDuration {

  return _keyboardAnimationDuration = _keyboardAnimationDuration < 0.01 ? LXMTableViewRowAnimationDurationNormal : _keyboardAnimationDuration;
}

- (UIViewAnimationCurve)keyboardAnimationCurveOption {

  return _keyboardAnimationCurveOption = _keyboardAnimationCurveOption == 0 ? 7 << 16 :
      _keyboardAnimationCurveOption;
}

- (LXMAnimationQueue *)animationQueue {

  if (_animationQueue == nil) {
    _animationQueue = [LXMAnimationQueue new];
  }

  return _animationQueue;
}

#pragma mark - methods

- (void)bounceRowAtIndex:(NSIndexPath *)indexPath check:(BOOL)shouldCheck {

  self.tableViewState.operationState = LXMTableViewOperationStateAnimating2;
  [self.tableViewRecognizer allowGesturesOnly:LXMTableViewGestureRecognizerOptionsTap |
                                              LXMTableViewGestureRecognizerOptionsHorizontalPan];
  
  LXMTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
  NSIndexPath *destinationIndexPath;
  
  [self.tableViewState.bouncingCells insertObject:cell atIndex:0];
  
  if (shouldCheck) {
    destinationIndexPath = [self movingDestinationIndexPathForRowAtIndexPath:indexPath];
  }
  
  [UIView animateWithDuration:LXMTableViewRowAnimationDurationNormal
                        delay:0 
       usingSpringWithDamping:0.6 
        initialSpringVelocity:8 
                      options:UIViewAnimationOptionCurveEaseInOut 
                   animations:^{
                     cell.actualContentView.frame = cell.contentView.frame;
                     [cell.strikeThroughText setNeedsLayout];
                   } 
                   completion:^(BOOL finished) {
                     if (shouldCheck) {
                       NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
                       [self moveRowAtIndexPath:indexPath toIndexPath:destinationIndexPath];
                     }
                     [self.tableViewState.bouncingCells removeLastObject];
                     if (self.tableViewState.uneditableIndexPaths.count == 0) {
                       self.tableViewState.operationState = LXMTableViewOperationStateNormal;
                       [self.tableViewRecognizer allowAllGestures];
                     }
                   }];
}

- (NSIndexPath *)movingDestinationIndexPathForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  NSUInteger __block index = 0;
  [self.todoList.todoItems enumerateObjectsUsingBlock:^(LXMTodoItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    if (!obj.isCompleted && (idx != indexPath.row)) {
      ++index;
    }
  }];
  
  return [NSIndexPath indexPathForRow:index inSection:0];
}

- (void)bounceCell:(LXMTableViewCell *)cell check:(BOOL)shouldCheck {
  
  NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
  [self bounceRowAtIndex:indexPath check:shouldCheck];
}

- (void)moveRowAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath {
  
  LXMTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
  if (cell.todoItem.isCompleted) {
    cell.actualContentView.backgroundColor = [self colorForRowAtIndexPath:indexPath];
    cell.strikeThroughText.textColor = [self textColorForRowAtIndexPath:indexPath];
  }
  
  [self.tableViewState.floatingCells insertObject:cell atIndex:0];
  
  void (^completionBlock)(void) = ^{
    [self.tableViewState.floatingCells removeLastObject];
    [[NSNotificationCenter defaultCenter] postNotificationName:LXMOperationCompleteNotification object:self];
    if (self.tableViewState.uneditableIndexPaths.count == 0) {
      [[NSNotificationCenter defaultCenter] postNotificationName:LXMOperationCompleteNotification object:self];
      [self.tableView reloadData];
    }
  };
  
  NSIndexPath *firstVisibleIndexPath = [self.tableView indexPathForCell:[self.tableView.visibleCells firstObject]];
  NSIndexPath *lastVisibleIndexPath = [self.tableView indexPathForCell:[self.tableView.visibleCells lastObject]];

  if (newIndexPath.row > lastVisibleIndexPath.row || newIndexPath.row < firstVisibleIndexPath.row) {
    NSIndexPath *tempTargetIndexPath;
    if (newIndexPath.row > lastVisibleIndexPath.row) {
      tempTargetIndexPath = lastVisibleIndexPath;
    } else {
      tempTargetIndexPath = firstVisibleIndexPath;
    }
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:LXMTableViewRowAnimationDurationNormal];
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
      LXMTodoItem *tempItem = self.todoList.todoItems[tempTargetIndexPath.row];
      [self.todoList.todoItems removeObjectAtIndex:tempTargetIndexPath.row];
      [self.todoList.todoItems insertObject:tempItem atIndex:newIndexPath.row];
      completionBlock();
    }];
    LXMTodoItem *tempItem = self.todoList.todoItems[indexPath.row];
    [self.todoList.todoItems removeObjectAtIndex:indexPath.row];
    [self.todoList.todoItems insertObject:tempItem atIndex:tempTargetIndexPath.row];
    [self.tableView moveRowAtIndexPath:indexPath toIndexPath:tempTargetIndexPath];
    [CATransaction commit];
    [UIView commitAnimations];
  } else {
    LXMTodoItem *tempItem = self.todoList.todoItems[indexPath.row];
    [self.todoList.todoItems removeObjectAtIndex:indexPath.row];
    [self.todoList.todoItems insertObject:tempItem atIndex:newIndexPath.row];
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:LXMTableViewRowAnimationDurationNormal];
    [CATransaction begin];
    [CATransaction setCompletionBlock:completionBlock];
    [self.tableView moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
    [CATransaction commit];
    [UIView commitAnimations];
  }
}

- (void)deleteRowAtIndexPath:(NSIndexPath *)indexPath {

  self.tableViewState.operationState = LXMTableViewOperationStateAnimating;

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
    [self.todoList.todoItems removeObjectAtIndex:indexPath.row];
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

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.todoList.todoItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  LXMTodoItem *todoItem = self.todoList.todoItems[indexPath.row];
  UIColor *backgroundColor = [self colorForRowAtIndexPath:indexPath];

  if (todoItem.usage != LXMTodoItemUsageNormal) {
    NSString *reuseIdentifier;
    LXMTransformableTableViewCellStyle style;
    NSString *processingText;
    NSString *committingText;

    switch (todoItem.usage) {
      case LXMTodoItemUsagePinchAdded:
        reuseIdentifier = @"UnfoldingCell";
        style = LXMTransformableTableViewCellStyleUnfolding;
        processingText = @"继续 pinch ";
        committingText = @"可以松开了";
        break;

      case LXMTodoItemUsagePullAdded:
        reuseIdentifier = @"PullDownCell";
        style = LXMTransformableTableViewCellStylePullDown;
        processingText = @"继续下拉";
        committingText = @"可以松开了";
        break;

      case LXMTodoItemUsageTapAdded:
        reuseIdentifier = @"PushDownCell";
        style = LXMTransformableTableViewCellStylePushDown;
        processingText = @"lalala";
        committingText = @"ok";
        break;

      case LXMTodoItemUsagePlaceholder:
        reuseIdentifier = @"PlaceholderCell";
        style = LXMTransformableTableViewCellStyleUnfolding;
        processingText = @"";
        committingText = @"";
        break;
    }

    LXMTransformableTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (!cell) {
      cell = [LXMTransformableTableViewCell transformableTableViewCellWithStyle:style reuseIdentifier:reuseIdentifier];
    }
    cell.tintColor = backgroundColor;
    cell.finishedHeight = [LXMGlobalSettings sharedInstance].modifyingRowHeight;

    if ([LXMTableViewState sharedInstance].addingProgress >= 1) {
      cell.textLabel.text = committingText;
    } else {
      cell.textLabel.text = processingText;
    }

    NSLog(@"**** cell for row: %@", cell);
    return cell;
  }

//  if (todoItem.usage == LXMTodoItemUsagePinchAdded) {
//    NSString *reuseIdentifier = @"UnfoldingCell";
//    LXMTransformableTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
//    if (!cell) {
//      cell = [LXMTransformableTableViewCell transformableTableViewCellWithStyle:LXMTransformableTableViewCellStyleUnfolding reuseIdentifier:reuseIdentifier];
//    }
//  } else if (todoItem.usage == LXMTodoItemUsagePullAdded) {
//    NSString *reuseIdentifier = @"PullDownCell";
//    LXMTransformableTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
//    if (!cell) {
//      cell = [LXMTransformableTableViewCell transformableTableViewCellWithStyle:LXMTransformableTableViewCellStylePullDown reuseIdentifier:reuseIdentifier];
//    }
//  }
//
//  if ([todoItem.text isEqualToString:kAddingCell]) {
//    NSString *reuseIdentifier;
//    LXMTransformableTableViewCell *cell;
//    if (indexPath.row == 0) {
//      reuseIdentifier = @"PullDownCell";
//      cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
//      if (!cell) {
//        cell = [LXMTransformableTableViewCell transformableTableViewCellWithStyle:LXMTransformableTableViewCellStylePullDown reuseIdentifier:reuseIdentifier];
//      }
//    } else {
//      reuseIdentifier = @"UnfoldingCell";
//      cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
//
//      if (!cell) {
//        cell = [LXMTransformableTableViewCell transformableTableViewCellWithStyle:LXMTransformableTableViewCellStyleUnfolding reuseIdentifier:reuseIdentifier];
//      }
//    }
//    cell.tintColor = backgroundColor;
//    cell.finishedHeight = [LXMGlobalSettings sharedInstance].modifyingRowHeight;
//    if (cell.frame.size.height > cell.finishedHeight) {
//      cell.textLabel.text = @"Release to create cell";
//    } else {
//      cell.textLabel.text = @"Continue pinching";
//    }
//    return cell;
//  }
  else {
    static NSString *reuseIdentifier = @"NormalCell";
    LXMTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (!cell) {
      cell = [[LXMTableViewCell alloc] initWithReuseIdentifier:reuseIdentifier];
    }
    cell.todoItem = todoItem;
    cell.delegate = self;
    cell.actualContentView.backgroundColor = backgroundColor;
    cell.strikeThroughText.textColor = [self textColorForRowAtIndexPath:indexPath];

    return cell;
  }
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return [LXMGlobalSettings sharedInstance].normalRowHeight;
}

#pragma mark - TableView Helper Methods

- (UIColor *)colorForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  return [self colorForRowAtIndexPath:indexPath ignoreTodoItem:NO];
}

- (UIColor *)colorForRowAtIndexPath:(NSIndexPath *)indexPath ignoreTodoItem:(BOOL)shouldIgnore {
  
  UIColor *backgroundColor = [[LXMGlobalSettings sharedInstance].itemBaseColor lxm_colorWithHueOffset:[LXMGlobalSettings sharedInstance].colorHueOffset * (indexPath.row + 1) / self.todoList.todoItems.count];
//  UIColor *backgroundColor = [UIColor clearColor];
  
  if (!shouldIgnore) {
    if (self.todoList.todoItems[indexPath.row].isCompleted) {
      backgroundColor = [UIColor blackColor];
    }
  }
  
  return backgroundColor;
}

- (UIColor *)textColorForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  if (self.todoList.todoItems[indexPath.row].isCompleted) {
    return [UIColor grayColor];
  } else {
    return [UIColor whiteColor];
  }
}

#pragma mark - LXMTableViewGestureAddingRowDelegate

- (BOOL)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer canAddCellAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.row == [self.todoList.todoItems count]) {
    return !self.todoList.todoItems.lastObject.isCompleted;
  } else {
    return indexPath.row == 0 || !self.todoList.todoItems[indexPath.row - 1].isCompleted;
  }
}

- (void)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer needsAddRowAtIndexPath:(NSIndexPath *)indexPath usage:(LXMTodoItemUsage)usage {

  [LXMTableViewState sharedInstance].operationState = LXMTableViewOperationStateAdding;

  // 块：（无动画）插入一个高度为零的行。

  void (^insertRowWithAnimation)() = ^{
    [self.todoList.todoItems insertObject:[LXMTodoItem todoItemWithUsage:usage] atIndex:indexPath.row];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
  };

  void (^insertRowWithoutAnimation)() = ^{
    [UIView performWithoutAnimation:^{
      insertRowWithAnimation();
    }];
  };

  switch (usage) {
    case LXMTodoItemUsagePinchAdded:
      // 仅插入行即可。
      insertRowWithoutAnimation();
      break;

    case LXMTodoItemUsageTapAdded: {
      // 用动画插入行。
      [UIView beginAnimations:nil context:nil];
      [UIView setAnimationDuration:4];
      [CATransaction begin];
      [CATransaction setCompletionBlock:^{
        [self p_handleNewRowAtIndexPath:indexPath forAdding:YES];
      }];
      [self.tableView beginUpdates];
      insertRowWithAnimation();
      [self.tableView endUpdates];
      [CATransaction commit];
      [UIView commitAnimations];

      UITableViewCell *transformingCell = [self.tableView cellForRowAtIndexPath:indexPath];

      // 定义 pop 属性动画，随 table view update 动画刷新新插入行的 layout 至完成。
      POPBasicAnimation *refreshCell = [POPBasicAnimation animationWithPropertyNamed:kPOPViewFrame];
      refreshCell.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
      refreshCell.name = @"Refresh_Tranforming_Cell_With_Table_View_Updating";
      refreshCell.duration = 4;
      refreshCell.fromValue = [NSValue valueWithCGRect:CGRectMake(transformingCell.frame.origin.x, transformingCell.frame.origin.y, transformingCell.frame.size.width, 0)];
      refreshCell.toValue = [NSValue valueWithCGRect:
                             CGRectMake(transformingCell.frame.origin.x,
                                       transformingCell.frame.origin.y,
                                       transformingCell.frame.size.width,
                                       [LXMGlobalSettings sharedInstance].normalRowHeight)];
      refreshCell.beginTime = CACurrentMediaTime();
      [transformingCell pop_addAnimation:refreshCell forKey:@"LXMKey"];
    }
      break;

    case LXMTodoItemUsagePullAdded:
      // TODO: 下拉新增todo
      break;

    case LXMTodoItemUsagePlaceholder:
    case LXMTodoItemUsageNormal:
      // TODO: 是否需要实现 placeholer 和 normal?
      break;
  }
}

//- (void)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer isAddingRowAtIndexPath:(NSIndexPath *)indexPath {
//  
//  CGFloat height = [self.tableView cellForRowAtIndexPath:indexPath].bounds.size.height;
//  height = MIN(self.tableView.rowHeight, height);
      // TODO: cell 背景色应随 pinch 变化  
//  [self.tableView.visibleCells enumerateObjectsUsingBlock:^(__kindof UITableViewCell * _Nonnull  obj, NSUInteger idx, BOOL * _Nonnull stop) {
//    if ([self.tableView indexPathForCell:obj] != indexPath) {
      
//      LXMTableViewCell *lxmCell = (LXMTableViewCell *)obj;
//      [lxmCell updateViewBackgroundColorWithPercentage:height / self.tableView.rowHeight];
//    }
//  }];
//}

- (void)p_recoverRowAtIndexPath:(NSIndexPath *)indexPath forAdding:(BOOL)shouldAdd {

  UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
  CGFloat currentRowHeight = cell.frame.size.height;
  CGFloat finishedRowHeight = shouldAdd ? [LXMGlobalSettings sharedInstance].normalRowHeight : 0;

  LXMAnimationBlock recoverHeightAnimation = ^(BOOL finished) {
    if (indexPath.row > 0) {
      // for pinch added rows
      [UIView animateWithDuration:LXMTableViewRowAnimationDurationNormal animations:^{
        // 设置新增 cell 的高度到正常行的高度或 0。
        cell.frame = CGRectMake(cell.frame.origin.x, cell.frame.origin.y, cell.frame.size.width, finishedRowHeight);
        // 恢复 table view 的 offset 和 inset。
        [self.tableViewState recoverTableViewContentOffsetAndInset];
        // 恢复其余 cell 的位置
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
        // 发出操作完成的通知并刷新列表。
        [[NSNotificationCenter defaultCenter] postNotificationName:LXMOperationCompleteNotification object:self];
        [self.tableView reloadData];
        self.animationQueue.blockCompletion()(YES);
      }];
    } else {
      // for pulldown added rows
      [UIView animateWithDuration:LXMTableViewRowAnimationDurationLong animations:^{

      } completion:^(BOOL finished) {
        // 发出操作完成的通知并刷新列表。
        [[NSNotificationCenter defaultCenter] postNotificationName:LXMOperationCompleteNotification object:self];
        [self.tableView reloadData];
        self.animationQueue.blockCompletion()(YES);
      }];
    }
  };

  [self.animationQueue addAnimations:recoverHeightAnimation, nil];

}

- (void)p_replaceRowAtIndexPathToNormal:(NSIndexPath *)indexPath {

  LXMAnimationBlock replaceWithNoAnimation = ^(BOOL finished) {
    [UIView performWithoutAnimation:^{
      [self.todoList.todoItems replaceObjectAtIndex:indexPath.row withObject:[LXMTodoItem todoItemWithText:@""]];
      [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }];
    [self.tableView reloadData];
    self.animationQueue.blockCompletion()(YES);
  };

  [self.animationQueue addAnimations:replaceWithNoAnimation, nil];
}

- (void)p_assignModifyRowAtIndexPath:(NSIndexPath *)indexPath {

  LXMAnimationBlock assignRowAnimation = ^(BOOL finished){
    if (!self.todoList.todoItems[indexPath.row].isCompleted) {
      LXMTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
      [cell.strikeThroughText becomeFirstResponder];
    }
    self.animationQueue.blockCompletion();
  };

  [self.animationQueue addAnimations:assignRowAnimation, nil];
}

- (void)p_handleNewRowAtIndexPath:(NSIndexPath *)indexPath forAdding:(BOOL)willAdd {

  if (willAdd) {
    NSLog(@"1");
    // 1. recover heigth
    [self p_recoverRowAtIndexPath:indexPath forAdding:YES];
    // 2. replace todo
    [self p_replaceRowAtIndexPathToNormal:indexPath];
    // 3. reload table view(put in step 2)
    // 4. assign firstResponder
    [self p_assignModifyRowAtIndexPath:indexPath];

  } else {
    // 1. set height to 0
    // 2. delete tempt todo
    // 3. reload table view
  }

  self.animationQueue.queueCompletion = ^(BOOL finished) {
    NSLog(@"hahaha");
  };
  [self.animationQueue play];
}

- (void)resetCellAtIndexPath:(NSIndexPath *)indexPath forAdding:(BOOL)shouldAdd {

  [LXMTableViewState sharedInstance].operationState = LXMTableViewOperationStateAnimating;

  LXMTransformableTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
  CGFloat finishedRowHeight;
  CGFloat currentRowHeight = cell.frame.size.height;
  if (shouldAdd) {
    finishedRowHeight = [LXMGlobalSettings sharedInstance].modifyingRowHeight;
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
        identity.m34 = [LXMGlobalSettings sharedInstance].addingM34;
        transform = CATransform3DRotate(identity, (CGFloat)M_PI_2, 1, 0, 0);
        [self startAnimation];
      }

      [UIView animateWithDuration:LXMTableViewRowAnimationDurationNormal animations:^{
        if (shouldAdd) {
          for (UITableViewCell *visibleCell in self.tableView.visibleCells) {
            if ([self.tableView indexPathForCell:visibleCell].row != indexPath.row) {
              visibleCell.frame = CGRectOffset(visibleCell.frame, 0, -(cell.frame.size.height - [LXMGlobalSettings sharedInstance].modifyingRowHeight));
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

        [self.tableViewState recoverTableViewContentOffsetAndInset];

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
      animationQueue.blockCompletion()(YES);
    }];
  };

  [animationQueue addAnimations:resetTableView, assignFirstResponder, nil];
  [animationQueue play];
}

- (void)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer needsCommitRowAtIndexPath:(NSIndexPath *)indexPath {
  
  [self.todoList.todoItems replaceObjectAtIndex:indexPath.row withObject:[LXMTodoItem todoItemWithText:@""]];
  LXMTransformableTableViewCell *cell = [recognizer.tableView cellForRowAtIndexPath:indexPath];
  [self resetCellAtIndexPath:indexPath forAdding:YES];
  
  
  BOOL isFirstRow = (indexPath.section == 0) && (indexPath.row == 0);
  if (isFirstRow) {
    if (cell.frame.size.height > [LXMGlobalSettings sharedInstance].modifyingRowHeight * 2) {
      [self.todoList.todoItems removeObjectAtIndex:indexPath.row];
      [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationMiddle];
    } else {
      cell.finishedHeight = [LXMGlobalSettings sharedInstance].modifyingRowHeight;
//      cell.textLabel.text = @"Just added!";
    }
  }
}

- (void)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer needsDiscardRowAtIndexPath:(NSIndexPath *)indexPath {
  [self.todoList.todoItems removeObjectAtIndex:indexPath.row];
  [self resetCellAtIndexPath:indexPath forAdding:NO];
}

#pragma mark - LXMTableViewGestureEditingRowDelegate

- (BOOL)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  
  BOOL __block canEdit = YES;
  [self.tableViewState.uneditableIndexPaths enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    if (indexPath == obj) {
      canEdit = NO;
      *stop = YES;
    }
  }];
  
  return canEdit;
}

- (void)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer didEnterEditingState:(LXMTableViewCellEditingState)editingState forRowAtIndexPath:(NSIndexPath *)indexPath {

  LXMTableViewCell *cell = self.tableViewState.panningCell;
  indexPath = [self.tableView indexPathForCell:cell];
  
  if (cell.todoItem.isCompleted) {
    switch (editingState) {
      case LXMTableViewCellEditingStateDeleting:
      case LXMTableViewCellEditingStateNormal:
        cell.actualContentView.backgroundColor = [UIColor blackColor];
        cell.strikeThroughText.textColor = [UIColor grayColor];
        break;
        
      case LXMTableViewCellEditingStateCompleting:
        cell.actualContentView.backgroundColor = [self colorForRowAtIndexPath:[self movingDestinationIndexPathForRowAtIndexPath:indexPath] ignoreTodoItem:YES];
        cell.strikeThroughText.textColor = [UIColor whiteColor];
        break;
      
      case LXMTableViewCellEditingStateNone:
        break;
    }
  } else {
    switch (editingState) {
      case LXMTableViewCellEditingStateDeleting:
      case LXMTableViewCellEditingStateNormal:
        cell.actualContentView.backgroundColor = [self colorForRowAtIndexPath:indexPath];
        cell.strikeThroughText.textColor = [UIColor whiteColor];
        break;
        
      case LXMTableViewCellEditingStateCompleting:
        cell.actualContentView.backgroundColor = [LXMGlobalSettings sharedInstance].editingCompletedColor;
        cell.strikeThroughText.textColor = [UIColor whiteColor];
        break;
        
      case LXMTableViewCellEditingStateNone:
        break;
    }
  }
}

- (void)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer didCommitEditingState:(LXMTableViewCellEditingState)editingState forRowAtIndexPath:(NSIndexPath *)indexPath {
  
  LXMTableViewCell *cell = self.tableViewState.panningCell;
  indexPath = [self.tableView indexPathForCell:cell];// very importent
  
  self.tableViewState.panningCell = nil;
  
  switch (editingState) {
    case LXMTableViewCellEditingStateDeleting:
      [self deleteRowAtIndexPath:indexPath];
      break;
      
    case LXMTableViewCellEditingStateNormal:
    case LXMTableViewCellEditingStateNone:
      [self bounceCell:cell check:NO];
      break;
      
    case LXMTableViewCellEditingStateCompleting:
      self.todoList.todoItems[indexPath.row].isCompleted = !self.todoList.todoItems[indexPath.row].isCompleted;
      [self bounceCell:cell check:YES];
      break;
  }
}

#pragma mark - LXMTableViewGestureMoveRowDelegate

- (BOOL)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
  
  return YES;
}

- (void)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer needsCreatePlaceholderForRowAtIndexPath:(NSIndexPath *)indexPath {
  self.tableViewState.operationState = LXMTableViewOperationStateRearranging;
  self.grabbedTodoItem = self.todoList.todoItems[indexPath.row];
  [self.todoList.todoItems replaceObjectAtIndex:indexPath.row withObject:[LXMTodoItem todoItemWithText:kDummyCell]];
}

- (void)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer needsMovePlaceholderForRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
  
  id object = self.todoList.todoItems[sourceIndexPath.row];
  [self.todoList.todoItems removeObjectAtIndex:sourceIndexPath.row];
  [self.todoList.todoItems insertObject:object atIndex:destinationIndexPath.row];
}

- (void)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer needsReplacePlaceholderForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  [self.todoList.todoItems replaceObjectAtIndex:indexPath.row withObject:self.grabbedTodoItem];
  self.grabbedTodoItem = nil;
}

#pragma mark - LXMTableViewCellDelegate

- (BOOL)tableViewCellShouldBeginTextEditing:(LXMTableViewCell *)cell {
  
  return YES;
}

- (void)tableViewCellDidBeginTextEditing:(LXMTableViewCell *)cell {

  cell.isModifying = YES;

  self.tableViewState.modifyingRowIndexPath = [self.tableView indexPathForCell:cell];
  [self.tableViewState saveTableViewLastContentOffsetAndInset];
  self.tableViewState.operationState = LXMTableViewOperationStateModifying;
  [self.tableViewRecognizer allowGesturesOnly:LXMTableViewGestureRecognizerOptionsTap | LXMTableViewGestureRecognizerOptionsVerticalPan];

  // 重要：如不设置 contentInset.bottom，当点击屏幕上最后几个 cell 时会出现意想不到的情况。
  self.tableView.contentInset =
      UIEdgeInsetsMake(self.tableView.contentInset.top,
          self.tableView.contentInset.left,
          self.tableView.contentInset.bottom + self.tableView.bounds.size.height - self.tableView.rowHeight,
          self.tableView.contentInset.right);

  [UIView animateWithDuration:self.keyboardAnimationDuration delay:0 options:self.keyboardAnimationCurveOption animations:^{
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
  
  [UIView animateWithDuration:self.keyboardAnimationDuration delay:0 options:self.keyboardAnimationCurveOption animations:^{
    for (LXMTableViewCell *visibleCell in self.tableView.visibleCells) {
      if (cell != visibleCell) {
        visibleCell.alpha = 1.0f;
      }
    }
    [self.tableViewState recoverTableViewContentOffsetAndInset];
  } completion:^(BOOL finished) {
    self.tableView.scrollEnabled = YES;
    self.tableView.bounces = YES;
    cell.isModifying = NO;
    self.tableViewState.modifyingRowIndexPath = nil;

    if ([cell.strikeThroughText.text isEqualToString:@""]) {
      [self deleteRowAtIndexPath:[self.tableView indexPathForCell:cell]];
    } else {
      [[NSNotificationCenter defaultCenter] postNotificationName:LXMOperationCompleteNotification object:self];
      [self.tableView reloadData];
    }
  }];
}

#pragma mark - PopAnimationDelegate

//- (void)pop_animationDidApply:(POPAnimation *)anim {
//  NSLog(@"%f", self);
//}
//
//- (void)pop_animationDidStop:(POPAnimation *)anim finished:(BOOL)finished {
//
//  if (finished) {
//    NSLog(@"100");
//  }
//}

@end