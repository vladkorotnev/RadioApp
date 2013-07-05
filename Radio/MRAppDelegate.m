//
//  MRAppDelegate.m
//  Radio
//
//  Created by Vladislav Korotnev on 6/30/13.
//  Copyright (c) 2013 Vladislav Korotnev. All rights reserved.
//

#import "MRAppDelegate.h"
#import <QTKit/QTKit.h>

#import <IOKit/hidsystem/ev_keymap.h>

@implementation MRAppDelegate
@synthesize darker;
@synthesize volSlider;
@synthesize menubarInvert;
@synthesize pwrBtn;
@synthesize display;
@synthesize mainVw;

static QTMovie*movie;
static MRShoutcastMetadata*md;
static int curStation=0;
static NSString* curStName;
static AVAudioPlayer*untuned;
static AVAudioPlayer*seeker;
static AVAudioPlayer*clickety;
static NSString* curStationUrl;
static int curBand=100;

- (NSString *)input: (NSString *)prompt defaultValue: (NSString *)defaultValue {
    NSAlert *alert = [NSAlert alertWithMessageText: prompt
                                     defaultButton:@"OK"
                                   alternateButton:@"Cancel"
                                       otherButton:nil
                         informativeTextWithFormat:@""];
    
    NSTextField *input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 300, 75)];
    [input setStringValue:defaultValue];
    [alert setAccessoryView:input];
    NSInteger button = [alert runModal];
    if (button == NSAlertDefaultReturn) {
        [input validateEditing];
        return [input stringValue];
    } else if (button == NSAlertAlternateReturn) {
        return nil;
    } else {
        return nil;
    }
}

