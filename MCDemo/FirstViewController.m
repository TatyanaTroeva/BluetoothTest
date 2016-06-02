//
//  FirstViewController.m
//  MCDemo
//
//  Created by Gabriel Theodoropoulos on 1/6/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "FirstViewController.h"

@interface FirstViewController ()

@property (nonatomic, strong) AppDelegate *appDelegate;

-(void)sendMyMessage:(NSString*) sMessage;
-(void)didReceiveDataWithNotification:(NSNotification *)notification;

@end

@implementation FirstViewController
{
    KSVideoPlayerView * viewPlayer;
    BOOL bVideoEncodeStarting;
    BOOL showPlayerView;
}

@synthesize webView;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if ( _appDelegate.isHosting )
    {
        [_appDelegate.mcManager setupPeerAndSessionWithDisplayName:@"Host"];
        self.title = @"Host";
        
        NSURL * urlSite = [NSURL URLWithString:@"https://youtube.com"];
        NSURLRequest * request = [NSURLRequest requestWithURL:urlSite];
        [webView loadRequest:request];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerItemBecameCurrent:)
                                                     name:@"AVPlayerItemBecameCurrentNotification"
                                                   object:nil];
    }
    else
    {
        [_appDelegate.mcManager setupPeerAndSessionWithDisplayName:@"Guest"];
        [_appDelegate.mcManager startAdvertisingForServiceType:@"Together-Test" discoveryInfo:nil];
        
        self.navigationItem.rightBarButtonItem = nil;
        self.title = @"Guest";
        [webView setUserInteractionEnabled:NO];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveDataWithNotification:)
                                                 name:@"MCDidReceiveDataNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(peerDidChangeStateWithNotification:)
                                                 name:@"MCDidChangeStateNotification"
                                               object:nil];

    
    showPlayerView = NO;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
    if ( !showPlayerView )
        return;
    
    [UIView animateWithDuration:duration animations:^{
        if(UIDeviceOrientationIsLandscape(toInterfaceOrientation)) {
            viewPlayer.frame = CGRectMake(0, 0, self.view.frame.size.height, self.view.frame.size.width);
        } else {
            viewPlayer.frame = CGRectMake(0, 0, self.view.frame.size.height, self.view.frame.size.width);
        }
    } completion:^(BOOL finished) {
    }];
}

