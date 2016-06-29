//
//  LXMTransformableTableViewCell.h
//  LXM's Gesture Recoginizer
//
//  Created by FLY.lxm on 3/24/16.
//  Copyright © 2016 FLY.lxm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, LXMTransformableTableViewCellStyle) {
  LXMTransformableTableViewCellStyleUnfolding,
  LXMTransformableTableViewCellStylePullDown,
};

@protocol LXMTransformableTableViewCell <NSObject>

@property (nonatomic, assign) CGFloat finishedHeight;
// TODO: tintColor // what's this for?

@end

@interface LXMTransformableTableViewCell : UITableViewCell <LXMTransformableTableViewCell>

+ (instancetype)transformableTableViewCellWithStyle:(LXMTransformableTableViewCellStyle)style reuseIdentifier:(NSString *)identifier;

@end

@interface LXMUnfoldingTransformableTableViewCell : LXMTransformableTableViewCell

@property (nonatomic, strong) UIView *transformable1HalfView;
@property (nonatomic, strong) UIView *transformable2HalfView;

@end

@interface LXMPullDownTransformableTableViewCell : LXMTransformableTableViewCell <LXMTransformableTableViewCell>

@property (nonatomic, strong) UIView *transformableView;
@property (nonatomic, assign) CGFloat vSize;
@property (nonatomic, assign) CGFloat fraction;

@end
