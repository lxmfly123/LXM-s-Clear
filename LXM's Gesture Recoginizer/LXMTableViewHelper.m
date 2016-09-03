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
#import "LXMGlobalSettings.h"
#import "UIColor+LXMTableViewGestureRecognizerHelper.h"

@interface LXMTableViewHelper ()

@property (nonatomic, weak) LXMTableViewState *tableViewState;
@property (nonatomic, weak) LXMGlobalSettings *globalSettings;

@end

@implementation LXMTableViewHelper

+ (instancetype)sharedInstance {

  static LXMTableViewHelper *singleInstance;
  static dispatch_once_t oncePredicate;
  dispatch_once(&oncePredicate, ^{
    singleInstance = [LXMTableViewHelper new];
  });
  return singleInstance;
}

- (instancetype)init {

  if (self = [super init]) {
    self.tableViewState = [LXMTableViewState sharedInstance];
    self.globalSettings = [LXMGlobalSettings sharedInstance];
  }

  return self;
}

- (UIColor *)colorForRowAtIndexPath:(NSIndexPath *)indexPath {

  return [self colorForRowAtIndexPath:indexPath ignoreTodoItem:NO];
}

- (UIColor *)colorForRowAtIndexPath:(NSIndexPath *)indexPath ignoreTodoItem:(BOOL)shouldIgnore {

  UIColor *backgroundColor = [self.globalSettings.itemBaseColor lxm_colorWithHueOffset:self.globalSettings.colorHueOffset * (indexPath.row + 1) / self.todoList.todoItems.count];
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

@end
