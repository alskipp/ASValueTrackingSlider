//
//  ASViewController.m
//  ValueTrackingSlider
//
//  Created by Alan Skipp on 19/10/2013.
//  Copyright (c) 2013 Alan Skipp. All rights reserved.
//

#import "ASViewController.h"
#import "ASValueTrackingSlider.h"

@interface ASViewController ()
@property (weak, nonatomic) IBOutlet ASValueTrackingSlider *slider;
@end

@implementation ASViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.slider.minimumValue = 0.0;
    self.slider.maximumValue = 255.0;
    [self.slider setMaxFractionDigitsDisplayed:2];
    [self.slider setPopUpViewColor:[UIColor colorWithHue:0.55 saturation:0.5 brightness:0.9 alpha:0.8]];
    [self.slider setTextColor:[UIColor colorWithHue:0.55 saturation:1 brightness:0.4 alpha:1]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
