//
//  SliderCell.h
//  ValueTrackingSlider
//
//  Created by Alan Skipp on 07/04/2014.
//  Copyright (c) 2014 Alan Skipp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ASValueTrackingSlider.h"

@interface SliderCell : UITableViewCell <ASValueTrackingSliderDelegate>
@property (weak, nonatomic) IBOutlet ASValueTrackingSlider *slider;
@end
