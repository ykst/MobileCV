// Copyright (c) 2014 Yohsuke Yukishita
// This software is released under the MIT License: http://opensource.org/licenses/mit-license.php

#import "TGLShaderWrapper.h"
#import "MCVBufferFreight.h"

@interface MCVSUSANEdgeDetector : TGLShaderWrapper

+ (MCVSUSANEdgeDetector *)create;
- (BOOL)process:(MCVBufferFreight *)src  to:(MCVBufferFreight *)dst;
//- (BOOL)process:(GLBufferFreight *)src withForeGround:(GLBufferFreight *)fg to:(GLBufferFreight *)dst;

@end

