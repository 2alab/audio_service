//
//  BackgroundChannelHandler.m
//  audio_service
//
//  Created by Alexander Buharsky on 21/09/2019.
//

#import "BackgroundChannelHandler.h"

@implementation BackgroundChannelHandler

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"getPlatformVersion" isEqualToString:call.method]) {
        result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
    } else {
        result(FlutterMethodNotImplemented);
    }
}

@end
