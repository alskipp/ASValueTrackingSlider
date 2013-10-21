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
@property (weak, nonatomic) IBOutlet ASValueTrackingSlider *slider1;
@property (weak, nonatomic) IBOutlet ASValueTrackingSlider *slider2;
@property (weak, nonatomic) IBOutlet ASValueTrackingSlider *slider3;
@end

@implementation ASViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // customize slider 1
    self.slider1.maximumValue = 2.0;

    
    // customize slider 2
    self.slider2.maximumValue = 255.0;
    [self.slider2 setMaxFractionDigitsDisplayed:0];
    [self.slider2 setPopUpViewColor:[UIColor colorWithHue:0.55 saturation:0.5 brightness:0.9 alpha:0.8]];
    [self.slider2 setTextColor:[UIColor colorWithHue:0.55 saturation:1 brightness:0.4 alpha:1]];
    
    
    // customize slider 3
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterPercentStyle];
    [self.slider3 setNumberFormatter:formatter];
    [self.slider3 setPopUpViewColor:[UIColor colorWithHue:0.4 saturation:0.9 brightness:0.7 alpha:1]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
