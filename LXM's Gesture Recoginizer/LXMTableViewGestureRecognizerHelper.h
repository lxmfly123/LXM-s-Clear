//
// Created by FLY.lxm on 2016.19.8.
// Copyright (c) 2016 FLY.lxm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LXMGlobalSettings.h"

@class LXMTableViewGestureRecognizer;

@interface LXMTableViewGestureRecognizerHelper : NSObject

@property (nonatomic, weak) LXMTableViewGestureRecognizer *tableViewGestureRecognizer;
@property (nonatomic, strong) UIImage *snapshot;
@property (nonatomic, strong) UIView *snapShotView;
@property (nonatomic, assign, readonly) NSTimeInterval keyboardAnimationDuration;
@property (nonatomic, assign, readonly) UIViewAnimationOptions keyboardAnimationCurveOption;

- (instancetype)initWithGestureRecognizer:(__weak LXMTableViewGestureRecognizer *)tableViewGestureRecognizer;

- (void)collectStartingInformation:(UIGestureRecognizer *)recognizer;
- (NSIndexPath *)addingRowIndexPathForGestureRecognizer:(UIGestureRecognizer *)recognizer;
- (CGFloat)panOffsetX:(UIPanGestureRecognizer *)recognizer;
- (void)prepareForRearrange:(UILongPressGestureRecognizer *)recognizer;
- (void)updateAddingIndexPathForCurrentLocation:(UILongPressGestureRecognizer *)recognizer;
- (void)finishLongPress:(UILongPressGestureRecognizer *)recognizer;
- (void)updateWithPinchAdding:(UIPinchGestureRecognizer *)recognizer;

- (void)deleteRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)commitOrDiscardRow;
@end