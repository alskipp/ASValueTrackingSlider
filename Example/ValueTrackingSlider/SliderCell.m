//
//  SliderCell.m
//  ValueTrackingSlider
//
//  Created by Alan Skipp on 07/04/2014.
//  Copyright (c) 2014 Alan Skipp. All rights reserved.
//

#import "SliderCell.h"

@implementation SliderCell

- (void)awakeFromNib
{
    self.slider.delegate = self;
}

- (void)sliderWillDisplayPopUpView:(ASValueTrackingSlider *)slider;
{
    [self.superview bringSubviewToFront:self];
}

@end
