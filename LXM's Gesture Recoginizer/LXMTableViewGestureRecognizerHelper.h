//
// Created by FLY.lxm on 2016.19.8.
// Copyright (c) 2016 FLY.lxm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LXMGlobalSettings.h"

@class LXMTableViewGestureRecognizer;
@class LXMTableViewState;

@interface LXMTableViewGestureRecognizerHelper : NSObject

@property (nonatomic, weak) LXMTableViewGestureRecognizer *tableViewGestureRecognizer;
@property (nonatomic, strong) UIImage *snapshot;
@property (nonatomic, strong) UIView *snapShotView;
@property (nonatomic, assign, readonly) NSTimeInterval keyboardAnimationDuration;
@property (nonatomic, assign, readonly) UIViewAnimationOptions keyboardAnimationCurveOption;

- (instancetype)initWithTableViewGestureRecognizer:(LXMTableViewGestureRecognizer *)tableViewGestureRecognizer tableViewState:(LXMTableViewState *)tableViewState;

- (void)collectStartingInformation:(UIGestureRecognizer *)recognizer;

// add row helper methods
- (NSIndexPath *)addingRowIndexPathForGestureRecognizer:(UIGestureRecognizer *)recognizer;


- (CGFloat)panOffsetX:(UIPanGestureRecognizer *)recognizer;
- (void)prepareForRearrange:(UILongPressGestureRecognizer *)recognizer;
- (void)updateAddingIndexPathForCurrentLocation:(UILongPressGestureRecognizer *)recognizer;
- (void)finishLongPress:(UILongPressGestureRecognizer *)recognizer;
- (void)updateWithPinchAdding:(UIPinchGestureRecognizer *)recognizer;

- (void)deleteRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)commitOrDiscardRow;

- (void)bounceRowAtIndex:(NSIndexPath *)indexPath check:(BOOL)shouldCheck;
@end