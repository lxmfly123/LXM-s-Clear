//
//  LXMTableViewState.m
//  LXM's Gesture Recoginizer
//
//  Created by FLY.lxm on 5/20/16.
//  Copyright © 2016 FLY.lxm. All rights reserved.
//

#import "LXMTableViewState.h"
#import "LXMGlobalSettings.h" 

NSString *const LXMOperationCompleteNotification = @"OperationComplete";

@interface LXMTableViewState ()

@property (nonatomic, weak) LXMGlobalSettings *globalSettings;

@property (nonatomic, assign) CGPoint lastContentOffset;
@property (nonatomic, assign) UIEdgeInsets lastContentInset;
@property (nonatomic, strong, readwrite) NSArray<NSIndexPath *> *uneditableIndexPaths;
@property (nonatomic, strong, readwrite) UIView *assistView;

@end

@implementation LXMTableViewState

- (instancetype)init {
  
  if (self = [super init]) {
    self.floatingCells = [[NSMutableArray alloc] initWithCapacity:5];
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
  return _assistView;
}

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
