//
//  RecordCell.h
//  02_audioRecoder
//
//  Created by sy on 2019/5/24.
//  Copyright © 2019 sy. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RecordCell : UITableViewCell
- (void)initNameLabel:(NSString*)name DateLable:(NSString*)date TimeLable:(NSString*)time;
@end

NS_ASSUME_NONNULL_END
