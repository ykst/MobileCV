// Copyright (c) 2014 Yohsuke Yukishita
// This software is released under the MIT License: http://opensource.org/licenses/mit-license.php

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "MTPipeline.h"

@interface MCVVideoCapture : NSObject<AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, readonly) MTNode *conduit;

+ (MCVVideoCapture *)createWithConduit:(MTNode *)conduit;

- (void) startCapture;
- (void) stopCapture;
- (BOOL) isCapturing; 
@end