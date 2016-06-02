//
//  FirstViewController.h
//  MCDemo
//
//  Created by Gabriel Theodoropoulos on 1/6/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LBYouTube.h"
#import "KSVideoPlayerView.h"
#import "AppDelegate.h"

#define TMESSAGE_URL_CHANGED    @"TMESSAGE_URL_CHANGED"
#define TMESSAGE_VIDEO_EXTRACTED    @"TMESSAGE_VIDEO_EXTRACTED"
#define TMESSAGE_VIDEO_PLAY    @"TMESSAGE_VIDEO_PLAY"
#define TMESSAGE_VIDEO_PAUSE    @"TMESSAGE_VIDEO_PAUSE"
#define TMESSAGE_VIDEO_SEEK    @"TMESSAGE_VIDEO_SEEK"
#define TMESSAGE_VIDEO_CLOSE    @"TMESSAGE_VIDEO_CLOSE"

@interface FirstViewController : UIViewController <UIWebViewDelegate, LBYouTubePlayerControllerDelegate, playerViewDelegate, MCBrowserViewControllerDelegate>


@property (strong, nonatomic) IBOutlet UIWebView *webView;

@end
