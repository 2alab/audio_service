//
//  PlaybackConnectionController.h
//  RadioPlayer2
//
//  Created by Александр Бухарский on 15.02.17.
//  Copyright © 2017 radiotoolkit. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AudioSessionControllerDelegate;
@interface AudioSessionController : NSObject
@property(nonatomic, weak)id<AudioSessionControllerDelegate> delegate;
@property(nonatomic, readonly) BOOL audioSessionInterrupted;

- (void)startAudioSession;

@end

@protocol AudioSessionControllerDelegate <NSObject>

- (void)audioSessionControllerRequiresToStopPlaying:(AudioSessionController*)controller;

- (void)audioSessionController:(AudioSessionController*)controller requiresToSuspendPlaying:(BOOL)isInterrupted;

- (void)audioSessionControllerNotifiesToResumePlaying:(AudioSessionController*)controller;

@end
