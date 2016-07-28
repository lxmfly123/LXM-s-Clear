//
//  LXMTableViewState.m
//  LXM's Gesture Recoginizer
//
//  Created by FLY.lxm on 5/20/16.
//  Copyright © 2016 FLY.lxm. All rights reserved.
//

#import "LXMTableViewState.h"
#import "LXMGlobalSettings.h" 

NSString *LXMEditCompleteNotification = @"EditComplete";

@interface LXMTableViewState ()

@property (nonatomic, weak) LXMGlobalSettings *globalSettings;

@property (nonatomic, strong, readwrite) NSArray<NSIndexPath *> *uneditableIndexPathes;
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
    singleInstance.lastContentOffset = CGPointZero;
  });
  return singleInstance;
}

- (NSArray<NSIndexPath *> *)uneditableIndexPathes {
  
  NSMutableArray *tempArray = [[NSMutableArray alloc] initWithArray:self.bouncingCells];
  [tempArray addObjectsFromArray:self.floatingCells];
  if (self.panningCell) {
    [tempArray addObject:self.panningCell];
  }
  NSMutableArray<NSIndexPath *> *indexPathes = [[NSMutableArray alloc] initWithCapacity:5];
  [tempArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    [indexPathes addObject:[self.tableView indexPathForCell:obj]];
  }];
  _uneditableIndexPathes = [NSArray arrayWithArray:indexPathes];
  return _uneditableIndexPathes;
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
