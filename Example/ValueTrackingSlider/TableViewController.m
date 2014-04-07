//
//  TableViewController.m
//  ValueTrackingSlider
//
//  Created by Alan Skipp on 07/04/2014.
//  Copyright (c) 2014 Alan Skipp. All rights reserved.
//

#import "TableViewController.h"


@implementation TableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // send headerView to back to prevent it from obscuring tableViewCells
    [self.headerView.superview sendSubviewToBack:self.headerView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 6;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SliderCell" forIndexPath:indexPath];
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row % 2 == 1) {
        cell.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    }
}

@end
