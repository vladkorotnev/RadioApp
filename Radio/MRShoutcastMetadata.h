//
//  MRShoutcastMetadata.h
//  Radio
//
//  Created by Vladislav Korotnev on 6/30/13.
//  Copyright (c) 2013 Vladislav Korotnev. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol MRSCMetadataReceiver;
@interface MRShoutcastMetadata : NSObject
@property (nonatomic,retain) id<MRSCMetadataReceiver> delegate;
- (void)beginReceivingUpdatesToDelegate:(id<MRSCMetadataReceiver>)del forStream:(NSString*)streamUrl;
@end

@protocol MRSCMetadataReceiver <NSObject>

- (void) thereIsNoMetadataForStream:(NSString*)streamUrl;
- (void) gotMetadataUpdate:(NSString*)metadata;

@end