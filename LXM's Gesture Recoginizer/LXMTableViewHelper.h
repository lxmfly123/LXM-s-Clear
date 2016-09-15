//
//  LXMTableViewHelper.h
//  LXM's Gesture Recoginizer
//
//  Created by FLY.lxm on 5/4/16.
//  Copyright © 2016 FLY.lxm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LXMGlobalSettings.h"

@class LXMTodoList;
@class LXMTableViewGestureRecognizer;
@class LXMTableViewState;

@protocol LXMTableViewHelper



@end

@interface LXMTableViewHelper : NSObject <LXMTableViewHelper>

- (instancetype)initWithTableViewGestureRecognizer:(LXMTableViewGestureRecognizer *)tableViewGestureRecognizer tableViewState:(LXMTableViewState *)tableViewState;

- (UIColor *)colorForRowAtIndexPath:(NSIndexPath *)indexPath;
- (UIColor *)colorForRowAtIndexPath:(NSIndexPath *)indexPath ignoreTodoItem:(BOOL)shouldIgnore;
- (UIColor *)textColorForRowAtIndexPath:(NSIndexPath *)indexPath;

- (void)saveTableViewContentOffsetAndInset;
- (void)recoverTableViewContentOffsetAndInset;

- (void)recoverRowAtIndexPath:(NSIndexPath *)indexPath forAdding:(BOOL)shouldAdd;
- (void)replaceRowAtIndexPathToNormal:(NSIndexPath *)indexPath;
- (void)assignModifyRowAtIndexPath:(NSIndexPath *)indexPath;

- (void)bounceRowAtIndex:(NSIndexPath *)indexPath check:(BOOL)shouldCheck;
- (void)moveRowAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath;
- (NSIndexPath *)movingDestinationIndexPathForRowAtIndexPath:(NSIndexPath *)indexPath;

@end
