//
//  VideoTableViewController.h
//  03_videoPlayer
//
//  Created by sy on 2019/6/20.
//  Copyright © 2019 sy. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface VideoTableViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray* videoURLs;
@end

NS_ASSUME_NONNULL_END
