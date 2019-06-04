//
//  RecordCell.m
//  02_audioRecoder
//
//  Created by sy on 2019/5/24.
//  Copyright © 2019 sy. All rights reserved.
//

#import "RecordCell.h"

@interface RecordCell ()

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *playProgress;


@end



@implementation RecordCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)initNameLabel:(NSString*)name DateLable:(NSString*)date TimeLable:(NSString*)time {
    self.nameLabel.text = name;
    self.dateLabel.text = date;
    self.timeLabel.text = time;
    [self.playProgress setProgress:0];
    self.playProgress.hidden = TRUE;
}

@end
