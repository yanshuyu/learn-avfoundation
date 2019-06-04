//
//  ViewController.m
//  02_audioRecoder
//
//  Created by sy on 2019/5/22.
//  Copyright © 2019 sy. All rights reserved.
//

#import "ViewController.h"
#import "AudioRecoderController.h"
#import "AudioPlayerController.h"
#import "SoundRecord.h"
#import "RecordCell.h"
#import <MediaPlayer/MediaPlayer.h>

#define SOUNDS_ARCHIVE @"sounds.data"
typedef  void (^RecordResultHandler) (NSString*, NSURL*);



@interface ViewController () <AudioRecoderControllerDelegate, UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UIButton *stopButton;
@property (weak, nonatomic) IBOutlet UILabel *timerLable;
@property (weak, nonatomic) IBOutlet UITableView *recordsTableView;

@property (nonatomic, strong) AudioRecoderController* audioRecorderController;
@property (nonatomic, strong) AudioPlayerController* audioPlayerController;
@property (nonatomic, strong) NSMutableArray* audioRecords;

@property (nonatomic, strong) NSTimer* recordTimer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.audioRecorderController = [[AudioRecoderController alloc] init];
    self.audioRecorderController.delegate = self;
    self.audioPlayerController = nil;
    
    UIImage* recordImage = [UIImage imageNamed:@"play"];
    UIImage* pauseImage = [UIImage imageNamed:@"pause"];
    [self.recordButton setImage:recordImage forState:UIControlStateNormal];
    [self.recordButton setImage:pauseImage forState:UIControlStateSelected];
    self.stopButton.enabled = FALSE;
    

    // load records from archiv
    self.audioRecords = [self unarchiveRecords];
    NSLog(@"Unarchive records: %@", self.audioRecords);
    
    //set table view delegate and data source
    self.recordsTableView.delegate = self;
    self.recordsTableView.dataSource = self;
    self.recordsTableView.tableFooterView = [[UIView alloc] init];
    
    
}

- (void)viewWillDisappear:(BOOL)animated{
    [self.audioRecorderController clearup:nil];
    if (self.audioPlayerController){
        [self.audioPlayerController stop];
        self.audioPlayerController = nil;
    }
}


- (IBAction)onRecordButtonTap:(UIButton *)sender {
    if (self.audioPlayerController) {
        [self.audioPlayerController stop];
        self.audioPlayerController = nil;
    }
    
    if (!sender.isSelected) {
        [self.audioRecorderController record];
        [self starRecordTimer];
    }else{
        [self.audioRecorderController pause];
        [self stopRecordTimer];
    }
    
    [self.stopButton setEnabled:TRUE];
    [sender setSelected:!sender.isSelected];
}


- (IBAction)onStopButtonTap:(UIButton *)sender {
    [self.audioRecorderController stop];
    [self stopRecordTimer];
    [self.stopButton setEnabled:FALSE];
    [self.recordButton setSelected:FALSE];
}


//
// MARK: - tableview delegate
//
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.audioRecords count];
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    RecordCell* cell = (RecordCell*)[tableView dequeueReusableCellWithIdentifier:@"RecordCell" forIndexPath:indexPath];
    SoundRecord* data = [self.audioRecords objectAtIndex:indexPath.row];
    
    [cell initNameLabel:data.name DateLable:[data dateString] TimeLable:[data timeString]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SoundRecord* selectedRecord = [self.audioRecords objectAtIndex:indexPath.row];
    
    if (self.audioPlayerController) {
        [self.audioPlayerController stop];
    }
    
    NSError* e;
    NSURL* url = [NSURL fileURLWithPath:selectedRecord.path];
    self.audioPlayerController = [[AudioPlayerController alloc] initWithContentsOfURL:url error:&e];
    
    if (!self.audioPlayerController){
        NSLog(@"Failed to create audio player controller with content url:%@\n for reson: %@", url, e.localizedDescription);
        BOOL reachable = [url checkResourceIsReachableAndReturnError:&e];
        if (!reachable) {
            NSLog(@"resource unreachable for reson: %@", e.localizedDescription);
        }
        return ;
    }
    
    if(![self.audioPlayerController play]) {
        NSLog(@"Failed to play record: %@", url);
    }
  
}


//
// MARK: - audio recoder controller delegate
//
- (void)audioRecorderControllerRecordBegin:(BOOL)success {
    NSLog(@"Begin record, success: %d", success);
}

- (void)audioRecorderControllerRecordPause {
    NSLog(@"Pause record");
}

