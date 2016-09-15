//
//  LXMTableViewHelper.m
//  LXM's Gesture Recoginizer
//
//  Created by FLY.lxm on 5/4/16.
//  Copyright © 2016 FLY.lxm. All rights reserved.
//

#import "LXMTableViewHelper.h"
#import "LXMTodoItem.h"
#import "LXMTodoList.h"
#import "LXMTableViewState.h"
#import "LXMTableViewCell.h"
#import "LXMTableViewGestureRecognizer.h"
#import "LXMGlobalSettings.h"
#import "UIColor+LXMTableViewGestureRecognizerHelper.h"
#import "LXMAnimationQueue.h"

@interface LXMTableViewHelper ()

@property (nonatomic, weak) LXMGlobalSettings *globalSettings;
@property (nonatomic, weak) LXMTableViewState *tableViewState;
@property (nonatomic, weak) LXMTableViewGestureRecognizer *tableViewGestureRecognizer;
@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, weak) LXMTableViewGestureRecognizerHelper *recognizerHelper;
@property (nonatomic, weak) LXMTodoList *list;
@property (nonatomic, strong) LXMAnimationQueue *animationQueue;

@end

@implementation LXMTableViewHelper

- (instancetype)initWithTableViewGestureRecognizer:(LXMTableViewGestureRecognizer *)tableViewGestureRecognizer tableViewState:(LXMTableViewState *)tableViewState {

  if (self = [super init]) {
    self.tableViewGestureRecognizer = tableViewGestureRecognizer;
    self.tableViewState = tableViewState;
    self.tableView = self.tableViewState.tableView;
  }

  return self;
}

#pragma mark - getters

- (LXMGlobalSettings *)globalSettings {

  if (!_globalSettings) {
    _globalSettings = [LXMGlobalSettings sharedInstance];
  }

  return _globalSettings;
}

- (LXMTodoList *)list {

  return self.tableViewState.list;
}

- (LXMTableViewGestureRecognizerHelper *)recognizerHelper {

  return self.tableViewGestureRecognizer.recognizerHelper;
}

- (LXMAnimationQueue *)animationQueue {

  if (_animationQueue == nil) {
    _animationQueue = [LXMAnimationQueue new];
  }

  return _animationQueue;
}

#pragma mark - color makers

- (UIColor *)colorForRowAtIndexPath:(NSIndexPath *)indexPath {

  return [self colorForRowAtIndexPath:indexPath ignoreTodoItem:NO];
}

- (UIColor *)colorForRowAtIndexPath:(NSIndexPath *)indexPath ignoreTodoItem:(BOOL)shouldIgnore {

  UIColor *backgroundColor = [self.globalSettings.itemBaseColor lxm_colorWithHueOffset:self.globalSettings.colorHueOffset * (indexPath.row + 1) / self.list.todoItems.count];
//  UIColor *backgroundColor = [UIColor clearColor];

  if (!shouldIgnore) {
    if (self.list.todoItems[indexPath.row].isCompleted) {
      backgroundColor = [UIColor blackColor];
    }
  }

  return backgroundColor;
}

- (UIColor *)textColorForRowAtIndexPath:(NSIndexPath *)indexPath {

  if (self.list.todoItems[indexPath.row].isCompleted) {
    return [UIColor grayColor];
  } else {
    return [UIColor whiteColor];
  }
}

#pragma mark - table view change methods

- (void)saveTableViewContentOffsetAndInset {

  self.tableViewState.lastContentOffset = self.tableView.contentOffset;
//  self.tableViewState.lastContentInset = self.tableView.contentInset;

  NSLog(@"save: %@", NSStringFromUIEdgeInsets(self.tableViewState.lastContentInset));
}

- (void)recoverTableViewContentOffsetAndInset {

  NSLog(@"before recover: %@", NSStringFromUIEdgeInsets(self.tableViewState.lastContentInset));

  self.tableView.contentOffset = self.tableViewState.lastContentOffset;
//  self.tableView.contentInset = self.tableViewState.lastContentInset;

  NSLog(@"recovered: %@", NSStringFromUIEdgeInsets(self.tableView.contentInset));

  self.tableViewState.lastContentOffset = CGPointZero;
//  self.tableViewState.lastContentInset = UIEdgeInsetsZero;

  NSLog(@"recovered last: %@", NSStringFromUIEdgeInsets(self.tableViewState.lastContentInset));
  NSLog(@"--------------------------------");
}

- (void)recoverRowAtIndexPath:(NSIndexPath *)indexPath forAdding:(BOOL)shouldAdd {

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

- (void)replaceRowAtIndexPathToNormal:(NSIndexPath *)indexPath {

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

- (void)assignModifyRowAtIndexPath:(NSIndexPath *)indexPath {

  LXMAnimationBlock assignRowAnimation = ^(BOOL finished){
    LXMTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (!cell.todoItem.isCompleted) {
      [cell.strikeThroughText becomeFirstResponder];
    }
    self.animationQueue.blockCompletion()(YES);
  };

  [self.animationQueue addAnimations:assignRowAnimation, nil];
}

- (void)bounceRowAtIndex:(NSIndexPath *)indexPath check:(BOOL)shouldCheck {

//  self.tableViewState.operationState = LXMTableViewOperationStateCodeAnimating2;
//  [self.tableViewGestureRecognizer allowGesturesOnly:LXMTableViewGestureRecognizerOptionsTap |
//      LXMTableViewGestureRecognizerOptionsHorizontalPan];

//  LXMTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
  LXMTableViewCell *cell = self.tableViewState.panningCell;
  NSIndexPath *destinationIndexPath;

//  [self.tableViewState.bouncingCells insertObject:cell atIndex:0];
  [self.tableViewState.bouncingIndexPaths insertObject:indexPath atIndex:0];

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
                     [self.tableViewState.bouncingIndexPaths removeLastObject];
//                     if (self.tableViewState.uneditableIndexPaths.count == 0) {
                     if (self.tableViewState.uneditableIndexPaths2.count == 0) {
//                       self.tableViewState.operationState = LXMTableViewOperationStateCodeNormal;
//                       [self.tableViewGestureRecognizer allowAllGestures];
                     }
                   }];
}

- (NSIndexPath *)movingDestinationIndexPathForRowAtIndexPath:(NSIndexPath *)indexPath {

  NSUInteger __block index = 0;
  [self.list.todoItems enumerateObjectsUsingBlock:^(LXMTodoItem *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
    if (!obj.isCompleted && (idx != indexPath.row)) {
      ++index;
    }
  }];

  return [NSIndexPath indexPathForRow:index inSection:0];
}

- (void)moveRowAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath {

  LXMTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
  if (cell.todoItem.isCompleted) {
    cell.actualContentView.backgroundColor = [self colorForRowAtIndexPath:indexPath];
    cell.strikeThroughText.textColor = [self textColorForRowAtIndexPath:indexPath];
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
    [self.list.todoItems removeObjectAtIndex:indexPath.row];
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

@end
