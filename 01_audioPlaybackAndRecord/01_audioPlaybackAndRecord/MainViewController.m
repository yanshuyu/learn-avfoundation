//
//  ViewController.m
//  01_audioPlaybackAndRecord
//
//  Created by sy on 2019/5/9.
//  Copyright © 2019 sy. All rights reserved.
//

#import "MainViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "UIVerticalSlider.h"


@interface MainViewController ()
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *stopButton;

@property (weak, nonatomic) IBOutlet UIVerticalSlider *rateSlider;
@property (strong, nonatomic) IBOutletCollection(UIVerticalSlider) NSArray *panSliders;
@property (strong, nonatomic) IBOutletCollection(UIVerticalSlider) NSArray *volumeSliders;
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *panLabels;
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *volLabels;
@property (weak, nonatomic) IBOutlet UILabel *rateLabel;
@property (nonatomic) BOOL playing;

@property (strong, nonatomic) NSArray* audioPlayers;

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.rateSlider._slider addTarget:self action:@selector(onRateChanging:) forControlEvents:UIControlEventValueChanged];
    
    for (UIVerticalSlider* panSliser in self.panSliders) {
        [panSliser._slider addTarget:self action:@selector(onPanChanging:) forControlEvents:UIControlEventValueChanged];
        [self updatePan:panSliser.val ForPlayerWithTag:panSliser.tag];
    }
    
    for (UIVerticalSlider* volSlider in self.volumeSliders) {
        [volSlider._slider addTarget:self action:@selector(onVolumeChanging:) forControlEvents:UIControlEventValueChanged];
        [self updateVolume:volSlider.val ForPlayerWithTag:volSlider.tag];
    }
    
    //create audioPlayers
    AVAudioPlayer* bassPalyer = [self createAudioPlayerFromFile:@"bass" withExtension:@"caf"];
    AVAudioPlayer* drumsPlayer = [self createAudioPlayerFromFile:@"drums" withExtension:@"caf"];
    AVAudioPlayer* guitarPlayer = [self createAudioPlayerFromFile:@"guitar" withExtension:@"caf"];
    NSArray* players = @[drumsPlayer, guitarPlayer, bassPalyer];
    self.audioPlayers = players;
    self.playing = FALSE;
    [self updatePlayerControlsState];
    
    //register to AvAudioSession's AVAudioSessionInterruptionNotification for responsing interruption (phone call, facetime request).
    NSNotificationCenter* nsnc = [NSNotificationCenter defaultCenter];
    [nsnc addObserver:self
             selector:@selector(handleInterruption:)
                 name:AVAudioSessionInterruptionNotification
               object:[AVAudioSession sharedInstance]];
    
    //register to AvAudioSession's AVAudioSessionInterruptionNotification for responsing route (audio input or output is added or removed).
    [nsnc addObserver:self
             selector:@selector(handleRouteChange:)
                 name:AVAudioSessionRouteChangeNotification
               object:[AVAudioSession sharedInstance]];
}

- (IBAction)play:(UIButton *)sender {
    NSLog(@"play button click...");
    
    NSTimeInterval shortStartDelay = [self.audioPlayers[0] deviceCurrentTime] + 0.01;
    for (AVAudioPlayer* player in self.audioPlayers) {
        [player playAtTime:shortStartDelay];
    }
    self.playing = TRUE;
    [self updatePlayerControlsState];
}

- (IBAction)pause:(UIButton *)sender {
    NSLog(@"pause button click...");
    
    for (AVAudioPlayer* player in self.audioPlayers) {
        [player stop];
        player.currentTime = 0;
    }
    self.playing = FALSE;
    [self updatePlayerControlsState];
}


- (void) onRateChanging: (UISlider*)slider {
    NSLog(@"rate: %f", slider.value);

    for (AVAudioPlayer* player in self.audioPlayers) {
        [player setRate:slider.value];
    }
    self.rateLabel.text = [[NSString alloc]initWithFormat:@"rate %.1f", slider.value];
}

