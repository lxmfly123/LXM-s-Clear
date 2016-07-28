//
//  StrikeThroughText.h
//  LXM's Gesture Recoginizer
//
//  Created by FLY.lxm on 4/22/16.
//  Copyright © 2016 FLY.lxm. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LXMTableViewCell;

@interface LXMStrikeThroughText : UITextField

@property (nonatomic, assign) BOOL isStrikeThrough;
@property (nonatomic, weak) LXMTableViewCell *parentCell;

@end
