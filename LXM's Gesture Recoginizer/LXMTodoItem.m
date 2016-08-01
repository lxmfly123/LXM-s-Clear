//
//  LXMTodoItem.m
//  LXM's Gesture Recoginizer
//
//  Created by FLY.lxm on 4/9/16.
//  Copyright © 2016 FLY.lxm. All rights reserved.
//

#import "LXMTodoItem.h"

@implementation LXMTodoItem

+ (instancetype)todoItemWithText:(NSString *)text {
  LXMTodoItem *todoItem = [LXMTodoItem new];
  if (todoItem) {
    todoItem.text = text;
    todoItem.isCompleted = NO;
  }
  return todoItem;
}

- (BOOL)toggleCompleted {
  self.isCompleted = !self.isCompleted;
  return self.isCompleted;
}

@end
