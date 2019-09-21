//
//  ChannelMethodHandler.h
//  audio_service
//
//  Created by Alexander Buharsky on 21/09/2019.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@interface ChannelMethodHandler : NSObject
@property(nonatomic, readonly) FlutterMethodChannel *channel;

- (instancetype)initWithChannel:(FlutterMethodChannel*)channel;
- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result;

@end

NS_ASSUME_NONNULL_END
