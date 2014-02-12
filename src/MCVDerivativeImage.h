// Copyright (c) 2014 Yohsuke Yukishita
// This software is released under the MIT License: http://opensource.org/licenses/mit-license.php

#import <Foundation/Foundation.h>
#import "MCVBufferFreight.h"
#import "MCVPointFeatureFreight.h"
#import "TGLShaderWrapper.h"

@interface MCVDerivativeImage : TGLShaderWrapper
+ (MCVDerivativeImage *)create;

- (BOOL)process:(MCVBufferFreight *)src to:(MCVBufferFreight *)dst withFeature:(MCVPointFeatureFreight *)feature;
@end

