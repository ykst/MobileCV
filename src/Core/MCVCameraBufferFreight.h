// Copyright (c) 2014 Yohsuke Yukishita
// This software is released under the MIT License: http://opensource.org/licenses/mit-license.php

#import "MCVBufferFreight.h"

@interface MCVCameraBufferFreight : MCVBufferFreight<MCVSubPlanerBufferProtocol>

+ (instancetype)create;
- (void)refill:(CMSampleBufferRef)sample;

//- (void)modifyAttitude:(double)roll :(double)pitch :(double)yaw;

@end

