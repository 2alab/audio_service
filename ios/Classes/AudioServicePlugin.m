#import "AudioServicePlugin.h"
#import "AudioSessionController.h"


#define CHANNEL_AUDIO_SERVICE @"ryanheise.com/audioService"
#define CHANNEL_AUDIO_SERVICE_BACKGROUND @"ryanheise.com/audioServiceBackground"

@interface AudioServicePlugin () <AudioSessionControllerDelegate>
{
    FlutterMethodChannel *_clientChannel;
    FlutterMethodChannel *_backgroundChannel;

    AudioSessionController *_audioSessionController;
}
@end

@implementation AudioServicePlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    
    FlutterMethodChannel *clientChannel = [FlutterMethodChannel
                                           methodChannelWithName:CHANNEL_AUDIO_SERVICE
                                           binaryMessenger:[registrar messenger]];

    FlutterMethodChannel *backgroundChannel = [FlutterMethodChannel
                                           methodChannelWithName:CHANNEL_AUDIO_SERVICE_BACKGROUND
                                           binaryMessenger:[registrar messenger]];

    AudioServicePlugin *instance = [[AudioServicePlugin alloc] init];
    
    instance->_clientChannel = clientChannel;
    instance->_backgroundChannel = backgroundChannel;
    
    [registrar addMethodCallDelegate:instance channel:clientChannel];
    [registrar addMethodCallDelegate:instance channel:backgroundChannel];
}

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
            result(@YES);
        }
        else {
            result(@NO);
        }
    }
    else if ([@"connect" isEqualToString:call.method]) {
        result(@YES);
    }
    else if ([@"disconnect" isEqualToString:call.method]) {
        result(@YES);
    }
    else {
        result(FlutterMethodNotImplemented);
    }
}


#pragma mark - AudioSessionController delegate

- (void)audioSessionController:(AudioSessionController *)controller requiresToSuspendPlaying:(BOOL)isInterrupted {
    [_backgroundChannel invokeMethod:@"onAudioFocusLost" arguments:nil];
}

- (void)audioSessionControllerNotifiesToResumePlaying:(AudioSessionController *)controller {
    [_backgroundChannel invokeMethod:@"onAudioFocusGained" arguments:nil];
}

- (void)audioSessionControllerRequiresToStopPlaying:(AudioSessionController *)controller {
    [_backgroundChannel invokeMethod:@"onAudioFocusLost" arguments:nil];
}


@end
