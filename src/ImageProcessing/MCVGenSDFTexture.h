// Copyright (c) 2014 Yohsuke Yukishita
// This software is released under the MIT License: http://opensource.org/licenses/mit-license.php

#import "TGLShaderWrapper.h"
#import "MCVBufferFreight.h"

@interface MCVGenSDFTexture : TGLShaderWrapper
+ (instancetype)createWithOutputSize:(CGSize)size;
- (TGLMappedTexture2D *)process:(MCVBufferFreight *)src;
@end

