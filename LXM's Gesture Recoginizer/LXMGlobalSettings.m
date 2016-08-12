//
//  LXMGlobalSetting.m
//  LXM's Gesture Recoginizer
//
//  Created by FLY.lxm on 4/12/16.
//  Copyright © 2016 FLY.lxm. All rights reserved.
//

#import "LXMGlobalSettings.h"
#import "UIColor+LXMTableViewGestureRecognizerHelper.h"

@interface LXMGlobalSettings ()

// color
@property (nonatomic, strong, readwrite) UIColor *itemBaseColor;
@property (nonatomic, strong, readwrite) UIColor *listBaseColor;
@property (nonatomic, strong, readwrite) UIColor *editingCompletedColor;
@property (nonatomic, assign, readwrite) CGFloat colorHueOffset;

/// 当值为 YES 时，在各行之间绘制一条半透明分割线。
@property (nonatomic, assign, readwrite) BOOL shouldSeparateRow;

// font

// size & constraints
@property (nonatomic, assign, readwrite) CGFloat normalRowHeight;
@property (nonatomic, assign, readwrite) CGFloat modifyingRowHeight;
@property (nonatomic, assign, readwrite) CGFloat textFieldLeftPadding;
@property (nonatomic, assign, readwrite) CGFloat textFieldLeftMargin;
@property (nonatomic, assign, readwrite) CGFloat textFieldRightMargin;

@property (nonatomic, assign, readwrite) CGFloat editCommitTriggerWidth;


// behavior conditions
@property (nonatomic, assign, readwrite) CATransform3D addingTransform3DIdentity;
//@property (nonatomic, assign) CGFloat panCommitCellDistance;
//@property (nonatomic, assign) CGFloat pullDownCommitCellDistance;
//@property (nonatomic, assign) CGFloat pullDownTransformViewDistance;

@end

@implementation LXMGlobalSettings

- (instancetype)init {
  
  if (self = [super init]) {
    // color
    UIColor *baseColor = [UIColor colorWithHue:0.4 saturation:0.7 brightness:0.7 alpha:1];
    self.listBaseColor = baseColor;
    self.itemBaseColor = [baseColor lxm_colorWithBrightnessOffset:0.1];
    CGFloat baseHue;
    [baseColor getHue:&baseHue saturation:nil brightness:nil alpha:nil];
    self.editingCompletedColor = [baseColor lxm_colorWithHueOffset:baseHue - (1 - baseHue)];
    self.colorHueOffset = 0.06f;
    
    // fonts
    
    // size & constraints
    self.textFieldLeftPadding = 5.0f;
    self.textFieldLeftMargin = 16.0f;
    self.textFieldRightMargin = 16.0f;
    
    self.normalRowHeight = 60.0f;
    self.modifyingRowHeight = 60.0f;
    self.shouldSeparateRow = YES;

    // behavior & conditions
    CATransform3D identity = CATransform3DIdentity;
    identity.m34 = -1 / 500.0f;
    self.addingTransform3DIdentity = identity;
  }
  return self;
}

+ (instancetype)sharedInstance {
  
  static LXMGlobalSettings *singleInstance;
  static dispatch_once_t oncePredicate;
  dispatch_once(&oncePredicate, ^{
    singleInstance = [LXMGlobalSettings new];
  });
  return singleInstance;
}

#pragma mark - getters & setters

- (CGFloat)editCommitTriggerWidth {
  NSString *string = @"\u2713";
  CGFloat width = [string sizeWithAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:40]}].width + 10;
  return width;
}

@end
