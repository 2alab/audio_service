#import "AudioServicePlugin.h"
#import "AudioSessionController.h"
#import <MediaPlayer/MediaPlayer.h>

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

- (instancetype)init {
    self = [super init];
    if (self) {
        [self _setupRemoteMediaCommandsHandlers];
    }
    
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    
//    NSLog(@"--> %@, %@", call.method, call.arguments);
    
    if ([@"isRunning" isEqualToString:call.method]) {
        result(_audioSessionController != nil ? @YES : @NO);
    }
    else if ([@"start" isEqualToString:call.method]) {
        if (_audioSessionController == nil) {
            _audioSessionController = [AudioSessionController new];
            _audioSessionController.delegate = self;
            
            [_audioSessionController startAudioSession];
        }

        [self _initBackgroundChannelWithCallbackHandle:call.arguments[@"callbackHandle"]];
        
        result(@YES);
        
    }
    else if ([@"connect" isEqualToString:call.method]) {
        result(@YES);
    }
    else if ([@"disconnect" isEqualToString:call.method]) {
        result(@YES);
    }
    else if ([@"setMediaItem" isEqualToString:call.method]) {
        
        id value;
        
        NSMutableDictionary *nowPlayingInfo = [NSMutableDictionary new];
        
        value = call.arguments[@"album"];
        if ([value isKindOfClass:[NSString class]]) {
            if ([(NSString*)value length] > 0) {
                nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = value;
            }
        }

        value = call.arguments[@"artist"];
        if ([value isKindOfClass:[NSString class]]) {
            if ([(NSString*)value length] > 0) {
                nowPlayingInfo[MPMediaItemPropertyArtist] = value;
            }
        }

        value = call.arguments[@"title"];
        if ([value isKindOfClass:[NSString class]]) {
            if ([(NSString*)value length] > 0) {
                nowPlayingInfo[MPMediaItemPropertyTitle] = value;
            }
        }
        [MPNowPlayingInfoCenter.defaultCenter setNowPlayingInfo:nowPlayingInfo];
        
        result(@YES);

        [_clientChannel invokeMethod:@"onMediaChanged" arguments:@[call.arguments]];
    }
    else if ([@"setState" isEqualToString:call.method]) {

        NSNumber *state = call.arguments[1];
        [_clientChannel invokeMethod:@"onPlaybackStateChanged" arguments:@[state, @0, @0, @1.0, @0]];
        result(@YES);
    }
    else if ([@"ready" isEqualToString:call.method]) {
        result(@YES);
    }
    else if ([@"play" isEqualToString:call.method]) {
        [self->_backgroundChannel invokeMethod:@"onPlay" arguments:nil];
        result(@YES);
    }
    else if ([@"pause" isEqualToString:call.method]) {
        [self->_backgroundChannel invokeMethod:@"onPause" arguments:nil];
        result(@YES);
    }
    else if ([@"stop" isEqualToString:call.method]) {
        [self->_backgroundChannel invokeMethod:@"onStop" arguments:nil];
        result(@YES);
    }
    else if ([@"prepare" isEqualToString:call.method]) {
        [self->_backgroundChannel invokeMethod:@"onPrepare" arguments:nil];
        result(@YES);
    }
    else {
        result(FlutterMethodNotImplemented);
    }
}

#pragma mark - Private

- (void)_sendStateChange:(int)state {
    [_clientChannel invokeMethod:@"onPlaybackStateChanged"
                       arguments:@[@(state), @(8), @(0), @(0), @(0), @(0)]];
}

- (void)_setupRemoteMediaCommandsHandlers {
    
    [[[MPRemoteCommandCenter sharedCommandCenter] playCommand] addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        [self->_backgroundChannel invokeMethod:@"onPlay" arguments:nil];
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    
    [[[MPRemoteCommandCenter sharedCommandCenter] pauseCommand] addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        [self->_backgroundChannel invokeMethod:@"onPause" arguments:nil];
        return MPRemoteCommandHandlerStatusSuccess;
    }];
}

- (void)_initBackgroundChannelWithCallbackHandle:(NSNumber*)callbackHandle {
    
    FlutterCallbackInformation *callbackInfo = [FlutterCallbackCache lookupCallbackInformation:[callbackHandle longLongValue]];
    
    FlutterEngine *engine = [[FlutterEngine alloc] initWithName:CHANNEL_AUDIO_SERVICE_BACKGROUND project:nil allowHeadlessExecution:YES];
    [engine runWithEntrypoint:[callbackInfo callbackName] libraryURI:[callbackInfo callbackLibraryPath]];
    
    if (_flutterPluginRegistrantCallback != nil) {
        _flutterPluginRegistrantCallback(engine);
    }
    
    _backgroundChannel = [FlutterMethodChannel
                          methodChannelWithName:CHANNEL_AUDIO_SERVICE_BACKGROUND
                          binaryMessenger:[engine binaryMessenger]];
    
    __weak typeof(self) weakSelf = self;
    [_backgroundChannel setMethodCallHandler:^(FlutterMethodCall * _Nonnull call, FlutterResult  _Nonnull result) {
        
        [weakSelf handleMethodCall:call result:result];
    }];

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
