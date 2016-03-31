//
//  ViewController.m
//  LXM's Gesture Recoginizer
//
//  Created by FLY.lxm on 3/22/16.
//  Copyright © 2016 FLY.lxm. All rights reserved.
//

#import "ViewController.h"
#import "LXMTableViewGestureRecognizer.h"
#import "LXMTransformableTableViewCell.h"
#import "UIColor+LXMTableViewGestureRecognizerHelper.h"

@interface ViewController () <LXMTableViewGestureAddingRowDelegate, LXMTableViewGestureEditingRowDelegate, LXMTableViewGestureMoveRowDelegate>

@property (nonatomic, strong) NSMutableArray *rows;
@property (nonatomic, strong) LXMTableViewGestureRecognizer *tableViewRecognizer;
// TODO: @property (nonamatic, strong) id grabbedObject

- (void)moveRowToBottomFromIndexPath:(NSIndexPath *)indexPath;

@end

static const NSString *kAddingCell = @"Continue";
static const NSString *kDoneCell = @"Done";
static const NSString *kDummyCell = @"Dummy";
static const CGFloat kCommitingCreateCellHeight = 60.0f;
static const CGFloat kNormalCellFinishedHeight = 60.0f;

@implementation ViewController

#pragma mark view lifecycle
- (void)viewDidLoad {
  [super viewDidLoad];
  self.rows = [@[@"右划完成", 
                 @"左划删除", 
                 @"Pinch 新建", 
                 @"向下拖动新建", 
                 @"长按移动", ] mutableCopy];
  self.tableViewRecognizer = [self.tableView enableGestureTableViewWithDelegate:self];
  
  self.tableView.backgroundColor = [UIColor blackColor];
  self.tableView.rowHeight = kNormalCellFinishedHeight;
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark methods

//- (void)moveRowToBottomFromIndexPath:(NSIndexPath *)indexPath {
//  [self.tableView beginUpdates];
//  id row = self.rows[indexPath.row];
//  [self.rows removeObjectAtIndex:indexPath.row];
//  [self.rows addObject:row];
//  [self.tableView moveRowAtIndexPath:indexPath toIndexPath:[NSIndexPath indexPathForRow:self.rows.count - 1 inSection:0]];
//  [self.tableView endUpdates];
//}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.rows.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  NSObject *row = self.rows[indexPath.row];
  UIColor *backgroundColor = [[UIColor redColor] colorWithHueOffset:0.12 * indexPath.row / self.rows.count];
  
  if ([row isEqual:kAddingCell]) {
    NSString *reuseIdentifier;
    LXMTransformableTableViewCell *cell;
    if (indexPath.row == 0) {
      // TODO: pulldown cell
    } else {
      reuseIdentifier = @"UnfoldingCell";
      cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
      
      if (!cell) {
        cell = [LXMTransformableTableViewCell transformableTableViewCellWithStyle:LXMTansformableTableViewCellStyleUnfolding reuseIdentifier:reuseIdentifier];
      }
      cell.tintColor = backgroundColor;
      cell.finishedHeight = kCommitingCreateCellHeight;
      if (cell.frame.size.height > cell.finishedHeight) {
        cell.textLabel.text = @"Release to create cell";
      } else {
        cell.textLabel.text = @"Continue pinching";
      }
    }
    
    return cell;
  } else {
    static NSString *reuseIdentifier = @"NormalCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    
    if (!cell) {
      cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
      cell.textLabel.adjustsFontSizeToFitWidth = YES;
      cell.textLabel.backgroundColor = [UIColor clearColor];
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    cell.textLabel.text = self.rows[indexPath.row];
    // TODO: 原设计会将已完成的事项内容修改为“DONE”。在输出时借此判断是否为已完成事项，应修改。
    if ([row isEqual:kDoneCell]) {
      cell.backgroundColor = [UIColor darkGrayColor];
      cell.textLabel.textColor = [UIColor grayColor];
    } else if ([row isEqual:kDummyCell]) {
      cell.textLabel.text = @"";
      cell.contentView.backgroundColor = [UIColor clearColor];
    } else {
      cell.textLabel.textColor = [UIColor whiteColor];
      cell.contentView.backgroundColor = backgroundColor;
    }
    cell.textLabel.shadowOffset = CGSizeMake(1, 1);
    cell.textLabel.shadowColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
    return cell;
  }
}

#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return kNormalCellFinishedHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  NSLog(@"Row of index %ld selected.", indexPath.row);
  [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark LXMTableViewGestureAddingRowDelegate

- (void)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer needsAddRowAtIndexPath:(NSIndexPath *)indexPath {
  [self.rows insertObject:kAddingCell atIndex:indexPath.row];
}

- (void)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer needsCommitRowAtIndexPath:(NSIndexPath *)indexPath {
  [self.rows replaceObjectAtIndex:indexPath.row withObject:@"Added!"];
  LXMTransformableTableViewCell *cell = [recognizer.tableView cellForRowAtIndexPath:indexPath];
  
  BOOL isFirstRow = indexPath.section == 0 && indexPath.row == 0;
  if (isFirstRow) {
    if (cell.frame.size.height > kCommitingCreateCellHeight * 2) {
      [self.rows removeObjectAtIndex:indexPath.row];
      [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationMiddle];
    } else {
      cell.finishedHeight = kNormalCellFinishedHeight;
      cell.textLabel.text = @"Just added!";
    }
  }
}

- (void)gestureRecognizer:(LXMTableViewGestureRecognizer *)recognizer needsDiscardRowAtIndexPath:(NSIndexPath *)indexPath {
  [self.rows removeObjectAtIndex:indexPath.row];
}

@end
