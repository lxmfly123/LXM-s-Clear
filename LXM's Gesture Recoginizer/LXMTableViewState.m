//
//  LXMTableViewState.m
//  LXM's Gesture Recoginizer
//
//  Created by FLY.lxm on 5/20/16.
//  Copyright © 2016 FLY.lxm. All rights reserved.
//

#import "LXMTableViewState.h"
#import "LXMGlobalSettings.h"
#import "LXMTableViewGestureRecognizer.h"
#import "LXMTableViewGestureRecognizerHelper.h"
#import "LXMTableViewHelper.h"

NSString * const LXMOperationCompleteNotification = @"OperationComplete";

@interface LXMTableViewState ()

// redefined public
@property (nonatomic, strong, readwrite) NSArray<NSIndexPath *> *uneditableIndexPaths;

// private
@property (nonatomic, weak) LXMGlobalSettings *globalSettings;

@property (nonatomic, strong) CADisplayLink *displayLink; ///< 用于某些动画需要随动画进行更新某些值时的计算。
@property (nonatomic, copy, nullable) void (^updatingBlock)(); ///< 动画需要随动画进行更新某些值时的计算块。

@property (nonatomic, strong) UIView *unfoldingAssistView; ///< 一个不在屏幕上显示的，辅助计算 LXMUnfoldingTransformableTableViewCell 透视投影时的在屏幕上的显示高度的 view。
@property (nonatomic, strong) UIView *flippingAssistView; ///< 一个不在屏幕上显示的，辅助计算 LXMFlippingTransformableTableViewCell 透视投影时的在屏幕上的显示高度的 view。

@end

@implementation LXMTableViewState

- (instancetype)init {
  
  if (self = [super init]) {
    // TODO:  这些属性最终应写成 getter
    self.floatingCells = [[NSMutableArray alloc] initWithCapacity:4];
    self.bouncingCells = [[NSMutableArray alloc] initWithCapacity:2];
    self.floatingIndexPaths = [[NSMutableArray alloc] initWithCapacity:4];
    self.bouncingIndexPaths = [[NSMutableArray alloc] initWithCapacity:2];
  }

  return self;
}

+ (instancetype)sharedInstance {
  
  static LXMTableViewState *singleInstance;
  static dispatch_once_t oncePredicate;
  dispatch_once(&oncePredicate, ^{
    singleInstance = [LXMTableViewState new];
  });

  return singleInstance;
}

#pragma mark - getters

- (LXMGlobalSettings *)globalSettings {

  if (!_globalSettings) {
    _globalSettings = [LXMGlobalSettings sharedInstance];
  }

  return _globalSettings;
}

- (LXMTableViewGestureRecognizerHelper *)tableViewGestureRecognizer {

  if (!_tableViewGestureRecognizer) {
    NSAssert(self.tableView, @"No Table View Found...");
    NSAssert(self.viewController, @"No Available Delegate Found...");
    _tableViewGestureRecognizer = [LXMTableViewGestureRecognizer gestureRecognizerWithTableView:self.tableView delegate:self.viewController];
  }

  if (self.tableView.delegate != _tableViewGestureRecognizer) {
    self.tableViewDelegate = self.tableView.delegate;
    self.tableView.delegate = _tableViewGestureRecognizer;
  }

  return _tableViewGestureRecognizer;
}

- (LXMTableViewGestureRecognizerHelper *)recognizerHelper {

  return self.tableViewGestureRecognizer.recognizerHelper;
}

- (LXMTableViewHelper *)tableViewHelper {

  return self.tableViewGestureRecognizer.tableViewHelper;
}

- (LXMTableViewCell *)panningCell {

  return [self.tableView cellForRowAtIndexPath:self.panningRowIndexPath];
}

- (LXMTableViewCell *)rearrangingCell {

  return [self.tableView cellForRowAtIndexPath:self.rearrangingRowIndexPath];
}

- (NSArray<NSIndexPath *> *)uneditableIndexPaths2 {

  NSMutableArray *tempArray = [NSMutableArray arrayWithArray:_bouncingIndexPaths];
  [tempArray addObjectsFromArray:_floatingIndexPaths];
  _uneditableIndexPaths = [tempArray copy];
  return _uneditableIndexPaths;
}

/// Has Been Depericated!
- (NSArray<NSIndexPath *> *)uneditableIndexPaths {
  
  NSMutableArray *tempArray = [[NSMutableArray alloc] initWithArray:self.bouncingCells];
  [tempArray addObjectsFromArray:self.floatingCells];
  if (self.panningCell) {
    [tempArray addObject:self.panningCell];
  }
  NSMutableArray<NSIndexPath *> *indexPaths = [[NSMutableArray alloc] initWithCapacity:5];
  [tempArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    // FIXME: big bug!!!
    [indexPaths addObject:[self.tableView indexPathForCell:obj]];
  }];
  _uneditableIndexPaths = [NSArray arrayWithArray:indexPaths];
  return _uneditableIndexPaths;
}

#pragma mark - setters

- (void)setTableView:(UITableView *)tableView {

  NSAssert(self.viewController, @"No View Controller Found...");

  _tableView = tableView;
}

#pragma mark - display link

- (void)startAnimationWithBlock:(void (^__nonnull)())updatingBlock {
  //  self.displayLink.beginTime = CACurrentMediaTime();
  self.updatingBlock = updatingBlock;

  if (!self.displayLink) {
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateWithAnimation:)];
  }
  self.displayLink.paused = NO;
  [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)stopAnimationWithBlock:(void (^__nullable)())endingBlock {
  self.displayLink.paused = YES;
  [self.displayLink invalidate];
  self.displayLink = nil;
  if (endingBlock) {
    endingBlock();
  }
  [self.tableView.visibleCells enumerateObjectsUsingBlock:^(__kindof UITableViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    obj.layer.transform = CATransform3DIdentity;
  }];
//  [self.tableViewState recoverTableViewContentOffsetAndInset];
}

- (void)updateWithAnimation:(CADisplayLink *)displayLink {

  if (self.updatingBlock) {
    self.updatingBlock();
  }
}

#pragma mark - public methods

- (void)resetState {

  [self.bouncingIndexPaths removeAllObjects];
  [self.floatingIndexPaths removeAllObjects];
}

//- (void)saveTableViewContentOffsetAndInset {
//
//  self.lastContentOffset = self.tableView.contentOffset;
//  self.lastContentInset = self.tableView.contentInset;
//}
//
//- (void)recoverTableViewContentOffsetAndInset {
//
//  self.tableView.contentOffset = self.lastContentOffset;
//  self.tableView.contentInset = self.lastContentInset;
//
//  self.lastContentOffset = CGPointZero;
//  self.lastContentInset = UIEdgeInsetsZero;
//}

@end
