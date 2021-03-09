//
//  VideoPlayerViewController.m
//  03_videoPlayer
//
//  Created by sy on 2019/6/22.
//  Copyright © 2019 sy. All rights reserved.
//

#import "VideoPlayerViewController.h"
#import "Video/SYVideoPlayerController.h"



@interface VideoPlayerViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic) TableViewMode tableViewMode;
@property (strong, nonatomic) NSMutableArray* subtitleOptions;
@property (strong, nonatomic) NSArray* chapterOptions;
@property (strong, nonatomic) NSString* lastSelectedSubTitle;

@property (weak, nonatomic) IBOutlet UIView *videoView;
@property (weak, nonatomic) IBOutlet UIView *extraView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end



@implementation VideoPlayerViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableViewMode = TableViewModeNone;
    self.subtitleOptions = [NSMutableArray array];
    self.chapterOptions = [NSMutableArray array];
    
    self.navigationController.navigationBar.hidden = TRUE;
    self.videoView.backgroundColor = [UIColor blackColor];
    self.videoController = [[SYVideoPlayerController alloc] initWithURL:self.url];
    if (self.videoController) {
        self.videoController.delegate = self;
        self.videoController.frame = CGRectMake(0, 0, self.videoView.frame.size.width, self.videoView.frame.size.height);
        [self.videoView addSubview:self.videoController.view];
    }
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [UIView new];
}


- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.videoController.frame = CGRectMake(0, 0, self.videoView.frame.size.width, self.videoView.frame.size.height);
}


- (BOOL)prefersStatusBarHidden{
    return  TRUE;
}

//
// MARK: - video player controller delegate
//
- (void)videoPlayerControllerDoRequestExit {
    [self.navigationController popViewControllerAnimated:TRUE];
    self.navigationController.navigationBar.hidden = FALSE;
}

- (void)videoPlayerController:(VideoPlayerController *)controller doRequestShowSubtitles:(NSMutableArray *)subtitles {
    if (self.tableViewMode != TableViewModeSubTitles) {
        self.subtitleOptions = subtitles;
        self.tableViewMode = TableViewModeSubTitles;
        [self.subtitleOptions addObject:@"None"];
        [self.tableView reloadData];
        
        unsigned long lastSelectedIndex = [self.subtitleOptions indexOfObject:self.lastSelectedSubTitle];
        if (lastSelectedIndex == NSNotFound) {
            lastSelectedIndex = self.subtitleOptions.count - 1;
        }
        NSIndexPath* lastSelectedIndexPath = [NSIndexPath indexPathForRow:lastSelectedIndex inSection:0];
        [self.tableView selectRowAtIndexPath:lastSelectedIndexPath
                                    animated:TRUE
                              scrollPosition:UITableViewScrollPositionMiddle];
        [self tableView:self.tableView didSelectRowAtIndexPath:lastSelectedIndexPath];
        
    }
}

- (void)videoPlayerController:(VideoPlayerController *)controller doRequestShowChapters:(NSArray *)chapters {
    self.chapterOptions = chapters;
    self.tableViewMode = TableViewModeChapters;
    [self.tableView reloadData];
}

//
// MARK: - table view delegate and data source
//
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.tableViewMode == TableViewModeSubTitles) {
        return self.subtitleOptions.count;
    } else if (self.tableViewMode == TableViewModeChapters) {
        return self.chapterOptions.count;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell* newCell = [tableView dequeueReusableCellWithIdentifier:@"basic" forIndexPath:indexPath];
    newCell.imageView.image = nil;
    newCell.textLabel.text = nil;
    newCell.accessoryType = UITableViewCellAccessoryNone;
    
    if (self.tableViewMode == TableViewModeSubTitles) {
        newCell.textLabel.text = self.subtitleOptions[indexPath.row];
    } else if (self.tableViewMode == TableViewModeChapters) {
        VideoChapterItem* chapterItem = (VideoChapterItem*)self.chapterOptions[indexPath.row];
        newCell.textLabel.text = [NSString stringWithFormat:@"%.2f - %@", CMTimeGetSeconds(chapterItem.time), chapterItem.title];
    }
    
    return newCell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.tableViewMode == TableViewModeSubTitles) {
        UITableViewCell* lastSelectedCell = [tableView cellForRowAtIndexPath:indexPath];
        lastSelectedCell.accessoryType = UITableViewCellAccessoryNone;
    }
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.tableViewMode == TableViewModeSubTitles) {
        UITableViewCell* selectedCell = [tableView cellForRowAtIndexPath:indexPath];
        selectedCell.accessoryType = UITableViewCellAccessoryCheckmark;
        NSString* selectedTitle = self.subtitleOptions[indexPath.row];
        [self.videoController selectSubtitle:selectedTitle];
        self.lastSelectedSubTitle = selectedTitle;
    } else if (self.tableViewMode == TableViewModeChapters) {
        VideoChapterItem* chapterItem = self.chapterOptions[indexPath.row];
        [self.videoController doScrubbingToTime:chapterItem.time];
        [tableView deselectRowAtIndexPath:indexPath animated:false];
    }
}

@end
