// Copyright (c) 2014 Yohsuke Yukishita
// This software is released under the MIT License: http://opensource.org/licenses/mit-license.php

#import "TGLShaderWrapper.h"
#import "MCVBufferFreight.h"

@interface MCVAdaptiveThreshold : TGLShaderWrapper

+ (instancetype)createWithBias:(GLfloat)bias withScreenSize:(CGSize)screen_size withWindowSize:(CGSize)window_size;
- (BOOL)process:(MCVBufferFreight *)src withIntegral:(MCVBufferFreight *)integral to:(MCVBufferFreight *)dst;
@end

