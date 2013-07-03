//
//  MRAppDelegate.h
//  Radio
//
//  Created by Vladislav Korotnev on 6/30/13.
//  Copyright (c) 2013 Vladislav Korotnev. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
#import "OBMenuBarWindow.h"
#import "MRShoutcastMetadata.h"
#import <AVFoundation/AVFoundation.h>
@interface MRAppDelegate : NSObject <NSApplicationDelegate,MRSCMetadataReceiver,AVAudioPlayerDelegate> {
    __weak NSTextField *display;
    __weak NSView *mainVw;
    NSButton *pwrBtn;
    NSMenuItem *menubarInvert;
    NSImageView *darker;
    __weak NSSlider *volSlider;
}
- (void)mediaKeyEvent: (int)key state: (BOOL)state repeat: (BOOL)repeat;
@property (strong) IBOutlet NSImageView*darker;
- (IBAction)mbInvClick:(id)sender;
@property (weak) IBOutlet NSTextField *display;
@property (weak) IBOutlet NSView *mainVw;
- (IBAction)buttonPushed:(NSButton*)sender;
@property (strong) IBOutlet NSButton *pwrBtn;
- (IBAction)powerPress:(NSButton *)sender;
@property (weak) IBOutlet NSSlider *volSlider;

@property (strong) IBOutlet NSMenuItem *menubarInvert;

@property (assign) IBOutlet OBMenuBarWindow *window;

@end
