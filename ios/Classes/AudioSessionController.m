//
//  PlaybackConnectionController.m
//  RadioPlayer2
//
//  Created by Александр Бухарский on 15.02.17.
//  Copyright © 2017 radiotoolkit. All rights reserved.
//

#import "AudioSessionController.h"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@interface AudioSessionController ()
@property(nonatomic, readwrite) BOOL audioSessionInterrupted;
@end

@implementation AudioSessionController

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self _registerForNotifications];
    }
    
    return self;
}

- (void)startAudioSession
{
    [self _startAudioSession];
}

#pragma mark - Notifications

- (void)_registerForNotifications
{
    // register for notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(audioSessionRouteChangeNotification:)
                                                 name:AVAudioSessionRouteChangeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(audioSessionInterruptionNotification:)
                                                 name:AVAudioSessionInterruptionNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(audioSessionMediaServicesWereResetNotification:)
                                                 name:AVAudioSessionMediaServicesWereResetNotification
                                               object:nil];
    
    if (NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_8_0)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(audioSessionSilenceSecondaryAudioHintNotification:)
                                                     name:AVAudioSessionSilenceSecondaryAudioHintNotification
                                                   object:nil];
    }
}

#pragma mark - AVAudioSession notifications

- (void)audioSessionRouteChangeNotification:(NSNotification*)notification
{
    switch ([notification.userInfo[AVAudioSessionRouteChangeReasonKey] intValue])
    {
        case kAudioSessionRouteChangeReason_OldDeviceUnavailable:
        {
            NSLog(@"HEADSET UN-PLAGGED");
            [self _stopPlaying];
        }
            break;
    }
}

- (void)audioSessionInterruptionNotification:(NSNotification*)notification
{
    NSLog(@"INTERRUPTION NOTIFICATION");

    switch ([notification.userInfo[AVAudioSessionInterruptionTypeKey] intValue])
    {
        case AVAudioSessionInterruptionTypeBegan:
        {
            if (&AVAudioSessionInterruptionWasSuspendedKey)//check availability on old iOS
            {
                BOOL wasSuspended = [notification.userInfo[AVAudioSessionInterruptionWasSuspendedKey] boolValue];
                
                // NOT NEED TO STOP PLAYING
                // interruption is a direct result of the application
                // being suspended by the operating system
                if(wasSuspended)
                    return;
            }
            
            
            if(!_audioSessionInterrupted)
            {
                NSLog(@"START INTERRUPTION");
                
                _audioSessionInterrupted = YES;
                
                [self _suspendPlaying:YES];
            }
        }
            break;
            
        case AVAudioSessionInterruptionTypeEnded:
        {
            if(_audioSessionInterrupted)
            {
                _audioSessionInterrupted = NO;
                
                AVAudioSessionInterruptionOptions options = [notification.userInfo[AVAudioSessionInterruptionOptionKey] intValue];
                
                BOOL shouldResume = (options == AVAudioSessionInterruptionOptionShouldResume);

                NSLog(@"END INTERRUPTION, shouldResume=%@", shouldResume ? @"true" : @"false");

                if (shouldResume)
                {
                    [self _resumePlaying];
                }
            }
        }
            break;
    }
}

- (void)audioSessionSilenceSecondaryAudioHintNotification:(NSNotification*)notification
{
    switch ([notification.userInfo[AVAudioSessionSilenceSecondaryAudioHintTypeKey] intValue])
    {
            // The system is indicating that another application's primary audio has started.
        case AVAudioSessionSilenceSecondaryAudioHintTypeBegin:
        {
            NSLog(@"START SILENCE SECONDARY AUDIO");
            [self _suspendPlaying:NO];
       }
            break;
            
            // The system is indicating that another application's primary audio has stopped.
        case AVAudioSessionSilenceSecondaryAudioHintTypeEnd:
        {
            NSLog(@"END SILENCE SECONDARY AUDIO");
        }
            break;
    }
}

- (void)audioSessionMediaServicesWereResetNotification:(NSNotification*)notification
{
    NSLog(@"AUDIOSESSION RESET");
    
    [self _suspendPlaying:YES];
    [self _startAudioSession];
    [self _resumePlaying];
}

#pragma mark - Private

- (BOOL)_startAudioSession
{
    NSLog(@"_startAudioSession");

    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    NSError *error              = nil;
    BOOL    setCategorySuccess  = NO;
    BOOL    activationSuccess   = NO;
    
    setCategorySuccess = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:0 error:&error];
    if(error){
        NSLog(@"Error on AVAudioSession setCategory: %@", error);
    }
    
    activationSuccess = [[AVAudioSession sharedInstance] setActive:YES error:&error];
    if(error){
        NSLog(@"Error on AVAudioSession setActive: %@", error);
    }
    
    return activationSuccess && setCategorySuccess;
}

- (void)_suspendPlaying:(BOOL)isInterrupted
{
    if ([_delegate respondsToSelector:@selector(audioSessionController:requiresToSuspendPlaying:)])
        [_delegate audioSessionController:self requiresToSuspendPlaying:isInterrupted];
}

- (void)_resumePlaying
{
    if ([_delegate respondsToSelector:@selector(audioSessionControllerNotifiesToResumePlaying:)])
        [_delegate audioSessionControllerNotifiesToResumePlaying:self];
}

- (void)_stopPlaying
{
    if ([_delegate respondsToSelector:@selector(audioSessionControllerRequiresToStopPlaying:)])
        [_delegate audioSessionControllerRequiresToStopPlaying:self];
}

@end
