// Copyright (c) 2014 Yohsuke Yukishita
// This software is released under the MIT License: http://opensource.org/licenses/mit-license.php

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "MTPipeline.h"
#import "MCVBufferFreight.h"

@interface MCVVideoCapture : NSObject<AVCaptureVideoDataOutputSampleBufferDelegate> {
@protected
    AVCaptureDevice *_device;
    AVCaptureSession *_session;
    AVCaptureDeviceInput *_input;
    AVCaptureVideoDataOutput *_output;
    dispatch_queue_t _queue;
    EAGLContext *_context;
    BOOL _focus_supported;
}

@property (nonatomic, readonly) MTNode *conduit;
@property (nonatomic, readonly) CGSize capture_size;
@property (nonatomic, readonly) AVCaptureDevicePosition position;
@property (nonatomic, readonly) BOOL capture_size_available;

+ (instancetype)createWithConduit:(MTNode *)conduit;
+ (instancetype)createWithConduit:(MTNode *)conduit withInputPreset:(NSString *)preset; // AVCaptureSessionPreset*
+ (instancetype)createWithConduit:(MTNode *)conduit withInputPreset:(NSString *)preset withPosition:(AVCaptureDevicePosition)position; // AVCaptureSessionPreset*
+ (instancetype)create60FpsWithConduit:(MTNode *)conduit; // rear camera only

+ (NSArray *)countSupportedPositions;
+ (BOOL)hasTorch;
+ (BOOL)torchIsOn;
+ (void)turnTorchOn:(BOOL)on;
+ (BOOL)has60fpsCapability;

- (void)startCapture;
- (void)stopCapture;
- (BOOL)isCapturing;
- (BOOL)focusPointSupported;
- (void)setFocusPoint:(CGPoint)focus_point;
- (void)setAutoFocus;
- (void)appendMetaInfo:(MCVBufferFreight *)freight; // override this to automatically append extra information
- (void)changeCameraFPS:(int)fps;
@end