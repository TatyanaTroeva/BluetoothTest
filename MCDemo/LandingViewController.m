//
//  LandingViewController.m
//  MCDemo
//
//  Created by Dev Mac on 11/3/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "LandingViewController.h"
#import "AppDelegate.h"

@interface LandingViewController ()

@property (nonatomic, strong) AppDelegate *appDelegate;

@end

@implementation LandingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.title = @"Together - Test";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UITableViewCell * cell = (UITableViewCell*) sender;
    
    if ( [cell.textLabel.text isEqualToString:@"Create a Room"] )
    {
        NSLog(@"Create a new room.");
        _appDelegate.isHosting = YES;
    }
    else
    {
        NSLog(@"Join to a room.");
        _appDelegate.isHosting = NO;
    }
    
}

@end
