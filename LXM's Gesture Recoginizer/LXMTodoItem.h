//
//  LXMTodoItem.h
//  LXM's Gesture Recoginizer
//
//  Created by FLY.lxm on 4/9/16.
//  Copyright © 2016 FLY.lxm. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, LXMTodoItemUsage) {
  LXMTodoItemUsageNormal, ///< 正常的，用来显示在列表中的 todo。
  LXMTodoItemUsagePinchAdded, ///< 通过 pinch 新增的占位 todo，会在 pinch 新增成功后转为 normal todo。
  LXMTodoItemUsagePullAdded, ///< 通过下拉新增的占位 todo，会在下拉新增成功后转为 normal todo。
  LXMTodoItemUsageTapAdded, ///< 通过 tap 新增的占位 todo，会在 tap 新增成功后转为 normal todo。
  LXMTodoItemUsagePlaceholder, ///< 通过长按进入 todo 重排状态后产生的占位 todo，会在重排状态结束后移除。
};

@interface LXMTodoItem : NSObject

@property (nonatomic, assign) LXMTodoItemUsage usage;
@property (nonatomic, assign) BOOL isCompleted;
@property (nonatomic, strong) NSString *text;

+ (instancetype)todoItemWithText:(NSString *)text;
+ (instancetype)todoItemWithUsage:(LXMTodoItemUsage)usage;

- (BOOL)toggleCompleted;

@end
