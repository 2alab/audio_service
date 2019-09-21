//
//  ClientChannelHandler.m
//  audio_service
//
//  Created by Alexander Buharsky on 21/09/2019.
//

#import "ClientChannelHandler.h"
#import "AudioSessionController.h"

@interface ClientChannelHandler () <AudioSessionControllerDelegate>
{
    AudioSessionController *_audioSessionController;
}
@end

@implementation ClientChannelHandler

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    
    NSLog(@"--> %@", call.method);
    
    if ([@"isRunning" isEqualToString:call.method]) {
        result(_audioSessionController != nil ? @YES : @NO);
    }
    else if ([@"start" isEqualToString:call.method]) {
        if (_audioSessionController == nil) {
            _audioSessionController = [AudioSessionController new];
            _audioSessionController.delegate = self;
            
            [_audioSessionController startAudioSession];
        }
        result(@YES);
    }
    else if ([@"connect" isEqualToString:call.method]) {
        result(@YES);
    }
    else if ([@"disconnect" isEqualToString:call.method]) {
        result(@YES);
    }
    else {
        [super handleMethodCall:call result:result];
    }
}

#pragma mark - AudioSessionController delegate

- (void)audioSessionController:(AudioSessionController *)controller requiresToSuspendPlaying:(BOOL)isInterrupted {
    
}

- (void)audioSessionControllerNotifiesToResumePlaying:(AudioSessionController *)controller {
    
}

- (void)audioSessionControllerRequiresToStopPlaying:(AudioSessionController *)controller {
    
}

@end
