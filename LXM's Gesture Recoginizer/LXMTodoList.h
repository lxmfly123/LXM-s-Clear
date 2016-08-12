//
// Created by FLY.lxm on 2016.9.8.
// Copyright (c) 2016 FLY.lxm. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LXMTodoItem;

@interface LXMTodoList : NSObject

@property (nonatomic, strong) NSMutableArray<LXMTodoItem *> *todoItems;
@property (nonatomic, assign, readonly) NSUInteger numberOfUncompleted;
@property (nonatomic, assign, readonly) NSUInteger numberOfCompleted;

+ (instancetype)listWithTodoItems:(LXMTodoItem *)todoItems, ... NS_REQUIRES_NIL_TERMINATION;

@end