//
// Created by FLY.lxm on 2016.9.8.
// Copyright (c) 2016 FLY.lxm. All rights reserved.
//

#import "LXMTodoList.h"
#import "LXMTodoItem.h"

@interface LXMTodoList ()

@end


@implementation LXMTodoList

+ (instancetype)listWithTodoItems:(LXMTodoItem *)todoItem1, ... {

  LXMTodoList *list = [LXMTodoList new];

  if (list) {
    [list.todoItems addObject:todoItem1];

    va_list todoItems;
    va_start(todoItems, todoItem1);
    for (LXMTodoItem *todoItem in va_arg(todoItems, LXMTodoItem *)) {
      [list.todoItems addObject:todoItem];
    }
    va_end(todoItems);
  }

  return list;
}

- (instancetype)init {

  if (self = [super init]) {
    self.todoItems = [NSMutableArray arrayWithCapacity:10];
  }

  return self;
}

#pragma mark - getters

- (NSUInteger)numberOfUncompleted {

  NSUInteger number = 0;
  for (LXMTodoItem *todoItem in self.todoItems) {
    if (!todoItem.isCompleted) {
      if (todoItem.usage == LXMTodoItemUsageNormal)
      number++;
    } else {
      break;
    }
  }

  return number;
}

- (NSUInteger)numberOfCompleted {

  NSUInteger number = 0;
  for (LXMTodoItem *todoItem in self.todoItems) {
    if (todoItem.isCompleted) {
      if (todoItem.usage == LXMTodoItemUsageNormal)
        number++;
    } else {
      break;
    }
  }

  return number;
}

@end