- (void) onVolumeChanging: (UISlider*)slider {
    NSLog(@"vol: %f for index: %ld", slider.value, (long)slider.superview.tag);
    [self updateVolume:slider.value ForPlayerWithTag:slider.superview.tag];
}

- (void) onPanChanging: (UISlider*)slider {
    NSLog(@"pan: %f for index: %ld", slider.value, slider.superview.tag);
    [self updatePan:slider.value ForPlayerWithTag:slider.superview.tag];
}

- (nullable AVAudioPlayer*) createAudioPlayerFromFile: (NSString*)file  withExtension: (NSString*)extension{
    NSURL* url = [[NSBundle mainBundle]URLForResource:file withExtension:extension];
    AVAudioPlayer* player = nil;
    
    if (url) {
        NSError* createError = nil;
        player = [[AVAudioPlayer alloc]initWithContentsOfURL:url fileTypeHint:nil error:&createError];
        if (player == nil) {
            NSLog(@"%s failed with args:\nfile: %@\nwithExtension: %@\nerror: %@",
                  __func__,
                  file,
                  extension,
                  createError.localizedDescription);
            return nil;
        }
        [player setEnableRate:TRUE];
        [player setNumberOfLoops:-1];
        [player prepareToPlay];
    }
    return player;
}

- (void) updatePlayerControlsState {
    [self.playButton setEnabled:!self.playing];
    [self.stopButton setEnabled:self.playing];
}

- (void) updatePan:(float)val ForPlayerWithTag: (NSUInteger)tag {
    if (tag < 0 || tag >= 3) {
        return;
    }
    
    [self.audioPlayers[tag] setPan:val];
    [self.panLabels enumerateObjectsUsingBlock:^(UILabel* label, NSUInteger idx, BOOL * _Nonnull stop) {
        if (label.tag == tag) {
            label.text = [[NSString alloc] initWithFormat:@"pan %.1f", val];
        }
    }];
}

- (void) updateVolume:(float)vol ForPlayerWithTag:(NSUInteger)tag {
    if (tag < 0 || tag >= 3) {
        return;
    }
    
    [self.audioPlayers[tag] setVolume:vol fadeDuration:0];
    [self.volLabels enumerateObjectsUsingBlock:^(UILabel* label, NSUInteger idx, BOOL * _Nonnull stop) {
        if (label.tag == tag) {
            label.text = [[NSString alloc]initWithFormat:@"vol %.1f", vol];
        }
    }];
    
}


- (void)handleInterruption:(NSNotification*) notification {
    NSDictionary* interrupInfo = [notification userInfo];
    if (interrupInfo) {
        AVAudioSessionInterruptionType interrupType = [interrupInfo[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
        if (interrupType == AVAudioSessionInterruptionTypeBegan) {
            [self pause:self.stopButton];
            
        } else if (interrupType == AVAudioSessionInterruptionTypeEnded) {
            AVAudioSessionInterruptionOptions interupOption = [interrupInfo[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
            if (interupOption == AVAudioSessionInterruptionOptionShouldResume) {
                [self play:self.playButton];
                
            }
        }
    }
}


- (void)handleRouteChange:(NSNotification*)notification {
    NSDictionary* rerouteInfo = notification.userInfo;
    if (rerouteInfo) {
        AVAudioSessionRouteChangeReason routeReason = [rerouteInfo[AVAudioSessionRouteChangeReasonKey] unsignedIntegerValue];
        if (routeReason == AVAudioSessionRouteChangeReasonOldDeviceUnavailable) {
            AVAudioSessionRouteDescription* prevRouteDesc = rerouteInfo[AVAudioSessionRouteChangePreviousRouteKey];
            AVAudioSessionPortDescription* prevFirstOutputPortDesc = prevRouteDesc.outputs[0];
            if ([prevFirstOutputPortDesc.portType isEqualToString:AVAudioSessionPortHeadphones]) {
                [self pause:self.stopButton];
            }
        }
    }
}

@end