- (void)mediaKeyEvent: (int)key state: (BOOL)state repeat: (BOOL)repeat
{
	switch( key )
	{
		case NX_KEYTYPE_PLAY:
			if( state == 0 ){
                self.pwrBtn.state = !self.pwrBtn.state;
                [self powerPress:self.pwrBtn];
            }
            //Play pressed and released
            return;
            break;
            
        case NX_KEYTYPE_PREVIOUS:
            if( state == 0 ){
                if(self.pwrBtn.state == 0)return;
                int cs=curStation-1;
                if(cs < 1) {
                    cs=9;
                }
                NSLog(@"CS");
                for (NSButton*b in mainVw.subviews) {
                    if (b.tag >= 1 && b.tag <= 9) {
                        if(b.tag == cs){
                            [b setState:1];
                            [self buttonPushed:b];
                        } else {
                            [b setState:0];
                        }
                    }
                }
            }

           
            break;
            
        case NX_KEYTYPE_NEXT:
            if( state == 0 ){
                if(self.pwrBtn.state == 0)return;
                int cs=curStation+1;
                if(cs > 9) {
                    cs=1;
                }
                for (NSButton*b in mainVw.subviews) {
                    if (b.tag >= 1 && b.tag <= 9) {
                        if(b.tag == cs){
                            [b setState:1];
                            [self buttonPushed:b];
                        } else {
                            [b setState:0];
                        }
                    }
                }  }
    break;

	}
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.window.menuBarIcon = [NSImage imageNamed:([[NSUserDefaults standardUserDefaults]boolForKey:@"invert"] ? @"menubar-i" : @"menubar")];
    self.window.highlightedMenuBarIcon = [NSImage imageNamed:([[NSUserDefaults standardUserDefaults]boolForKey:@"invert"] ? @"menubar" : @"menubar-i")];
    self.window.hasMenuBarIcon = YES;
    self.window.attachedToMenuBar = YES;
    self.window.isDetachable = YES;
   
    seeker=[[AVAudioPlayer alloc]initWithContentsOfURL:[[NSBundle mainBundle]URLForResource:@"seeking" withExtension:@"wav"] error:nil];
    seeker.volume=0;
    seeker.numberOfLoops=-1;
    untuned=[[AVAudioPlayer alloc]initWithContentsOfURL:[[NSBundle mainBundle]URLForResource:@"untuned" withExtension:@"wav"] error:nil];
    untuned.volume=1;
    clickety=[[AVAudioPlayer alloc]initWithContentsOfURL:[[NSBundle mainBundle]URLForResource:@"switch" withExtension:@"wav"] error:nil];
    clickety.volume=1;
    untuned.numberOfLoops=-1;
    [display setTextColor:[NSColor lightGrayColor]];
    NSDictionary* kioku = [[NSUserDefaults standardUserDefaults]objectForKey:@"kioku"];
    if(kioku) {
        curStation = [[kioku objectForKey:@"curStation"]intValue];
        curBand = [[kioku objectForKey:@"curBand"]intValue];
        NSLog(@"load kioku %@",kioku);
        for (NSButton*b in mainVw.subviews) {
            if (b.tag >= 100 && b.tag <= 300) {
                if(b.tag == curBand){
                    [b setState:1];
                } else {
                    [b setState:0];
                }
            }
        }

        [self _pushButtonAtNumber:curStation];
        curStationUrl = [[[NSUserDefaults standardUserDefaults]objectForKey:[NSString stringWithFormat:@"%i",(curStation+curBand)]]objectForKey:@"url"];
        curStName = [[[NSUserDefaults standardUserDefaults]objectForKey:[NSString stringWithFormat:@"%i",(curStation+curBand)]]objectForKey:@"name"];
        volSlider.floatValue = [[kioku objectForKey:@"volSlider"]floatValue];
        [self volChg:volSlider];
    }
    for (NSButton*b in mainVw.subviews) {
        if (b.tag >= 1 && b.tag <= 9) {
            NSDictionary*stUrl = [[NSUserDefaults standardUserDefaults]objectForKey:[NSString stringWithFormat:@"%li",(long)(b.tag+curBand)]];
            if(stUrl[@"name"] && ![stUrl[@"name"] isEqualToString:@""]) [b setToolTip:stUrl[@"name"]];
        }
    }
    NSInteger kiokuVersion = [[NSUserDefaults standardUserDefaults]integerForKey:@"kiokuVersion"];
    if(kiokuVersion < 2) {
        for (int i=1; i<10; i++) {
            [[NSUserDefaults standardUserDefaults]setObject:[[NSUserDefaults standardUserDefaults]objectForKey:[NSString stringWithFormat:@"%i",i]] forKey:[NSString stringWithFormat:@"%i",(100+i)]];
        }
        [[NSUserDefaults standardUserDefaults]setInteger:2 forKey:@"kiokuVersion"];
    }
    
}

- (void) applicationWillTerminate:(NSNotification *)notification {
    NSDictionary* kioku = @{@"curStation": [NSString stringWithFormat:@"%i",curStation], @"volSlider": [NSString stringWithFormat:@"%f",volSlider.floatValue], @"curBand":[NSString stringWithFormat:@"%i",curBand]};
    [[NSUserDefaults standardUserDefaults]setObject:kioku forKey:@"kioku"];
}