- (void)audioRecorderControllerRecordFinish:(BOOL)success WithResult:(NSURL *)result {
    NSLog(@"Stop record with reslut:\n\tsuccess: %d\n\tresult:%@",success, result.path);
    if (success) {
        [self presentAlertToHandleResult:result
                         withSaveHandler:^(NSString* name, NSURL* srcUrl) {
                             NSLog(@"Perform ok action to reslut with entered name: %@", name);
                             [self updateRecordTimeLable:TRUE];
                             // save temprory record file to persitance location
                             NSError* e;
                             NSURL* savedUrl = [self saveRecordWithName:name ForURL:srcUrl Error:&e];
                             if (!savedUrl) {
                                 NSLog(@"Failed to save record: %@ for reson: %@", srcUrl.path, e.localizedDescription);
                                 return ;
                             }
                             NSLog(@"Saved srcUrl: %@\nto dstUrl: %@ success.", srcUrl.path, savedUrl.path);
                             // update table view data
                             SoundRecord* record = [[SoundRecord alloc] initWithName:name Path:savedUrl.path];
                             [self.audioRecords addObject:record];
                             [self.recordsTableView reloadData];
                             
                             // archive record data
                             if (![self archiveRecords:&e])
                             {
                                 NSLog(@"Failed to write archived record data to file for reson: %@", e.localizedDescription);
                             }
                             NSLog(@"Archive records: %@", self.audioRecords);
                             
                         } orCancelHandler:^(NSString* name, NSURL * srcUrl) {
                             [self updateRecordTimeLable:TRUE];
                             NSLog(@"Perform cancle action to reslut with entered name: %@", name);
                         }];
    }

}


//
// MARK: - record data managment
//

- (NSURL*)saveRecordWithName:(NSString*)name ForURL:(NSURL*)url Error:(NSError* _Nullable *)error {
    // copy record to document dir
    assert(name!=nil && url!=nil);
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSArray* docPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSTimeInterval timeStamp = [NSDate timeIntervalSinceReferenceDate];
    NSString* fileName = [NSString stringWithFormat:@"%@_%d.m4a",name, (int)timeStamp];
    NSURL* dstUrl = [NSURL fileURLWithPath:[docPaths[0] stringByAppendingPathComponent:fileName]];
    NSError* e;
    BOOL success = [fileManager copyItemAtURL:url toURL:dstUrl error:&e];

    if (!success) {
        dstUrl = nil;
        if (error) {
            *error = e;
        }
    }
    
    return dstUrl;
}


- (BOOL)archiveRecords:(NSError* _Nullable *)error {
    NSArray* docPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSURL* archUrl = [NSURL fileURLWithPath:[docPaths[0] stringByAppendingPathComponent:SOUNDS_ARCHIVE]];
    NSError* e;
    NSData* archivedData = [NSKeyedArchiver archivedDataWithRootObject:self.audioRecords requiringSecureCoding:YES error:&e];
    BOOL success = FALSE;
    if (archivedData) {
        success = [archivedData writeToURL:archUrl atomically:YES];
    }else{
        if (error) {
            *error = e;
        }
    }
    
    return success;
}

- (NSMutableArray*)unarchiveRecords {
    NSMutableArray* result = nil;
    NSArray* docPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* archivePath = [docPaths[0] stringByAppendingPathComponent:SOUNDS_ARCHIVE];
    NSURL* archiveUrl = [NSURL fileURLWithPath:archivePath];
    NSData* recordsData = [NSData dataWithContentsOfURL:archiveUrl];
    
    if (!recordsData) {
        result = [NSMutableArray array];
    }else{
        NSError* e;
        NSSet* formatIds = [NSSet setWithArray:@[[NSMutableArray class],[SoundRecord class]]];
        result = [NSKeyedUnarchiver unarchivedObjectOfClasses:formatIds fromData:recordsData error:&e];
        if (!result){
            NSLog(@"Failed to unarchiveRecords for reson: %@", e.localizedDescription);
        }
    }
    
    return result;
}


- (void)presentAlertToHandleResult:(NSURL*)result withSaveHandler:(RecordResultHandler)saveHandler orCancelHandler:(RecordResultHandler)cancelHandler {
    UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"Save Record"
                                                                             message:@"Enter A Name To Save Your Record"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"ok"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * _Nonnull action) {
                                                         if (saveHandler) {
                                                             saveHandler(alertController.textFields[0].text, result);
                                                         }
                                                     }];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"canle"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             if (cancelHandler) {
                                                                 cancelHandler(alertController.textFields[0].text, result);
                                                             }
                                                         }];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"Enter Your Name Here";
    }];
    [alertController addAction:okAction];
    [alertController addAction:cancelAction];

    
    [self presentViewController:alertController animated:TRUE completion:nil];
}


//
// MARK: - uodating interface
//

- (void) updateRecordTimeLable:(BOOL)reset {
    NSInteger recordTime = (NSInteger)[self.audioRecorderController.audioRecorder currentTime];
    if (reset) {
        recordTime = 0;
    }
    NSInteger hour = recordTime / 3600;
    NSInteger min = (recordTime % 3600) / 60;
    NSInteger sec = (recordTime % 3600) % 60;
    self.timerLable.text = [NSString stringWithFormat:@"%02li:%02li:%02li", (long)hour, (long)min, (long)sec];
}

- (void) starRecordTimer {
    [self stopRecordTimer];
    
    self.recordTimer = [NSTimer timerWithTimeInterval:0.5
                                               target:self
                                             selector:@selector(updateRecordTimeLable:)
                                             userInfo:nil
                                              repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.recordTimer forMode:NSRunLoopCommonModes];
}

- (void) stopRecordTimer {
    [self.recordTimer invalidate];
    self.recordTimer = nil;
}




@end
