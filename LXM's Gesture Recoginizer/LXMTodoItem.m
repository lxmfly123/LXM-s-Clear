//
//  LXMTodoItem.m
//  LXM's Gesture Recoginizer
//
//  Created by FLY.lxm on 4/9/16.
//  Copyright © 2016 FLY.lxm. All rights reserved.
//

#import "LXMTodoItem.h"

@implementation LXMTodoItem

+ (instancetype)todoItemWithText:(NSString *)text usage:(LXMTodoItemUsage)usage{

  LXMTodoItem *todoItem = [LXMTodoItem new];

  if (todoItem) {
    todoItem.usage = usage;
    todoItem.isCompleted = NO;

    switch (usage) {
      case LXMTodoItemUsageNormal:
        todoItem.text = text;
        break;

      case LXMTodoItemUsagePinchAdded:
      case LXMTodoItemUsagePullAdded:
      case LXMTodoItemUsageTapAdded:
      case LXMTodoItemUsagePlaceholder:
        todoItem.text = @"";
        break;
    }
  }

  return todoItem;
}

+ (instancetype)todoItemWithText:(NSString *)text {

  return [LXMTodoItem todoItemWithText:text usage:LXMTodoItemUsageNormal];
}

+ (instancetype)todoItemWithUsage:(LXMTodoItemUsage)usage {

  return [LXMTodoItem todoItemWithText:@"" usage:usage];
}

- (BOOL)toggleCompleted {
  self.isCompleted = !self.isCompleted;
  return self.isCompleted;
}

@end