- (void) _pushButtonAtNumber:(long)number {

    for (NSButton*b in mainVw.subviews) {
        if (b.tag >= 1 && b.tag <= 9) {
            if(b.tag == number){
                [b setState:1];
                curStation=(int)number;
            } else {
                [b setState:0];
            }
        }
    }
}
- (IBAction)buttonPushed:(NSButton*)sender {
    [clickety play];
        NSDictionary*stUrl = [[NSUserDefaults standardUserDefaults]objectForKey:[NSString stringWithFormat:@"%li",(long)(sender.tag+curBand)]];
    if(curStation == sender.tag){
        
        NSString*url = [self input:@"Change URL for this key?" defaultValue:stUrl[@"url"]];
        if(!url) {
            sender.state=1; return;
        }
        if(![url hasPrefix:@"http://"] && ![url hasPrefix:@"https://"]) url=[@"http://" stringByAppendingString:url];
        NSString*namne = [self input:@"Enter station name for this key" defaultValue:stUrl[@"name"]];
        if(!namne) {
            sender.state=1; return;
        }
        [self _pushButtonAtNumber:sender.tag];
        if(url && namne) {
            stUrl = @{@"name": namne, @"url":url};
            [[NSUserDefaults standardUserDefaults]setObject:stUrl forKey:[NSString stringWithFormat:@"%li",(long)(sender.tag+curBand)]];
        } else return;
        
        return;
    }

    if (!stUrl) {
        NSString*url = [self input:@"Enter URL for this key" defaultValue:@""];
        if(!url) {
            sender.state=0; return;
        }
         if(![url hasPrefix:@"http://"] && ![url hasPrefix:@"https://"]) url=[@"http://" stringByAppendingString:url];
          NSString*namne = [self input:@"Enter station name for this key" defaultValue:@""];
        if(!namne) {
            sender.state=0; return;
        }
        if(url && namne) {
            stUrl = @{@"name": namne, @"url":url};
            [[NSUserDefaults standardUserDefaults]setObject:stUrl forKey:[NSString stringWithFormat:@"%li",(long)(sender.tag+curBand)]];
        } else return;
    }
    [self _pushButtonAtNumber:sender.tag];
  
        curStName=[stUrl objectForKey:@"name"];
    curStationUrl=[stUrl objectForKey:@"url"];
      if(pwrBtn.state==1) {
        [display setStringValue:[stUrl objectForKey:@"name"]];
        [display setTextColor:[NSColor grayColor]];
        [self _slowlyStaticOutToStation:[stUrl objectForKey:@"url"]];
    }
}
#define ARC4RANDOM_MAX 0x100000000
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
 
}
- (void)_slowlyLowerVolumeStatics{
    bool done1 = false;
    bool done2=false;
    if (seeker.volume > 0) {
        float futureVol = seeker.volume - 0.05;
        if (futureVol < 0) {
            futureVol=0;
        }
      //  NSLog(@"V %f",futureVol);
        seeker.volume = futureVol;
       
            } else {
        [seeker stop];
        done1=true;
    }
    if (movie.volume < (volSlider.doubleValue/100)) {
        float futureVol = movie.volume + 0.1;
        if (futureVol > 1.0f) {
            futureVol=1.0f;
        }
       NSLog(@"mVo %f",futureVol);
        movie.volume = futureVol;

    } else done2=true;
    if(!done1 || !done2) [self performSelector:@selector(_slowlyLowerVolumeStatics) withObject:nil afterDelay:0.2];

}
- (void)_fadeToUntuned{
    bool done1 = false;
    bool done2=false;
    
    if (seeker.volume > 0) {
        float futureVol = seeker.volume - 0.05;
        if (futureVol < 0) {
            futureVol=0;
        }
   //     NSLog(@"V %f",futureVol);
        seeker.volume = futureVol;
        
       
    } else {
        [seeker stop];
        done1=true;
    }
    if (untuned.volume <= (volSlider.doubleValue/100)) {
        if(!untuned.playing) [untuned play];
        float futureVol = untuned.volume + 0.1;
        if (futureVol > 1.0f) {
            futureVol=1.0f;
        }
       // NSLog(@"mV %f",futureVol);
        untuned.volume = futureVol;
        
    } else done2=true;
    if(!done1 || !done2)  [self performSelector:@selector(_fadeToUntuned) withObject:nil afterDelay:0.1];
}
- (void)_slowlyStaticOutToStation:(NSString*)url{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_slowlyLowerVolumeStatics) object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_fadeToUntuned) object:nil];
    if(seeker.playing == false) [seeker play];
    bool done1 = false;
    bool done2=false;
    if (movie.volume > 0) {
        float futureVol = movie.volume - 0.1;
        if (futureVol <= 0) {
            futureVol=0;
            
        }
       NSLog(@"mVi %f",futureVol);
        movie.volume = futureVol;
    } else 
        done1=true;
    
    if (seeker.volume < (volSlider.doubleValue/100)) {
        float futureVol = seeker.volume + 0.2;
        if (futureVol >= 1.0f) {
            futureVol=1.0f;
        
        }
        seeker.volume = futureVol;
     
    } else {
         [movie stop];
        [untuned stop];
        [self playStationAtURL:url];
            done2=true;
    }
    if(!done1 || !done2) [self performSelector:@selector(_slowlyStaticOutToStation:) withObject:url afterDelay:0.2];
}


