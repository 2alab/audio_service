//
//  ChannelMethodHandler.m
//  audio_service
//
//  Created by Alexander Buharsky on 21/09/2019.
//

#import "ChannelMethodHandler.h"

@implementation ChannelMethodHandler

- (instancetype)initWithChannel:(FlutterMethodChannel*)channel {
    self = [super init];
    if (self) {
        _channel = channel;

        __block ChannelMethodHandler *_self = self;
        [_channel setMethodCallHandler:^(FlutterMethodCall * _Nonnull call, FlutterResult  _Nonnull result) {
            [_self handleMethodCall:call result:result];
        }];
    }
    
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    result(FlutterMethodNotImplemented);
}

@end
