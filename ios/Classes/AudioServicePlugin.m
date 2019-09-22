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

static FlutterPluginRegistrantCallback _flutterPluginRegistrantCallback;

@implementation AudioServicePlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    
    FlutterMethodChannel *clientChannel = [FlutterMethodChannel
                                           methodChannelWithName:CHANNEL_AUDIO_SERVICE
                                           binaryMessenger:[registrar messenger]];

    AudioServicePlugin *instance = [[AudioServicePlugin alloc] init];
    
    instance->_clientChannel = clientChannel;
    
    [registrar addMethodCallDelegate:instance channel:clientChannel];
}

+ (void)setPluginRegistrantCallback:(FlutterPluginRegistrantCallback)callback {
    _flutterPluginRegistrantCallback = callback;
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
        }
        
        [_clientChannel invokeMethod:@"onPlaybackStateChanged" arguments:@[@(8), @(513), @(0), @(1.0), @(1569105283141)]];
        [_clientChannel invokeMethod:@"onQueueChanged" arguments:@(0)];
        
        NSNumber *callbackHandleId = call.arguments[@"callbackHandle"];
        
        FlutterCallbackInformation *callbackInfo = [FlutterCallbackCache lookupCallbackInformation:[callbackHandleId longLongValue]];
        
        FlutterEngine *engine = [[FlutterEngine alloc] initWithName:CHANNEL_AUDIO_SERVICE_BACKGROUND project:nil allowHeadlessExecution:YES];
        [engine runWithEntrypoint:[callbackInfo callbackName] libraryURI:[callbackInfo callbackLibraryPath]];

        if (_flutterPluginRegistrantCallback != nil) {
            _flutterPluginRegistrantCallback(engine);
        }
        
        _backgroundChannel = [FlutterMethodChannel
         methodChannelWithName:CHANNEL_AUDIO_SERVICE_BACKGROUND
         binaryMessenger:[engine binaryMessenger]];
        
        [_backgroundChannel setMethodCallHandler:^(FlutterMethodCall * _Nonnull call, FlutterResult  _Nonnull result) {
            NSLog(@"backgroundChannel --> %@ %@", call.method, call.arguments);
            result([NSNumber numberWithBool:YES]);
        }];
        
        
        result([NSNumber numberWithBool:YES]);
        
        
        [_backgroundChannel invokeMethod:@"onPlay" arguments:nil];
    }
    else if ([@"connect" isEqualToString:call.method]) {
        result([NSNumber numberWithBool:YES]);
    }
    else if ([@"disconnect" isEqualToString:call.method]) {
        result([NSNumber numberWithBool:YES]);
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
