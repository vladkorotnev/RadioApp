//
//  MRApp.m
//  Radio
//
//  Created by Vladislav Korotnev on 7/3/13.
//  Copyright (c) 2013 Vladislav Korotnev. All rights reserved.
//

#import "MRApp.h"
#import "MRAppDelegate.h"
@implementation MRApp 
- (void)sendEvent: (NSEvent*)event
{
	if( [event type] == NSSystemDefined && [event subtype] == 8 )
	{
		int keyCode = (([event data1] & 0xFFFF0000) >> 16);
		int keyFlags = ([event data1] & 0x0000FFFF);
		int keyState = (((keyFlags & 0xFF00) >> 8)) == 0xA;
		int keyRepeat = (keyFlags & 0x1);
		
		[(MRAppDelegate*)self.delegate mediaKeyEvent: keyCode state: keyState repeat: keyRepeat];
	}
    
	[super sendEvent: event];
}
@end
