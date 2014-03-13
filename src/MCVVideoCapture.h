// Copyright (c) 2014 Yohsuke Yukishita
// This software is released under the MIT License: http://opensource.org/licenses/mit-license.php

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "MTPipeline.h"
#import "MCVBufferFreight.h"

@interface MCVVideoCapture : NSObject<AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, readonly) MTNode *conduit;
@property (nonatomic, readonly) CGSize capture_size;

@property (nonatomic, readonly) BOOL capture_size_available;

+ (instancetype)createWithConduit:(MTNode *)conduit;
+ (instancetype)createWithConduit:(MTNode *)conduit withInputPreset:(NSString *)preset; // AVCaptureSessionPreset*

- (void)startCapture;
- (void)stopCapture;
- (BOOL)isCapturing;

- (void)appendMetaInfo:(MCVBufferFreight *)freight; // override this to automatically append extra information
@end