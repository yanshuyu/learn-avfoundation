//
//  VideoTableViewController.m
//  03_videoPlayer
//
//  Created by sy on 2019/6/20.
//  Copyright © 2019 sy. All rights reserved.
//

#import "VideoTableViewController.h"
#import "Cell/VideoCell.h"
#import "VideoPlayerViewController.h"


@interface VideoTableViewController ()

@end

@implementation VideoTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadVideoData];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}


- (void)loadVideoData {
    NSURL* video_1 = [[NSBundle mainBundle] URLForResource:@"hubblecast"
                                              withExtension:@"m4v"];
    NSURL* video_2 = [[NSBundle mainBundle] URLForResource:@"videoplayback"
                                              withExtension:@"mp4"] ;
    self.videoURLs = [NSArray arrayWithObjects:video_1,video_2, nil];
    //self.videoURLs = @[video_1, video_2];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"VideoDetail"]){
        VideoPlayerViewController* dstView = (VideoPlayerViewController*)segue.destinationViewController;
        NSIndexPath* indexPath = [self.tableView indexPathForSelectedRow];
        dstView.url = self.videoURLs[indexPath.row];
    }
}


//
// MARK: - table view delegate
//
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 140;
}

//
// MARK: - table view data source
//
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    return [self.videoURLs count];
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView
                 cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    VideoCell* cell = (VideoCell*)[tableView dequeueReusableCellWithIdentifier:@"VideoCell"
                                                                  forIndexPath:indexPath];
    cell.url = self.videoURLs[indexPath.row];
    return cell;
    
}



@end
