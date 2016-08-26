//
// Created by FLY.lxm on 2016.18.8.
// Copyright (c) 2016 FLY.lxm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class LXMTableViewState;
@class LXMTableViewGestureRecognizer;

typedef NS_ENUM(NSUInteger, LXMTableViewOperationStateCode) {
  LXMTableViewOperationStateCodeNormal,         ///< 正常状态，没有任何操作在进行。
  LXMTableViewOperationStateCodeModifying,      ///< 正在修改一个 todo 的文字。
  LXMTableViewOperationStateCodeChecking,     ///< 正在（向右拖动）修改一个 todo 的完成状态。
  LXMTableViewOperationStateCodeDeleting,       ///< 正在（向左拖动）删除一个 todo。
  LXMTableViewOperationStateCodePinchAdding,         ///< 正在新建一个 todo。
  LXMTableViewOperationStateCodePinchTranslating,  ///< 通过 pinch 缩小来返回上一级菜单。
  LXMTableViewOperationStateCodePanTranslating,  ///< 通过 pan 来移动到下一个或者上一个列表。
  LXMTableViewOperationStateCodePullAdding,
  LXMTableViewOperationStateCodeRearranging,    ///< （长按后）正在拖动一个 todo 到某个位置。
  LXMTableViewOperationStateCodeRecovering,      ///< 正在执行某些操作完成后的动画，不允许交互。
  LXMTableViewOperationStateCodeProcessing,     ///< 正在执行某些操作完成后的动画，但允许某些交互。
};

@protocol LXMTableViewOperationStateProtocol

- (void)handlePinch:(UIPinchGestureRecognizer *)recognizer;
- (void)handlePan:(UIPanGestureRecognizer *)recognizer;
- (void)handleLongPress:(UILongPressGestureRecognizer *)recognizer;
- (void)handleTap:(UITapGestureRecognizer *)recognizer;
- (void)handleScroll:(UITableView *)tableView;

@optional

- (void)didFinished; ///< 应该有一个方法，能够在上一个状态完成后，跳转到下一个状态。

@end


@interface LXMTableViewOperationState<LXMTableViewOperationStateProtocol> : NSObject

@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, weak) LXMTableViewState *tableViewState;
@property (nonatomic, weak) LXMTableViewGestureRecognizer *tableViewGestureRecognizer;

+ (instancetype)operationStateWithTableViewGestureRecognizer:(LXMTableViewGestureRecognizer *)tableViewGestureRecognizer operationStateCode:(LXMTableViewOperationStateCode)stateCode;

@end