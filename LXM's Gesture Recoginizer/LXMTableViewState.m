//
//  LXMTableViewState.m
//  LXM's Gesture Recoginizer
//
//  Created by FLY.lxm on 5/20/16.
//  Copyright © 2016 FLY.lxm. All rights reserved.
//

#import "LXMTableViewState.h"
#import "LXMGlobalSettings.h" 

NSString * const LXMOperationCompleteNotification = @"OperationComplete";

@interface LXMTableViewState ()

// redefined public
@property (nonatomic, strong, readwrite) NSArray<NSIndexPath *> *uneditableIndexPaths;
@property (nonatomic, strong, readwrite) UIView *assistView;

// private
@property (nonatomic, weak) LXMGlobalSettings *globalSettings;
@property (nonatomic, assign) CGPoint lastContentOffset;
@property (nonatomic, assign) UIEdgeInsets lastContentInset;

@property (nonatomic, strong) CADisplayLink *displayLink; ///< 用于某些动画需要随动画进行更新某些值时的计算。
@property (nonatomic, copy, nullable) void (^updatingBlock)(); ///< 动画需要随动画进行更新某些值时的计算块。

@end

@implementation LXMTableViewState

- (instancetype)init {
  
  if (self = [super init]) {
    self.floatingCells = [[NSMutableArray alloc] initWithCapacity:4];
    self.bouncingCells = [[NSMutableArray alloc] initWithCapacity:2];
    self.globalSettings = [LXMGlobalSettings sharedInstance];
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

- (NSArray<NSIndexPath *> *)uneditableIndexPaths {
  
  NSMutableArray *tempArray = [[NSMutableArray alloc] initWithArray:self.bouncingCells];
  [tempArray addObjectsFromArray:self.floatingCells];
  if (self.panningCell) {
    [tempArray addObject:self.panningCell];
  }
  NSMutableArray<NSIndexPath *> *indexPaths = [[NSMutableArray alloc] initWithCapacity:5];
  [tempArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    [indexPaths addObject:[self.tableView indexPathForCell:obj]];
  }];
  _uneditableIndexPaths = [NSArray arrayWithArray:indexPaths];
  return _uneditableIndexPaths;
}

- (UIView *)assistView {

  if (!_assistView) {
    _assistView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, self.globalSettings.addingRowFinishedHeight)];
  }

  if (_addingProgress >= 0) {

    CGFloat angle = acosf(_addingProgress);
    _assistView.layer.anchorPoint = (CGPoint){0.5, 0};
    _assistView.layer.transform = CATransform3DRotate([LXMGlobalSettings sharedInstance].addingTransform3D, angle, -1, 0, 0);
  }

  return _assistView;
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
  endingBlock();
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
  
  self.tableView = nil;
  self.panningCell = nil;
  [self.bouncingCells removeAllObjects];
  [self.floatingCells removeAllObjects];
}

- (void)saveTableViewLastContentOffsetAndInset {

  self.lastContentOffset = self.tableView.contentOffset;
  self.lastContentInset = self.tableView.contentInset;
}

- (void)recoverTableViewContentOffsetAndInset {

  self.tableView.contentOffset = self.lastContentOffset;
  self.tableView.contentInset = self.lastContentInset;

  self.lastContentOffset = CGPointZero;
  self.lastContentInset = UIEdgeInsetsZero;
}

@end