- (void) playStationAtURL:(NSString*)url {
    [self fullHeatTubes];
    NSURL *mp3URL = [NSURL URLWithString:url];
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], QTMovieOpenForPlaybackAttribute,
                                mp3URL, QTMovieURLAttribute,
                                nil];
    //Creates an object to hold the error message in case we get one
    NSError *error = nil;
    //Creates and initializes the movie object with the attributes dictionary we’ve created previously.
    movie = [[QTMovie alloc] initWithAttributes:dictionary error:&error];
    //Checks if anything went wrong
    if(error){
        //Something is wrong, let’s tell the user and stop the method execution
        [[NSAlert alertWithError:error] runModal];
        return;
    }
    curStationUrl=url;
    //We need to know when we can start playing and change the status label
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackStateDidChange:) name:QTMovieLoadStateDidChangeNotification object:movie];
    if (NSClassFromString(@"NSUserNotification") != nil) {
        //Initalize new notification
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        //Set the title of the notification
        [notification setTitle:@"Tuned to a new station"];
        //Set the text of the notification
        [notification setInformativeText:[NSString stringWithFormat:@"Station %i",curStation]];
        //Set the time and date on which the nofication will be deliverd (for example 20 secons later than the current date and time)
        [notification setDeliveryDate:[NSDate dateWithTimeInterval:1 sinceDate:[NSDate date]]];
        //Set the sound, this can be either nil for no sound, NSUserNotificationDefaultSoundName for the default sound (tri-tone) and a string of a .caf file that is in the bundle (filname and extension)
        [notification setSoundName:nil];
        [notification setSubtitle:curStName];
        
        //Get the default notification center
        NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
        //Scheldule our NSUserNotification
        [center scheduleNotification:notification];
        [center performSelector:@selector(removeAllDeliveredNotifications) withObject:nil afterDelay:1];
    }

}

- (void) thereIsNoMetadataForStream:(NSString*)streamUrl {
    NSLog(@"Nometa");
}
- (void) gotMetadataUpdate:(NSString*)metadata {
    NSLog(@"metadata %@",metadata);
}
- (IBAction)volChg:(NSSlider*)sender {
    if (movie) {
        movie.volume=(sender.floatValue/100);
    }
    seeker.volume=(sender.floatValue/100);
    untuned.volume=(sender.floatValue/100);
    
}

-(void)playbackStateDidChange:(NSNotification *)noti{
    //Let’s get the load state
    QTMovieLoadState state = [[movie attributeForKey:QTMovieLoadStateAttribute] intValue];

    //Checks if there was an error while buffering the streaming, in case there was, stops the audio playback
    if(state == -1l){
        [display setStringValue:@"Error"];
          [display setTextColor:[NSColor redColor]];
        [self _fadeToUntuned];
    }
    //Checks if the audio streaming is loading
    else if(state == QTMovieLoadStateLoading){
        [display setStringValue:@"Heating up tubes..."];
            [display setTextColor:[NSColor grayColor]];
    }
    //Checks if we have enough audio data to start playing the audio
    else if(state >= 10000){
        [self _slowlyLowerVolumeStatics];
        [movie play];
        movie.volume = 0;
         [display setStringValue:curStName];
            [display setTextColor:[NSColor blackColor]];
    }
    else {
        //The movie was fully loaded, we need to do nothing
    }
}


