// Copyright (c) 2014 Yohsuke Yukishita
// This software is released under the MIT License: http://opensource.org/licenses/mit-license.php

#import "TGLShaderWrapper.h"
#import "MCVBufferFreight.h"

@interface MCVLBPFilter : TGLShaderWrapper

+ (instancetype)create;

- (BOOL)process:(MCVBufferFreight *)src to:(MCVBufferFreight *)dst;
@end

