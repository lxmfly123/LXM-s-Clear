//
//  LXMGlobalSetting.h
//  LXM's Gesture Recoginizer
//
//  Created by FLY.lxm on 4/12/16.
//  Copyright © 2016 FLY.lxm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void (^LXMAnimationBlock)(BOOL);

typedef NS_ENUM(NSUInteger, LXMTableViewCellEditingState) {
  LXMTableViewCellEditingStateNone,
  LXMTableViewCellEditingStateNormal,
  LXMTableViewCellEditingStateWillDelete,
  LXMTableViewCellEditingStateWillCheck,
};

@interface LXMGlobalSettings : NSObject

+ (instancetype)sharedInstance;

// color
@property (nonatomic, strong, readonly) UIColor *itemBaseColor;
@property (nonatomic, strong, readonly) UIColor *listBaseColor;
@property (nonatomic, strong, readonly) UIColor *editingCompletedColor;
@property (nonatomic, assign, readonly) CGFloat colorHueOffset;

/// 当值为 YES 时，在各行之间绘制一条半透明分割线。默认为 YES。 (目前未使用)
@property (nonatomic, assign, readonly) BOOL shouldSeparateRow;

// fonts

// size & constraints
@property (nonatomic, assign, readonly) CGFloat normalRowHeight;
@property (nonatomic, assign, readonly) CGFloat modifyingRowHeight;
@property (nonatomic, assign, readonly) CGFloat textFieldLeftPadding;
@property (nonatomic, assign, readonly) CGFloat textFieldLeftMargin;
@property (nonatomic, assign, readonly) CGFloat textFieldRightMargin;

@property (nonatomic, assign, readonly) CGFloat editCommitTriggerWidth;


// behavior conditions

@property (nonatomic, assign, readonly) CATransform3D addingTransform3DIdentity; ///< 新增 todo 时的 3D 透视转换矩阵，m34 默认 -1/500.0f。
@property (nonatomic, strong, readonly) NSDictionary *usageAndClass;
//@property (nonatomic, assign) CGFloat panCommitCellDistance;
//@property (nonatomic, assign) CGFloat pullDownCommitCellDistance;
//@property (nonatomic, assign) CGFloat pullDownTransformViewDistance;

@end
