//
//  LXMTodoItem.h
//  LXM's Gesture Recoginizer
//
//  Created by FLY.lxm on 4/9/16.
//  Copyright © 2016 FLY.lxm. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LXMTodoItem : NSObject

@property (nonatomic, assign) BOOL isCompleted;
@property (nonatomic, strong) NSString *text;

+ (instancetype)todoItemWithText:(NSString *)text;

- (BOOL)toggleCompleted;

@end