- (void) viewDidDisappear:(BOOL)animated
{
    if ( !_appDelegate.isHosting )
        [_appDelegate.mcManager stopAdvertising];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onInvite:(id)sender {
    [[_appDelegate mcManager] setupMCBrowser];
    [[[_appDelegate mcManager] browser] setDelegate:self];
    [self presentViewController:[[_appDelegate mcManager] browser] animated:YES completion:nil];
}

#pragma mark - MCBrowserViewController delegate

- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController
{
    [browserViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController
{
    [browserViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - web view delegates

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    
    NSLog(@"load request = %@", request.description);
    
    if ( [request.description rangeOfString:@"zrt_lookup.html"].location != NSNotFound )
    {
        bVideoEncodeStarting = YES;
        return YES;
    }
    else
    {
        if ( _appDelegate.isHosting )
            [self sendMyMessage:[self makeTMessage:TMESSAGE_URL_CHANGED withData:[[request URL] absoluteString]]];
    }
    
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView{
    
}

- (void)webViewDidFinishLoad:(UIWebView *)webView{
    
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    
}

#pragma mark LBYouTubePlayerViewControllerDelegate

-(void)youTubePlayerViewController:(LBYouTubePlayerViewController *)controller didSuccessfullyExtractYouTubeURL:(NSURL *)videoURL {
    NSLog(@"Did extract video source:%@", videoURL);
}

-(void)youTubePlayerViewController:(LBYouTubePlayerViewController *)controller failedExtractingYouTubeURLWithError:(NSError *)error {
    NSLog(@"Failed loading video due to error:%@", error);
}

#pragma mark - Notification delegates

-(void)playerItemBecameCurrent:(NSNotification*)notification {
    
    if ( !bVideoEncodeStarting )
        return;
    
    AVPlayerItem *playerItem = [notification object];
    if(playerItem == nil) return;
    // Break down the AVPlayerItem to get to the path
    AVURLAsset *asset = (AVURLAsset*)[playerItem asset];
    NSURL *url = [asset URL];
    NSString *path = [url absoluteString];
    
    NSLog(@"Captured video link : %@", path);
    
    if ( path )
    {
        if ([self.webView canGoBack]) {
            [self.webView goBack];
        }
    
        [self sendMyMessage:[self makeTMessage:TMESSAGE_VIDEO_EXTRACTED withData:path]];
        [self performSelectorOnMainThread:@selector(showVideoPlayer:) withObject:url waitUntilDone:NO];
//        [self showVideoPlayer:url];
    }
}

- (void) showVideoPlayer:(NSURL *) url
{
    if ( viewPlayer )
        [viewPlayer removeFromSuperview];
    
    viewPlayer = [[KSVideoPlayerView alloc] initWithFrame:self.view.frame contentURL:url];
    viewPlayer.delegate = self;
    
    if ( !_appDelegate.isHosting ){
        viewPlayer.userInteractionEnabled = NO;
        [viewPlayer showHud:NO];
    }
    
    [self.view addSubview:viewPlayer];
    self.navigationController.navigationBarHidden = YES;
    bVideoEncodeStarting = NO;
    
    showPlayerView = YES;
    
}

- (void) closeVideoPlayer
{
    if ( viewPlayer )
        [viewPlayer onClose:nil];
    
    showPlayerView = NO;
}

#pragma mark - KSVideoPlayer view delegates

-(void)playerViewZoomButtonClicked:(KSVideoPlayerView*)view{
    
}

-(void)playerFinishedPlayback:(KSVideoPlayerView*)view{
    NSLog(@"Finished!");
}

-(void)playerChangedPlayback:(KSVideoPlayerView*)view Time:(CMTime) changedTime{
    
    NSLog(@"video seek time = %d", (int)changedTime.value * changedTime.timescale);
    NSString * data = [NSString stringWithFormat:@"%d,%d", (int)changedTime.value, (int)changedTime.timescale];
    [self sendMyMessage:[self makeTMessage:TMESSAGE_VIDEO_SEEK withData:data]];
}

-(void)playerClickedPlay:(KSVideoPlayerView*)view{
    NSLog(@"Play!");
    
    [self sendMyMessage:[self makeTMessage:TMESSAGE_VIDEO_PLAY withData:@""]];
}

-(void)playerClickedPause:(KSVideoPlayerView*)view{
    NSLog(@"Paused!");
    [self sendMyMessage:[self makeTMessage:TMESSAGE_VIDEO_PAUSE withData:@""]];
}

- (void)playerClose:(KSVideoPlayerView *)view
{
    self.navigationController.navigationBarHidden = NO;
    [self sendMyMessage:[self makeTMessage:TMESSAGE_VIDEO_CLOSE withData:@""]];
}

#pragma mark - Private method implementation

-(void)sendMyMessage: (NSString*) sMessage{
    
    if ( !_appDelegate.isHosting )
        return;
    
    NSLog(@"Send message : %@", sMessage);
    
    NSData *dataToSend = [sMessage dataUsingEncoding:NSUTF8StringEncoding];
    NSArray *allPeers = _appDelegate.mcManager.session.connectedPeers;
    NSError *error;
    
    [_appDelegate.mcManager.session sendData:dataToSend
                                     toPeers:allPeers
                                    withMode:MCSessionSendDataReliable
                                       error:&error];
    
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
    }
    
}

-(void)didReceiveDataWithNotification:(NSNotification *)notification{
    MCPeerID *peerID = [[notification userInfo] objectForKey:@"peerID"];
    NSString *peerDisplayName = peerID.displayName;
    
    NSData *receivedData = [[notification userInfo] objectForKey:@"data"];
    NSString *receivedText = [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];

    NSLog(@"received message : %@", receivedText);
    
    [self parseTMessageAndDo:receivedText];
}


-(void)peerDidChangeStateWithNotification:(NSNotification *)notification{
    MCPeerID *peerID = [[notification userInfo] objectForKey:@"peerID"];
    NSString *peerDisplayName = peerID.displayName;
    MCSessionState state = [[[notification userInfo] objectForKey:@"state"] intValue];
    
    if (state != MCSessionStateConnecting) {
        if (state == MCSessionStateConnected && _appDelegate.isHosting) {
            
            NSString *currentURL = @"https://youtube.com";//webView.request.URL.absoluteString;
            [self sendMyMessage:[self makeTMessage:TMESSAGE_URL_CHANGED withData:currentURL]];
            
        }
        else if (state == MCSessionStateNotConnected){
            
            
        }
    }
}

#pragma mark - Utilies


- (NSString*) makeTMessage:(NSString*) type withData:(NSString*) data
{
    NSString * sMessage = [NSString stringWithFormat:@"%@:::%@", type, data];
    
    return sMessage;
}

- (void) parseTMessageAndDo:(NSString*) receivedText
{
    NSArray * array = [receivedText componentsSeparatedByString:@":::"];
    if ( array.count < 2  )
    {
        NSLog(@"Unknown format!");
        return;
    }
    
    NSString * type = (NSString*)array[0];
    NSString * data = (NSString*)array[1];
    
    NSLog(@"parse message type: %@, data: %@", type, data);
    
    if ( [type isEqualToString:TMESSAGE_URL_CHANGED] )
    {
        if ( [data isEqualToString:@"about:blank" ])
            return;
        
        dispatch_sync(dispatch_get_main_queue(), ^{
        
        NSURL * urlSite = [NSURL URLWithString:data];
        NSURLRequest * request = [NSURLRequest requestWithURL:urlSite];
        [webView loadRequest:request];
            
        });
    }
    else if ( [type isEqualToString:TMESSAGE_VIDEO_EXTRACTED] ) {
        
        [self performSelectorOnMainThread:@selector(showVideoPlayer:) withObject:[NSURL URLWithString:data ] waitUntilDone:NO];
    }
    else if ( [type isEqualToString:TMESSAGE_VIDEO_PAUSE] ) {
        dispatch_sync(dispatch_get_main_queue(), ^{
        
        if ( viewPlayer )
            [viewPlayer pause];
            
        });
    }
    else if ( [type isEqualToString:TMESSAGE_VIDEO_PLAY] ) {
        dispatch_sync(dispatch_get_main_queue(), ^{
        
        if ( viewPlayer)
            [viewPlayer play];
            
        });
    }
    else if ( [type isEqualToString:TMESSAGE_VIDEO_SEEK] ) {
        
        NSArray * arr = [data componentsSeparatedByString:@","];
        int value = [arr[0] intValue];
        int scale = [arr[1] intValue];
        
        CMTime time = CMTimeMake(value, scale);
        
        dispatch_sync(dispatch_get_main_queue(), ^{
        
        if ( viewPlayer )
            [viewPlayer seekToTime:time];
            
        });
    }
    else if ( [type isEqualToString:TMESSAGE_VIDEO_CLOSE] ) {
        
        [self performSelectorOnMainThread:@selector(closeVideoPlayer) withObject:nil waitUntilDone:NO];
    }
    
}

@end
