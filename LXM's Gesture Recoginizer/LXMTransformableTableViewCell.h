//
//  LXMTransformableTableViewCell.h
//  LXM's Gesture Recoginizer
//
//  Created by FLY.lxm on 3/24/16.
//  Copyright © 2016 FLY.lxm. All rights reserved.
//

typedef NS_ENUM(NSUInteger, LXMTansformableTableViewCellStyle) {
  LXMTansformableTableViewCellStyleUnfolding,
  LXMTansformableTableViewCellStylePullDown,
};

@protocol LXMTransformableTableViewCell <NSObject>

@property (nonatomic, assign) CGFloat finishedHeight;
// TODO: tintColor // what's this for?

@end

@interface LXMTransformableTableViewCell : UITableViewCell <LXMTransformableTableViewCell>

+ (instancetype)transformableTableViewCellWithStyle:(LXMTansformableTableViewCellStyle)style reuseIdentifier:(NSString *)identifier;

@end

@interface LXMUnfoldingTransformableTableViewCell : LXMTransformableTableViewCell

@property (nonatomic, strong) UIView *transformable1HalfView;
@property (nonatomic, strong) UIView *transformable2HalfView;

@end

// TODO: LXMPullDownTansformableTableViewCell