- (void) fullHeatTubes {
    if (darker.alphaValue > 0) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(preheatTubes) object:nil];
        darker.alphaValue = darker.alphaValue - 0.01f;
        if(darker.alphaValue < 0)darker.alphaValue=0;
        [self performSelector:@selector(fullHeatTubes) withObject:nil afterDelay:0.1];
    }
}
- (void) preheatTubes {
    if (darker.alphaValue > 0.5f) {
        darker.alphaValue = darker.alphaValue - 0.01f;
         if(darker.alphaValue < 0)darker.alphaValue=0;
        [self performSelector:@selector(preheatTubes) withObject:nil afterDelay:0.1];
    }
}
- (void) coolDown {
    if(darker.alphaValue >= 1.0f) return;
        darker.alphaValue = darker.alphaValue + 0.04f;
        [self performSelector:@selector(coolDown) withObject:nil afterDelay:0.01f];
    
}
- (IBAction)powerPress:(NSButton *)sender {
/*
    for (NSButton*b in mainVw.subviews) {
        if (b.tag >= 1 && b.tag <= 9) {
            if(sender.state==1){
                [b setEnabled:true];
            } else {
                [b setEnabled:false];
            }
        }
    } */
    if(sender.state==1) {
        [self preheatTubes];
        if(curStation == 0)   [untuned play];
        else {
                [self _slowlyStaticOutToStation:curStationUrl];
            NSLog(@"%@",curStName);
        }
    } else {
         [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [clickety play];
        [self coolDown];
        if(untuned.isPlaying) [untuned stop];
        if(seeker.isPlaying) [seeker stop];
        if(movie) [movie stop];
       
        [display setTextColor:[NSColor grayColor]];
    }
}
- (IBAction)mbInvClick:(id)sender {
    [[NSUserDefaults standardUserDefaults]setBool:(![[NSUserDefaults standardUserDefaults]boolForKey:@"invert"]) forKey:@"invert"];
    self.window.menuBarIcon = [NSImage imageNamed:([[NSUserDefaults standardUserDefaults]boolForKey:@"invert"] ? @"menubar-i" : @"menubar")];
    self.window.highlightedMenuBarIcon = [NSImage imageNamed:([[NSUserDefaults standardUserDefaults]boolForKey:@"invert"] ? @"menubar" : @"menubar-i")];
}

- (NSButton*) findButtonWithTag:(NSInteger)tag {
    for (NSButton*b in mainVw.subviews) {
        if(b.tag == tag)return b;
    }
    return nil;
}

- (IBAction)bandClick:(NSButton*)sender {
    int newBand;
    for (NSButton*b in mainVw.subviews) {
        if (b.tag >= 100 && b.tag <= 300) {
            if(b.tag == sender.tag){
                [b setState:1];
                newBand=(int)b.tag;
            } else {
                [b setState:0];
            }
        }
    }
    if (newBand != curBand) {
        [clickety play];
        curBand = newBand;
        for (NSButton*b in mainVw.subviews) {
            if (b.tag >= 1 && b.tag <= 9) {
                NSDictionary*stUrl = [[NSUserDefaults standardUserDefaults]objectForKey:[NSString stringWithFormat:@"%li",(long)(b.tag+curBand)]];
                if(stUrl[@"name"] && ![stUrl[@"name"] isEqualToString:@""]) [b setToolTip:stUrl[@"name"]];
            }
        }
        NSDictionary*stUrl = [[NSUserDefaults standardUserDefaults]objectForKey:[NSString stringWithFormat:@"%li",(long)(curStation+curBand)]];
        
       
     
        if(pwrBtn.state==1) {
            if (!stUrl) {
                curStName=@"";
                curStationUrl=@"";
                curStation=0;
                [self _fadeToUntuned];
                [movie stop];
                [display setStringValue:@"Not tuned to a station"];
                [display setTextColor:[NSColor grayColor]];
                [self _pushButtonAtNumber:-1];
            } else {
                
                curStName=[stUrl objectForKey:@"name"];
                curStationUrl=[stUrl objectForKey:@"url"];
                [display setStringValue:[stUrl objectForKey:@"name"]];
                [display setTextColor:[NSColor grayColor]];
                [self _slowlyStaticOutToStation:[stUrl objectForKey:@"url"]];
            }
            
        }

    } else return;
    
    
    
}
@end
